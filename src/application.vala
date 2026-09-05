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

    ActionEntry[] action_entries = {
        ActionEntry () {
            name = "reload-window",
            activate = reload_window
        },
        ActionEntry () {
            name = "finish",
            activate = finish,
            parameter_type = "s"
        },
    };

    public string? command { get; construct; }

    ApplicationService app_service;

    public Application (string? command) {
        Object (
            application_id: Config.APP_ID_DYN,
            resource_base_path: "/org/altlinux/ReadySet/",
            command: command
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

        typeof (InitialSetupEndPage).ensure ();
        typeof (InstallerEndPage).ensure ();
    }

    construct {
        add_main_option_entries (OptionsHandler.OPTION_ENTRIES);

        var actions = action_entries.copy ();
        if (Config.NIGHTLY) {
            actions += ActionEntry () {
                name = "show-devel-window",
                activate = show_devel_window
            };
        }

        add_action_entries (
            actions,
            this
        );

        set_accels_for_action ("app.quit", { "<primary>q" });
        set_accels_for_action ("win.about", { "<primary>o" });

        set_option_context_parameter_string ("[COMMAND]");
        set_option_context_summary (CommandHandler.build_summary ());
    }

    protected override bool local_command_line (ref unowned string[] arguments, out int exit_status) {
        if (command == CommandHandler.BASH_COMP) {
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

        app_service = new ApplicationService (options);

        return -1;
    }

    protected override void startup () {
        base.startup ();

        app_service.init ();
    }

    void reload_window () {
        var window = active_window as ReadySet.Window;
        if (window != null) {
            window.reload_window.begin ();
        }
    }

    async void apply_only () {
        yield app_service.init_model ();

        var finalizer = app_service.finalizer_factory.build ();
        try {
            yield finalizer.run ();
            print ("Done!\n");

        } catch (ApplyError e) {
            var error_data = apply_error_to_data (e);
            print ("Failed: %s. %s\n", error_data.message, error_data.description);
            Process.exit (-1);
        }
    }

    public override void activate () {
        base.activate ();

        if (app_service.options_handler.apply_only) {
            hold ();
            apply_only.begin (() => {
                release ();
            });

            return;
        }

        if (command == CommandHandler.NTD) {
            hold ();
            app_service.is_ntd.begin ((obj, res) => {
                release ();
            });

            return;
        }

        if (active_window == null) {
            //  If mode is existing-user, window presents by itself after
            //  init.
            //  We do this because of in install/initial-setup modes
            //  we should show at  least one page with setup. In existing-user
            //  there can be situation where  there is nothing to do because
            //  of all steps where done at initial-setup stage. And if nothing
            //  to do, we can't show window for loading because blink.
            if (app_service.context.mode == EXISTING_USER) {
                hold ();
                app_service.init_model.begin (true, (obj, res) => {
                    if (app_service.init_model.end (res)) {
                        build_window ().present ();
                    }
                    release ();
                });
            } else {
                build_window ().present ();
            }

        } else {
            active_window.present ();
        }
    }

    Window build_window () {
        return new Window (this, app_service);
    }

    public new static ReadySet.Application? get_default () {
        return (ReadySet.Application?) GLib.Application.get_default ();
    }

    void show_devel_window () {
        new Devel.Window (app_service.context, app_service.options_handler).present ();
    }

    void finish (SimpleAction action, Variant? parameter) {
        switch (parameter.get_string ()) {
            case "quit":
                quit ();
                break;
            case "post-act":
                if (active_window != null) {
                    active_window.hide ();
                }
                if (!app_service.context.sandbox) {
                    app_service.post_act.do.begin ((obj, res) => {
                        if (!app_service.post_act.do.end (res)) {
                            quit ();
                        }
                    });
                }
                break;
            case "reboot":
                quit ();
                break;
        }
    }
}
