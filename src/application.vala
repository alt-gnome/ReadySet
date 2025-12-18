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

    const OptionEntry[] OPTION_ENTRIES = {
        { "version", 'v', 0, OptionArg.NONE, null, N_("Print version information and exit"), null },
        { "steps-file", 'f', 0, OptionArg.FILENAME, null, N_("Filename with steps"), "FILENAME" },
        { "steps", 's', 0, OptionArg.STRING, null, N_("Steps. E.g: `steps=language,keyboard`"), "STEPS" },
        { "idle", 'i', 0, OptionArg.NONE, null, N_("Idle run without doing anything"), null },
        { null }
    };

    static string[] all_steps = {};

    string? steps_filename = null;
    string[]? steps = null;

    public bool idle { get; private set; }

    public bool show_steps { get; set; default = false; }

    Context context;

    public Gee.ArrayList<BasePage> callback_pages { get; default = new Gee.ArrayList<BasePage> (); }

    public Application () {
        Object (
            application_id: Config.APP_ID_DYN,
            resource_base_path: "/org/altlinux/ReadySet/"
        );
    }

    static construct {
        typeof (BasePageDesc).ensure ();
        typeof (ContextRow).ensure ();
        typeof (MarginLabel).ensure ();
        typeof (PagesIndicator).ensure ();
        typeof (PositionedStack).ensure ();
        typeof (StepRow).ensure ();
        typeof (StepsMainPage).ensure ();
        typeof (StepsSidebar).ensure ();

        typeof (BasePage).ensure ();
        typeof (EndPage).ensure ();
        typeof (KeyboardPage).ensure ();
        typeof (UserPage).ensure ();
        typeof (UserWithRootPage).ensure ();
    }

    construct {
        add_main_option_entries (OPTION_ENTRIES);
        add_action_entries (ACTION_ENTRIES, this);
        set_accels_for_action ("app.quit", { "<primary>q" });

        context = new Context ();
        context.reload_window.connect (reload_window);
    }

    protected override int handle_local_options (VariantDict options) {
        if (options.contains ("version")) {
            print ("%s\n", Config.VERSION);
            return 0;

        }
        if (options.contains ("steps-file")) {
            steps_filename = options.lookup_value ("steps-file", null).get_bytestring ();

        }
        if (options.contains ("idle")) {
            idle = true;

        }
        if (options.contains ("steps")) {
            steps = options.lookup_value ("steps", null).get_string ().split (",");
            for (int i = 0; i < steps.length; i++) {
                steps[i] = steps[i].strip ();
            }
        }

        return -1;
    }

    Peas.Engine get_engine () {
        var engine = Peas.Engine.get_default ();
        engine.enable_loader ("python");

        engine.add_search_path (
            Path.build_filename (Config.LIBDIR, "ready-set", "plugins"),
            Path.build_filename (Config.DATADIR, "ready-set", "plugins")
        );

        return engine;
    }

    public BasePage[] get_pages () {
        if (all_steps.length == 0) {
            all_steps = get_all_steps ();
        }

        var pages = new Gee.ArrayList<BasePage> ();

        var engine = get_engine ();
        var addins = new Peas.ExtensionSet.with_properties (engine, typeof (Addin), {}, {});

        for (int i = 0; i < engine.get_n_items (); i++) {
            engine.load_plugin ((Peas.PluginInfo) engine.get_item (i));
        }

        var plugins = new Gee.HashMap<string, Addin> ();

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

        print ("Loaded plugins:\n");
        for (int i = 0; i < all_steps.length; i++) {
            if (plugins[all_steps[i]] == null) {
                pages.add (new BasePage () {
                    is_ready = true
                });
                print ("  broken step");
            } else {
                var addin = plugins[all_steps[i]];
                addin.context = context;
                pages.add_all_array (addin.build_pages ());
                print ("  %s\n", all_steps[i]);
            }
        }

        pages.add (new EndPage ());

        return pages.to_array ();
    }

    string[] get_all_steps () {
        var app = ReadySet.Application.get_default ();

        var steps_data = new Array<string> ();

        if (app.steps_filename != null) {
            var steps_file = File.new_for_path (app.steps_filename);

            if (!steps_file.query_exists ()) {
                error (_("Steps file doesn't exists"));
            }

            uint8[] steps_file_content;
            try {
                if (!steps_file.load_contents (null, out steps_file_content, null)) {
                    error (_("Steps file is empty"));
                }
            } catch (Error e) {
                error (_("Error loading steps file: %s"), e.message);
            }

            string[] data = ((string) steps_file_content).split ("\n");

            for (int i = 0; i < data.length; i++) {
                data[i] = data[i].strip ();
            };

            foreach (var line in data) {
                var stripped_line = line.strip ();

                if (stripped_line != "" && !stripped_line.has_prefix ("#")) {
                    steps_data.append_val (stripped_line);
                }
            }

        } else if (app.steps != null) {
            foreach (var step in app.steps) {
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
            var win = new Window (this);

            win.present ();

        } else {
            active_window.present ();
        }
    }

    public new static ReadySet.Application get_default () {
        return (ReadySet.Application) GLib.Application.get_default ();
    }
}
