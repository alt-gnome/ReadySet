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

    internal const string INSTALLER_STEP_PREFIX = "installer.";

    string? installer_name;
    bool steps_inited_once = false;

    public Context context { get; construct; }

    public string[] steps { get; private set; }

    Peas.Engine steps_engine;
    Peas.Engine installers_engine;

    HashTable<string, StepAddin> steps_plugins = new HashTable<string, StepAddin> (str_hash, str_equal);
    HashTable<string, InstallerAddin> installers_plugins = new HashTable<string, InstallerAddin> (str_hash, str_equal);

    public PluginManager (Context context) {
        Object (context: context);
    }

    public void init (string? installer_name, string[]? steps_to_load = null) {
        this.installer_name = installer_name;

        init_steps_plugins (steps_to_load);

        if (installer_name != null) {
            init_installers_plugins (steps_to_load);
        }
    }

    internal void blank_init (string[]? steps_to_load = null) {
        init_steps_plugins (steps_to_load);
        init_installers_plugins (steps_to_load);

        debug ("Steps: %s", string.joinv (", ", get_available_steps ()));
        debug ("installers: %s", string.joinv (", ", get_available_installers ()));
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
        var steps = new Gee.ArrayList<string> ();
        steps.add_all_array (steps_plugins.get_keys_as_array ());

        foreach (var installer in installers_plugins.get_values ()) {
            var installer_steps = ReadySetC.safe_copy (installer.steps.get_keys_as_array ());
            foreach (var step in installer_steps) {
                steps.add (INSTALLER_STEP_PREFIX + step);
            }
        }

        return steps.to_array ();
    }

    internal string[] get_available_installers () {
        return installers_plugins.get_keys_as_array ().copy ();
    }

    public bool has_step (string id) {
        if (steps_plugins.contains (id)) {
            return true;
        }

        if (installer_name != null) {
            if (id.has_prefix (INSTALLER_STEP_PREFIX)) {
                if (get_installer_plugin ().steps.contains (id[INSTALLER_STEP_PREFIX.length:id.length])) {
                    return true;
                }
            }
        }

        return false;
    }

    public static string get_real_page_id (string page_id) {
        return page_id[INSTALLER_STEP_PREFIX.length:page_id.length];
    }

    public BasePage build_installer_page (string page_id)
    requires (installer_name != null)
    requires (page_id.has_prefix (INSTALLER_STEP_PREFIX))
    requires (get_installer_plugin ().steps.contains (get_real_page_id (page_id))) {
        return get_installer_plugin ().steps[get_real_page_id (page_id)].build_page ();
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

    void init_steps_plugins (string[]? steps_to_load = null) {
        var not_found_steps = new Gee.ArrayList<string> ();
        if (steps_to_load != null) {
            var fiter = new Gee.ArrayList<string>.wrap (steps_to_load.copy ())
                .filter ((el) => !el.has_prefix (INSTALLER_STEP_PREFIX));
            not_found_steps.add_all_iterator (fiter);
        }

        var engine = get_steps_engine ();
        var addins = new Peas.ExtensionSet.with_properties (engine, typeof (StepAddin), {}, {});

        for (int i = 0; i < engine.get_n_items (); i++) {
            var info = (Peas.PluginInfo) engine.get_item (i);
            if (steps_to_load == null || info.module_name in steps_to_load) {
                engine.load_plugin (info);
                not_found_steps.remove (info.module_name);
            }
        }

        if (not_found_steps.size > 0) {
            var qarr = new Gee.ArrayList<string> ();
            var iter = not_found_steps.map<string> ((el) => "`%s`".printf (el));
            qarr.add_all_iterator (iter);
            error ("This steps not found: %s", string.joinv (", ", qarr.to_array ()));
        }

        steps_plugins.remove_all ();

        addins.foreach (steps_addins_foreach_func);
    }

    public void check_steps (string[] in_steps) {
        if (steps_plugins.length == 0) {
            error ("\nNo plugins found\n");
        }

        if (in_steps.length == 0) {
            error ("No steps specified");
        }

        var rs_settings = new Settings ("org.altlinux.ReadySet");
        string[] performed_steps = rs_settings.get_strv ("performed-steps");

        string[] st = {};

        //  We add welcome step in existing user mode if welcome step is not provided
        if (context.mode == EXISTING_USER && in_steps[0] != "welcome" && has_step ("welcome")) {
            st = { "welcome" };
            foreach (var s in in_steps) {
                st += s;
            }
        } else {
            st = in_steps.copy ();
        }

        this.steps = st;

        for (int i = 0; i < steps.length; i++) {
            if (steps_plugins.contains (steps[i])) {
                var addin = steps_plugins[steps[i]];

                string module_name;
                if (addin.module_name != null) {
                    module_name = addin.module_name;
                } else {
                    module_name = steps[i];
                }

                context.register_vars (module_name, addin.get_context_vars ());

                var vars = new HashTable<string, ContextVarInfo> (str_hash, str_equal);
                var var_name = "%s.enabled".printf (steps[i]);
                vars[var_name] = new ContextVarInfo (
                    ContextType.BOOLEAN,
                    !(context.mode == EXISTING_USER &&
                            (addin.plugin_info.module_name in performed_steps || !addin.existing_user))
                );
                context.register_vars ("steps", vars);

                context.bind_context_to_property (
                    "steps." + var_name,
                    addin,
                    "enabled",
                    SYNC_CREATE | BIDIRECTIONAL
                );

                addin.context = context;
                addin.load_css_for_display (Gdk.Display.get_default ());
            }
        }
    }

    void steps_addins_foreach_func (Peas.ExtensionSet _set, Peas.PluginInfo info, Object extension) {
        steps_plugins[info.module_name] = (StepAddin) extension;
    }

    void init_installers_plugins (string[]? steps_to_load = null) {
        var not_found_steps = new Gee.ArrayList<string> ();
        if (steps_to_load != null) {
            var fiter = new Gee.ArrayList<string>.wrap (steps_to_load.copy ())
                .filter ((el) => el.has_prefix (INSTALLER_STEP_PREFIX));
            var miter = fiter
                .map<string> ((el) => el[INSTALLER_STEP_PREFIX.length:]);
            not_found_steps.add_all_iterator (miter);
        }

        var engine = get_installers_engine ();
        var addins = new Peas.ExtensionSet.with_properties (engine, typeof (InstallerAddin), {}, {});

        installers_plugins.remove_all ();
        for (int i = 0; i < engine.get_n_items (); i++) {
            var info = (Peas.PluginInfo) engine.get_item (i);
            if (installer_name == null || info.module_name == installer_name) {
                engine.load_plugin (info);
                installers_plugins[info.module_name] = (InstallerAddin) addins.get_extension (info);
            }
        }

        if (installer_name != null) {
            not_found_steps.remove_all_array (installers_plugins[installer_name].steps.get_keys_as_array ());
        }

        if (not_found_steps.size > 0) {
            var qarr = new Gee.ArrayList<string> ();
            var iter = not_found_steps.map<string> ((el) => "`%s`".printf (el));
            qarr.add_all_iterator (iter);
            error ("This installer steps not found: %s", string.joinv (", ", qarr.to_array ()));
        }
    }

    public void check_installers () {
        if (!installers_plugins.contains (installer_name)) {
            error ("Unknown installer plugin");
        }

        context.register_vars ("installer", installers_plugins[installer_name].get_context_vars ());

        get_installer_plugin ().load_css_for_display (Gdk.Display.get_default ());
    }

    public async void init_steps_once () {
        if (steps_inited_once) {
            return;
        }

        for (int i = 0; i < steps.length; i++) {
            if (has_step (steps[i])) {
                var addin = get_step_addin (steps[i]);

                if (addin != null) {
                    yield addin.init_once ();
                }
            }
        }

        steps_inited_once = true;
    }
}
