/*
 * Copyright (C) 2024-2026 Vladimir Romanov <rirusha@altlinux.org>
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see
 * <https://www.gnu.org/licenses/gpl-3.0-standalone.html>.
 * 
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public sealed class ReadySet.PluginManager : Object {

    const string INSTALLER_STEP_PREFIX = "installer-";

    string? installer_name;

    public Context context { get; construct; }

    Peas.Engine steps_engine;
    Peas.Engine installers_engine;

    HashTable<string, StepAddin> steps_plugins = new HashTable<string, StepAddin> (str_hash, str_equal);
    HashTable<string, InstallerAddin> installers_plugins = new HashTable<string, InstallerAddin> (str_hash, str_equal);

    public PluginManager (Context context) {
        Object (context: context);
    }

    public void init (string[] steps, string? installer_name) {
        this.installer_name = installer_name;

        init_steps_plugins (steps);

        if (installer_name != null) {
            init_installers_plugins (steps);
        }
    }

    internal void blank_init () {
        init_steps_plugins ({});
        init_installers_plugins ({});
    }

    public InstallerAddin get_installer_plugin ()
    requires (installer_name != null)
    requires (installers_plugins.contains (installer_name)) {
        return installers_plugins[installer_name];
    }

    public StepAddin? get_step_addin (string step_id) {
        if (steps_plugins.contains (step_id)) {
            return steps_plugins[step_id];
        }

        return null;
    }

    internal string[] get_available_steps () {
        string[] steps = steps_plugins.get_keys_as_array ();

        foreach (var installer in installers_plugins.get_values ()) {
            foreach (var step in installer.all_pages) {
                steps += "installer-" + step;
            }
        }

        return steps;
    }

    internal string[] get_available_installers () {
        return installers_plugins.get_keys_as_array ();
    }

    public bool has_step (string id) {
        if (steps_plugins.contains (id)) {
            return true;
        }

        if (installer_name != null) {
            if (id.has_prefix (INSTALLER_STEP_PREFIX)) {
                if (get_installer_plugin ().has_page (id[INSTALLER_STEP_PREFIX.length:id.length])) {
                    return true;
                }
            }
        }

        return false;
    }

    public string get_real_page_id (string page_id) {
        return page_id[INSTALLER_STEP_PREFIX.length:page_id.length];
    }

    public BasePage build_installer_page (string page_id)
    requires (installer_name != null)
    requires (page_id.has_prefix (INSTALLER_STEP_PREFIX))
    requires (get_installer_plugin ().has_page (get_real_page_id (page_id))) {
        return get_installer_plugin ().build_page (get_real_page_id (page_id));
    }

    Peas.Engine get_steps_engine () {
        if (steps_engine == null) {
            steps_engine = new Peas.Engine ();
            steps_engine.enable_loader ("python");

            steps_engine.add_search_path (
                Config.STEPS_PLUGINS_DIR,
                null
            );
        }

        return steps_engine;
    }

    Peas.Engine get_installers_engine () {
        if (installers_engine == null) {
            installers_engine = new Peas.Engine ();
            installers_engine.enable_loader ("python");

            installers_engine.add_search_path (
                Config.INSTALLERS_PLUGINS_DIR,
                null
            );
        }

        return installers_engine;
    }

    void init_steps_plugins (string[] steps) {
        var engine = get_steps_engine ();
        var addins = new Peas.ExtensionSet.with_properties (engine, typeof (StepAddin), {}, {});

        for (int i = 0; i < engine.get_n_items (); i++) {
            engine.load_plugin ((Peas.PluginInfo) engine.get_item (i));
        }

        steps_plugins.remove_all ();

        addins.foreach (steps_addins_foreach_func);

        if (steps.length == 0) {
            return;
        }

        if (steps_plugins.length == 0) {
            error ("\nNo plugins found\n");
        } else {
            print ("\nFound steps plugins:\n");
            foreach (var plugin in steps_plugins.get_keys ()) {
                print ("  %s\n", plugin);
            }
        }

        string[] passed_steps = {};

        for (int i = 0; i < steps.length; i++) {
            if (steps_plugins.contains (steps[i])) {
                var addin = steps_plugins[steps[i]];

                context.register_vars (addin.get_context_vars ());

                //  There is no need in disabling welcome plugin
                if (steps[i] != "welcome") {
                    var vars = new HashTable<string, ContextVarInfo> (str_hash, str_equal);
                    var var_name = "step-%s-enabled".printf (steps[i]);
                    vars[var_name] = new ContextVarInfo (ContextType.BOOLEAN, true);
                    context.register_vars (vars);
                }

                passed_steps += steps[i];
            }
        }
    }

    void steps_addins_foreach_func (Peas.ExtensionSet _set, Peas.PluginInfo info, Object extension) {
        steps_plugins[info.module_name] = (StepAddin) extension;
    }

    void init_installers_plugins (string[] steps) {
        var engine = get_installers_engine ();
        var addins = new Peas.ExtensionSet.with_properties (engine, typeof (InstallerAddin), {}, {});

        for (int i = 0; i < engine.get_n_items (); i++) {
            engine.load_plugin ((Peas.PluginInfo) engine.get_item (i));
        }

        installers_plugins.remove_all ();

        addins.foreach (installer_addins_foreach_func);

        if (steps.length == 0) {
            return;
        }

        if (installers_plugins.length != 0) {
            print ("\nFound installers plugins:\n");
            foreach (var plugin in installers_plugins.get_keys ()) {
                print ("  %s\n", plugin);
            }
        }

        if (!installers_plugins.contains (installer_name)) {
            error ("Unknown installer plugin");
        }
    }

    void installer_addins_foreach_func (Peas.ExtensionSet _set, Peas.PluginInfo info, Object extension) {
        installers_plugins[info.module_name] = (InstallerAddin) extension;
    }
}
