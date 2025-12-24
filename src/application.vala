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

    string? steps_filename = null;
    string[]? steps = null;
    bool fullscreen = false;

    const OptionEntry[] OPTION_ENTRIES = {
        { "version", 'v', 0, OptionArg.NONE, null, N_("Print version information and exit"), null },
        { "steps-file", 'f', 0, OptionArg.FILENAME, null, N_("Filename with steps"), "FILENAME" },
        { "steps", 's', 0, OptionArg.STRING, null, N_("Steps. E.g: `steps=language,keyboard`"), "STEPS" },
        { "context", 'c', 0, OptionArg.STRING_ARRAY, null, N_("Context vars"), "CONTEXT" },
        { "conf-file", 'C', 0, OptionArg.FILENAME, null, N_("App config file"), "CONF-FILE" },
        { "idle", 'i', 0, OptionArg.NONE, null, N_("Idle run without doing anything"), null },
        { "fullscreen", 'F', 0, OptionArg.NONE, null, N_("Run window in fullscreen"), null },
        { null }
    };

    static string[] all_steps = {};

    public bool show_steps { get; set; default = false; }

    public Context context { get; private set; }

    Gee.HashMap<string, Addin> plugins = new Gee.HashMap<string, Addin> ();

    public Gee.ArrayList<BasePage> loaded_pages { get; default = new Gee.ArrayList<BasePage> (); }
    public Gee.ArrayList<Addin> loaded_addins { get; default = new Gee.ArrayList<Addin> (); }

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
        add_main_option_entries (OPTION_ENTRIES);
        add_action_entries (ACTION_ENTRIES, this);
        set_accels_for_action ("app.quit", { "<primary>q" });
    }

    protected override int handle_local_options (VariantDict options) {
        if (options.contains ("version")) {
            print ("%s\n", Config.VERSION);
            return 0;
        }

        var conf_keyfile = new KeyFile ();
        conf_keyfile.set_list_separator (',');
        var app_group_name = "Application";
        var has_app_group = false;
        var ctx_group_name = "Context";

        var idle = false;

        try {
            var idle_opt_name = "idle";
            if (options.contains (idle_opt_name)) {
                idle = true;
            }

            if (options.contains ("conf-file")) {
                var config_filename = options.lookup_value ("conf-file", null).get_bytestring ();
                conf_keyfile.load_from_file (config_filename, KeyFileFlags.NONE);
                has_app_group = conf_keyfile.has_group (app_group_name);

                //  Also check if idle not set by args
                if (!idle && kf_has_key (conf_keyfile, app_group_name, idle_opt_name)) {
                    idle = conf_keyfile.get_boolean (app_group_name, idle_opt_name);
                }

                context = new Context (idle);
                context.load_from_keyfile (conf_keyfile, ctx_group_name);
            } else {
                context = new Context (idle);
            }

            context.reload_window.connect (reload_window);

            var steps_file_opt_name = "steps-file";
            if (options.contains (steps_file_opt_name)) {
                steps_filename = options.lookup_value (steps_file_opt_name, null).get_bytestring ();
            } else if (kf_has_key (conf_keyfile, app_group_name, steps_file_opt_name)) {
                steps_filename = conf_keyfile.get_string (app_group_name, steps_file_opt_name);
            }

            var fullscreen_opt_name = "fullscreen";
            if (options.contains (fullscreen_opt_name)) {
                fullscreen = true;
            } else if (kf_has_key (conf_keyfile, app_group_name, fullscreen_opt_name)) {
                fullscreen = conf_keyfile.get_boolean (app_group_name, fullscreen_opt_name);
            }

            var steps_opt_name = "steps";
            if (options.contains (steps_opt_name)) {
                steps = options.lookup_value (steps_opt_name, null).get_string ().split (",");
                for (int i = 0; i < steps.length; i++) {
                    steps[i] = steps[i].strip ();
                }
            } else if (kf_has_key (conf_keyfile, app_group_name, steps_opt_name)) {
                steps = conf_keyfile.get_string_list (app_group_name, steps_opt_name);
                for (int i = 0; i < steps.length; i++) {
                    steps[i] = steps[i].strip ();
                }
            }

            if (options.contains ("context")) {
                var ctx = options.lookup_value ("context", null).get_strv ();
                foreach (var c in ctx) {
                    var parts = c.split ("=", 2);
                    if (parts.length != 2) {
                        error ("Invalid context: %s", c);
                    }
                    context.set_raw (parts[0], parts[1]);
                }
            }
        } catch (Error e) {
            error ("Error in working with config file: %s", e.message);
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
    }

    public void init_pages () {
        loaded_pages.clear ();
        loaded_addins.clear ();

        if (all_steps.length == 0) {
            all_steps = get_all_steps ();
        }

        if (plugins.size == 0) {
            init_plugins ();
        }

        print ("Loaded plugins:\n");
        for (int i = 0; i < all_steps.length; i++) {
            if (plugins[all_steps[i]] == null) {
                loaded_pages.add (new BasePage () {
                    is_ready = true
                });
                print ("  broken step (%s)\n", all_steps[i]);
            } else {
                var addin = plugins[all_steps[i]];
                if (addin.allowed ()) {
                    loaded_addins.add (addin);
                    addin.context = context;
                    loaded_pages.add_all_array (addin.build_pages ());
                    print ("  %s\n", all_steps[i]);
                }
            }
        }

        loaded_pages.add (new EndPage ());
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
            var locale = context.get_string ("locale");
            if (locale != null) {
                Intl.setlocale (ALL, locale);
            }

            var win = new Window (this);

            win.present ();
            if (fullscreen) {
                win.fullscreen ();
            }

        } else {
            active_window.present ();
        }
    }

    public new static ReadySet.Application get_default () {
        return (ReadySet.Application) GLib.Application.get_default ();
    }
}
