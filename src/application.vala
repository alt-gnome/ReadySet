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

public sealed class ReadySet.Application: Adw.Application {

    const ActionEntry[] ACTION_ENTRIES = {
        { "reload-window", reload_window },
    };

    public bool show_steps { get; set; default = false; }

    internal OptionsHandler options_handler;
    internal PluginManager plugin_manager { get; private set; }
    internal Context context { get; private set; }

    Gee.ArrayList<Binding> context_bindings = new Gee.ArrayList<Binding> ();

    public bool can_close {
        get {
            return Config.NIGHTLY || options_handler.can_close;
        }
    }

    bool has_installer {
        get {
            return options_handler.installer != null;
        }
    }

    public InstallerAddin? installer_plugin {
        owned get {
            if (!has_installer) {
                return null;
            }

            return plugin_manager.get_installer_plugin ();
        }
    }

    public PagesModel? model { get; private set; default = null; }

    public Application () {
        Object (
            application_id: Config.APP_ID_DYN,
            resource_base_path: "/org/altlinux/ReadySet/"
        );
    }

    static construct {
        //  Ensure some libready-set types
        typeof (StatusPage).ensure ();
        typeof (BasePage).ensure ();

        typeof (PagesIndicator).ensure ();
        typeof (PositionedStack).ensure ();
        typeof (StepRow).ensure ();
        typeof (StepsMainPage).ensure ();
        typeof (StepsSidebar).ensure ();

        typeof (EndPage).ensure ();
    }

    construct {
        add_main_option_entries (OptionsHandler.OPTION_ENTRIES);
        add_action_entries (ACTION_ENTRIES, this);
        set_accels_for_action ("app.quit", { "<primary>q" });
        set_accels_for_action ("win.about", { "<primary>o" });

        set_option_context_parameter_string ("[COMMAND]");
        set_option_context_summary (
            "Commands:\n"
            + "  generate-bash-completion    Output bash completion script"
        );
    }

    protected override bool local_command_line (ref unowned string[] arguments, out int exit_status) {
        if (arguments.length > 1 && arguments[1] == "generate-bash-completion") {
            Completions.print_completion_script ();
            exit_status = 0;
            return true;
        }
        return base.local_command_line (ref arguments, out exit_status);
    }

    protected override int handle_local_options (VariantDict options) {
        if (options.contains ("version")) {
            print ("%s\n", Config.VERSION);
            return 0;
        }

        options_handler = new OptionsHandler.from_options (options);
        context = new Context (options_handler.sandbox);
        plugin_manager = new PluginManager (context);

        return -1;
    }

    protected override void startup () {
        base.startup ();

        options_handler.fill_context (context);
        context.reload_window.connect (reload_window);

        plugin_manager.init (options_handler.installer);

        init_lib_css ();

#if DEVEL
        if (options_handler.force_mode == null) {
#endif
            if (installer_plugin != null) {
                context.mode = INSTALLER;
            } else if (in_group ("ready-set") || in_group ("gnome-initial-setup")) {
                context.mode = INITIAL_SETUP;
            } else {
                context.mode = EXISTING_USER;
            }
#if DEVEL
        } else {
            context.mode = Mode.from_string (options_handler.force_mode);
        }
#endif

        plugin_manager.check_steps (options_handler.steps);

        if (!options_handler.sandbox) {
            exec_pre_hooks.begin ();
        }
    }

    async void exec_pre_hooks () {
        try {
            if (context.mode == Mode.INITIAL_SETUP) {
                yield real_exec_pre_hooks ();
                yield get_ready_set_proxy ().exec_pre_hooks ();
            } else if (context.mode == Mode.INSTALLER) {
                yield get_ready_set_proxy ().exec_installer_pre_hooks ();
            }

        } catch (IOError e) {
            warning ("IOError on executing pre hooks: %s", e.message);
        } catch (Error e) {
            error ("Failed to executing pre hooks: %s", e.message);
        }
    }

    public async void build_steps () {
        var pages = new Gee.ArrayList<PageInfo> ();

        string[] enabled_plugins = {};

        var initial_position = model == null ? 0 : model.get_selected ();

        yield plugin_manager.init_steps_once ();
        var steps = plugin_manager.steps;

        print ("Loaded steps:\n");
        for (int i = 0; i < steps.length; i++) {
            if (!plugin_manager.has_step (steps[i])) {
                pages.add (new PageInfo (
                    new BasePage.unknown () {
                        is_ready = true
                    },
                    null
                ));
                print ("  broken step (%s)\n", steps[i]);
            } else {
                var addin = plugin_manager.get_step_addin (steps[i]);

                if (addin != null) {
                    if (addin.enabled) {
                        enabled_plugins += addin.plugin_info.module_name;
                    }

                    var addin_pages = yield addin.build_pages ();
                    if (addin_pages.length == 0) {
                        pages.add (new PageInfo (
                            null,
                            addin
                        ));

                    } else {
                        foreach (var page in (yield addin.build_pages ())) {
                            pages.add (new PageInfo (
                                page,
                                addin
                            ));
                        }
                    }
                    print ("  %s\n", steps[i]);
                } else {
                    var installer_page = installer_plugin.build_page (plugin_manager.get_real_page_id (steps[i]));
                    if (installer_page != null) {
                        pages.add (new PageInfo (
                            installer_page,
                            null
                        ));
                        print ("  %s\n", steps[i]);
                    } else {
                        print ("  %s (Skipped: failed to build page)\n", steps[i]);
                    }
                }

            }

            Idle.add (build_steps.callback);
            yield;
        }

        if (context.mode == EXISTING_USER) {
            if (check_nothing_to_do (enabled_plugins)) {
                print ("There is nothing to do\n");
                quit ();
                return;
            }
        }

        model = new PagesModel (pages);
        model.select_item (initial_position, true);
    }

    bool check_nothing_to_do (string[] enabled_plugins) {
        var settings = new Settings ("org.altlinux.ReadySet");
        if (!settings.get_boolean ("existing-user-mode-enabled")) {
            return true;
        }

        var ntd = false;

        if (enabled_plugins.length == 1) {
            if (enabled_plugins[0] == "welcome") {
                ntd = true;
            }
        } else if (enabled_plugins.length == 0) {
            ntd = true;
        }

        return ntd;
    }

    void reload_window () {
        var window = active_window as ReadySet.Window;
        if (window != null) {
            window.reload_window.begin ();
        }
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
                fullscreened = options_handler.fullscreen,
                default_width = options_handler.width,
                default_height = options_handler.height,
                resizable = options_handler.resizable
            };

            //  If mode is existing-user, window presents by itself after
            //  init. 
            //  We do this because of in install/initial-setup modes
            //  we should show at  least one page with setup. In existing-user
            //  there can be situation where  there is nothing to do because
            //  of all steps where done at initial-setup stage. And if nothing
            //  to do, we can't show window for loading because blink.
            if (context.mode != EXISTING_USER) {
                win.present ();
            }

        } else {
            active_window.present ();
        }
    }

    public new static ReadySet.Application get_default () {
        return (ReadySet.Application) GLib.Application.get_default ();
    }

    public void hide_window () {
        if (active_window != null) {
            active_window.hide ();
        }
    }
}
