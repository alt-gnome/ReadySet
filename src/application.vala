/* Copyright (C) 2024-2025 Vladimir Romanov <rirusha@altlinux.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public sealed class ReadySet.Application: Adw.Application {

    const ActionEntry[] ACTION_ENTRIES = {
        { "finish", finish },
        { "reload-window", reload_window },
        { "hide-window", hide_window },
    };

    Peas.Engine steps_engine;
    Peas.Engine installers_engine;

    static string[] all_steps = {};

    public bool show_steps { get; set; default = false; }

    public OptionsHandler options_handler;
    public Context context { get; private set; }

    Gee.HashMap<string, StepAddin> steps_plugins = new Gee.HashMap<string, StepAddin> ();
    Gee.HashMap<string, InstallerAddin> installers_plugins = new Gee.HashMap<string, InstallerAddin> ();

    public signal void on_finish ();

    public bool has_installer {
        get {
            return options_handler.installer != null;
        }
    }

    public InstallerAddin? installer_plugin {
        owned get {
            if (!has_installer) {
                return null;
            }

            return installers_plugins[options_handler.installer];
        }
    }

    public PagesModel? model { get; private set; default = null; }

    Gee.ArrayList<string> inited_plugins = new Gee.ArrayList<string> ();

    public Application () {
        Object (
            application_id: Config.APP_ID_DYN,
            resource_base_path: "/org/altlinux/ReadySet/"
        );
    }

    static construct {
        typeof (BasePageDesc).ensure ();
        typeof (PagesIndicator).ensure ();
        typeof (PositionedStack).ensure ();
        typeof (StepRow).ensure ();
        typeof (StepsMainPage).ensure ();
        typeof (StepsSidebar).ensure ();

        typeof (BasePage).ensure ();
        typeof (EndPage).ensure ();
    }

    construct {
        add_main_option_entries (OptionsHandler.OPTION_ENTRIES);
        add_action_entries (ACTION_ENTRIES, this);
        set_accels_for_action ("app.quit", { "<primary>q" });
        set_accels_for_action ("win.about", { "<primary>o" });
    }

    protected override int handle_local_options (VariantDict options) {
        if (options.contains ("version")) {
            print ("%s\n", Config.VERSION);
            return 0;
        }

        options_handler = new OptionsHandler.from_options (options);
        context = new Context (options_handler.intact);

        return -1;
    }

    protected override void startup () {
        base.startup ();

        init_steps_plugins ();
        init_installers_plugins ();

        options_handler.fill_context (context);
        context.reload_window.connect (reload_window);
    }

    protected override void shutdown () {
        if (!options_handler.intact) {
            try {
                var proxy = get_ready_set_proxy ();
                proxy.exec_pre_hooks ();
            } catch (Error e) {
                error ("Failed to clear generated rules: %s", e.message);
            }
        }

        base.shutdown ();
    }

    Peas.Engine get_steps_engine () {
        if (steps_engine == null) {
            steps_engine = new Peas.Engine ();
            steps_engine.enable_loader ("python");

            steps_engine.add_search_path (
                Config.STEPS_PLUGINS_DIR,
                Config.STEPS_PLUGINS_DIR
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
                Config.INSTALLERS_PLUGINS_DIR
            );
        }

        return installers_engine;
    }

    void init_steps_plugins () {
        var engine = get_steps_engine ();
        var addins = new Peas.ExtensionSet.with_properties (engine, typeof (StepAddin), {}, {});

        for (int i = 0; i < engine.get_n_items (); i++) {
            engine.load_plugin ((Peas.PluginInfo) engine.get_item (i));
        }

        steps_plugins.clear ();

        addins.foreach ((_set, info, extension) => {
            steps_plugins[info.module_name] = (StepAddin) extension;
        });

        if (steps_plugins.size == 0) {
            error ("\nNo plugins found\n");
        } else {
            print ("\nFound steps plugins:\n");
            foreach (var plugin in steps_plugins) {
                print ("  %s\n", plugin.key);
            }
        }

        all_steps = get_all_steps ();

        for (int i = 0; i < all_steps.length; i++) {
            if (steps_plugins[all_steps[i]] != null) {
                var addin = steps_plugins[all_steps[i]];

                context.register_vars (addin.get_context_vars ());

                var vars = new HashTable<string, ContextVarInfo> (str_hash, str_equal);
                var var_name = "step-%s-enabled".printf (all_steps[i]);
                vars[var_name] = new ContextVarInfo (ContextType.BOOLEAN);
                vars[var_name].initial_value = true;
                context.register_vars (vars);
            }
        }
    }

    void init_installers_plugins () {
        var engine = get_installers_engine ();
        var addins = new Peas.ExtensionSet.with_properties (engine, typeof (InstallerAddin), {}, {});

        for (int i = 0; i < engine.get_n_items (); i++) {
            engine.load_plugin ((Peas.PluginInfo) engine.get_item (i));
        }

        installers_plugins.clear ();

        addins.foreach ((_set, info, extension) => {
            installers_plugins[info.module_name] = (InstallerAddin) extension;
        });

        if (installers_plugins.size != 0) {
            print ("\nFound installers plugins:\n");
            foreach (var plugin in installers_plugins) {
                print ("  %s\n", plugin.key);
            }
        }

        if (has_installer) {
            if (!installers_plugins.has_key (options_handler.installer)) {
                error ("Unknown installer plugin");
            }
        }
    }

    public void init_pages () {
        var pages = new Gee.ArrayList<PageInfo> ();

        print ("Loaded plugins:\n");
        for (int i = 0; i < all_steps.length; i++) {
            if (steps_plugins[all_steps[i]] == null) {
                pages.add (new PageInfo (
                    new BasePage () {
                        is_ready = true
                    },
                    null,
                    false
                ));
                print ("  broken step (%s)\n", all_steps[i]);
            } else {
                var addin = steps_plugins[all_steps[i]];

                addin.context = context;
                addin.load_css_for_display (Gdk.Display.get_default ());

                context.bind_context_to_property (
                    "step-%s-enabled".printf (all_steps[i]),
                    addin,
                    "accessible",
                    SYNC_CREATE
                );

                if (!(all_steps[i] in inited_plugins)) {
                    addin.init_once ();
                    inited_plugins.add (all_steps[i]);
                }

                foreach (var page in addin.build_pages ()) {
                    pages.add (new PageInfo (
                        page,
                        addin,
                        !(all_steps[i] in options_handler.steps_no_apply)
                    ));
                }
                print ("  %s\n", all_steps[i]);
            }
        }

        pages.add (new PageInfo (
            new EndPage (),
            null,
            false
        ));

        model = new PagesModel (pages);
    }

    string[] get_all_steps () {
        var steps_data = new Array<string> ();

        if (options_handler.steps != null) {
            foreach (var step in options_handler.steps) {
                steps_data.append_val (step);
            }

        } else {
            error (_("No steps specified"));
        }

        return steps_data.data;
    }

    void reload_window () {
        (active_window as ReadySet.Window)?.reload_window ();
    }

    void hide_window () {
        (active_window as ReadySet.Window)?.hide ();
    }

    public override void activate () {
        base.activate ();

        if (active_window == null) {
            if (context.has_key ("language-locale")) {
                var locale = context.get_string ("language-locale");
                if (locale != null) {
                    Intl.setlocale (ALL, locale);
                }
            }

            var win = new Window (this) {
                fullscreened = options_handler.fullscreen
            };

            win.present ();

        } else {
            active_window.present ();
        }
    }

    public new static ReadySet.Application get_default () {
        return (ReadySet.Application) GLib.Application.get_default ();
    }

    void finish () {
        on_finish ();
    }
}
