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

    const ActionEntry[] ACTION_ENTRIES = {};

    static string[] all_steps = {};

    public bool show_steps { get; set; default = false; }

    public OptionsHandler options_handler;
    public Context context { get; private set; }

    Gee.HashMap<string, Addin> plugins = new Gee.HashMap<string, Addin> ();

    public Gee.ArrayList<BaseBarePage> loaded_pages { get; default = new Gee.ArrayList<BaseBarePage> (); }
    public Gee.ArrayList<Addin> loaded_addins { get; default = new Gee.ArrayList<Addin> (); }

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
        context = new Context (options_handler.idle);

        return -1;
    }

    protected override void startup () {
        base.startup ();

        if (!options_handler.idle) {
            try {
                pkexec ({
                    Path.build_filename (Config.LIBEXECDIR, "ready-set-ruler"),
                    "--generate-rules",
                    "--restart-polkit",
                    "--user", options_handler.user
                });
            } catch (Error e) {
                error ("Failed to generate rules: %s", e.message);
            }
        }

        init_plugins ();

        options_handler.fill_context (context);
        context.reload_window.connect (reload_window);
    }

    protected override void shutdown () {
        if (!options_handler.idle) {
            try {
                pkexec ({
                    Path.build_filename (Config.LIBEXECDIR, "ready-set-ruler"),
                    "--clear-rules",
                    "--restart-polkit"
                });
            } catch (Error e) {
                error ("Failed to clear generated rules: %s", e.message);
            }
        }

        base.shutdown ();
    }

    Peas.Engine get_engine () {
        var engine = Peas.Engine.get_default ();
        engine.enable_loader ("python");

        engine.add_search_path (
            Path.build_filename (Config.LIBDIR, Config.NAME, "plugins"),
            Path.build_filename (Config.DATADIR, Config.NAME, "plugins")
        );

        return engine;
    }

    void init_plugins () {
        var engine = get_engine ();
        var addins = new Peas.ExtensionSet.with_properties (engine, typeof (Addin), {}, {});

        for (int i = 0; i < engine.get_n_items (); i++) {
            engine.load_plugin ((Peas.PluginInfo) engine.get_item (i));
        }

        plugins.clear ();

        addins.foreach ((_set, info, extension) => {
            plugins[info.module_name] = (Addin) extension;
        });

        if (plugins.size == 0) {
            error ("\nNo plugins found\n");
        } else {
            print ("\nFound plugins:\n");
            foreach (var plugin in plugins) {
                print ("  %s\n", plugin.key);
            }
        }

        all_steps = get_all_steps ();

        for (int i = 0; i < all_steps.length; i++) {
            if (plugins[all_steps[i]] != null) {
                var addin = plugins[all_steps[i]];

                if (addin.allowed) {
                    context.register_vars (addin.get_context_vars ());
                }
            }
        }
    }

    public void init_pages () {
        loaded_pages.clear ();
        loaded_addins.clear ();

        print ("Loaded plugins:\n");
        for (int i = 0; i < all_steps.length; i++) {
            if (plugins[all_steps[i]] == null) {
                loaded_pages.add (new BasePage () {
                    is_ready = true
                });
                print ("  broken step (%s)\n", all_steps[i]);
            } else {
                var addin = plugins[all_steps[i]];
                if (addin.allowed) {
                    addin.set_data<string> (STEP_ID_LABEL, all_steps[i]);
                    loaded_addins.add (addin);
                    addin.context = context;
                    addin.load_css_for_display (Gdk.Display.get_default ());
                    if (!(all_steps[i] in inited_plugins)) {
                        addin.init_once ();
                        inited_plugins.add (all_steps[i]);
                    }
                    addin.init ();
                    foreach (var page in addin.build_pages ()) {
                        if (page.allowed) {
                            page.set_data<string> (STEP_ID_LABEL, all_steps[i]);
                            loaded_pages.add (page);
                        }
                    }
                    print ("  %s\n", all_steps[i]);
                }
            }
        }

        loaded_pages.add (new EndPage ());
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
}
