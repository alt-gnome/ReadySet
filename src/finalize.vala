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

public sealed class ReadySet.Finalizer : Object {

    public Context context { get; construct; }
    public PluginManager plugin_manager { get; construct; }
    public InstallerAddin? installer_plugin { get; construct; default = null; }
    public ProgressData progress_data { get; construct; }

    public Finalizer (
        Context context,
        PluginManager plugin_manager,
        InstallerAddin? installer_plugin,
        ProgressData progress_data
    ) {
        Object (
            context: context,
            plugin_manager: plugin_manager,
            installer_plugin: installer_plugin,
            progress_data: progress_data
        );
    }

    public async void run () throws ApplyError {
        switch (context.mode) {
            case INITIAL_SETUP:
                yield finalize_initial_setup ();
                break;
            case INSTALLER:
                yield finalize_installer ();
                break;
            default:
                assert_not_reached ();
        }
    }

    async void finalize_initial_setup () throws ApplyError {
        var steps = plugin_manager.steps;

        var passed_plugins = new Gee.ArrayList<string> ();

        for (int i = 0; i < steps.length; i++) {
            if (steps[i] == "welcome") {
                continue;
            }

            var addin = plugin_manager.get_step_addin (steps[i]);
            if (addin == null || !addin.enabled) {
                continue;
            }

            progress_data.value = 0.0;
            progress_data.message = "";

            yield addin.apply (progress_data);
            progress_data.value = 1.0;

            passed_plugins.add (steps[i]);
        }

        try {
            var raw_context = context.get_raw_string ();
            var env = new Gee.ArrayList<string> ();

            foreach (var key in raw_context.get_keys ()) {
                env.add ("%s=%s".printf (context_key_to_env_key (key), raw_context[key]));
            }

            string hooks_type = "post";
            string hooks_target = "initial-setup";

            var pre_hooks_dir = get_system_hooks_dir (hooks_type, hooks_target);

            foreach (var name in ReadySet.get_all_hooks_from_dir (pre_hooks_dir)) {
                ReadySet.real_exec_hook_from_dir (pre_hooks_dir, name, env.to_array ());
            }

            foreach (var name in yield get_ready_set_proxy ().get_all_hooks (hooks_type, hooks_target)) {
                yield get_ready_set_proxy ().exec_hook (hooks_type, hooks_target, name, env.to_array ());
            }
        } catch (Error e) {
            warning ("Error on executing post hooks: %s", e.message);
        }

        if (context.has_key ("user.username")) {
            var rs_settings = new Settings ("org.altlinux.ReadySet");
            rs_settings.set_strv ("performed-steps", passed_plugins.to_array ());

            const string[] FILES_TO_COPY = {
                ".config/dconf/user"
            };

            foreach (var file in FILES_TO_COPY) {
                try {
                    yield get_ready_set_proxy ().copy_to_user (
                        Path.build_filename (
                            Environment.get_home_dir (),
                            file
                        ),
                        file,
                        context.get_string ("user.username")
                    );
                } catch (Error e) {
                    warning ("Fail to copy to user: %s", e.message);
                }
            }
        }
    }

    async void finalize_installer () throws ApplyError {
        progress_data.message = _("Installing system…");

        yield installer_plugin.install (progress_data);

        try {
            var raw_context = context.get_raw_string ();
            var env = new Gee.ArrayList<string> ();

            foreach (var key in raw_context.get_keys ()) {
                env.add ("%s=%s".printf (context_key_to_env_key (key), raw_context[key]));
            }

            string hooks_type = "post";
            string hooks_target = "installer";

            foreach (var name in yield get_ready_set_proxy ().get_all_hooks (hooks_type, hooks_target)) {
                yield get_ready_set_proxy ().exec_hook (hooks_type, hooks_target, name, env.to_array ());
            }
        } catch (Error e) {
            warning ("Error on executing post hooks: %s", e.message);
        }

        progress_data.value = 1.0;
    }
}
