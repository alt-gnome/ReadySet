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

public sealed class ReadySet.InitialSetupFinalizer : Finalizer {

    Gee.ArrayList<StepAddin> reorder_steps (Gee.ArrayList<StepAddin> steps) {
        var module_to_step = new Gee.HashMap<string, StepAddin> ();
        foreach (var step in steps) {
            module_to_step[step.plugin_name] = step;
        }

        var dependents = new Gee.HashMap<string, Gee.ArrayList<string>> ();
        var in_degree = new Gee.HashMap<string, int> ();

        foreach (var step in steps) {
            string module_name = step.plugin_name;
            in_degree[module_name] = 0;
            dependents[module_name] = new Gee.ArrayList<string> ();
        }

        foreach (var step in steps) {
            string module_name = step.plugin_name;
            if (step is ApplyAfter) {
                foreach (var dep in ((ApplyAfter) step).get_apply_after ()) {
                    if (!module_to_step.has_key (dep)) {
                        continue;
                    }

                    dependents[dep].add (module_name);
                    in_degree[module_name] = in_degree[module_name] + 1;
                }
            }
        }

        var queue = new Gee.ArrayList<string> ();
        foreach (var step in steps) {
            string module_name = step.plugin_name;
            if (in_degree[module_name] == 0) {
                queue.add (module_name);
            }
        }

        var sorted = new Gee.ArrayList<StepAddin> ();
        while (queue.size > 0) {
            string module_name = queue.remove_at (0);
            sorted.add (module_to_step[module_name]);

            foreach (var dependent in dependents[module_name]) {
                in_degree[dependent] = in_degree[dependent] - 1;
                if (in_degree[dependent] == 0) {
                    queue.add (dependent);
                }
            }
        }

        if (sorted.size < steps.size) {
            critical ("Cycle detected in apply_after dependencies");
        }

        return sorted;
    }

    public override async void run (ProgressData progress_data) throws ApplyError {
        Gee.ArrayList<StepAddin> steps_addins_arr = new Gee.ArrayList<StepAddin> ();

        for (int i = 0; i < model.get_n_items_unfiltered (); i++) {
            var page_info = (PageInfo) model.get_item_unfiltered (i);

            if (!page_info.can_be_applyed ()) {
                continue;
            }

            if (page_info.plugin in steps_addins_arr) {
                continue;
            }

            steps_addins_arr.add (page_info.plugin);
        }

        steps_addins_arr = reorder_steps (steps_addins_arr);

        string[] passed_plugins = {};
        var files_to_copy = new Gee.ArrayList<string>.wrap ({
            ".config/dconf/user",
        });

        foreach (var addin in steps_addins_arr) {
            progress_data.value = 0.0;
            progress_data.message = "";

            yield addin.apply (progress_data);
            progress_data.value = 1.0;

            passed_plugins += addin.plugin_info.module_name;

            if (addin is HasFilesToCopy) {
                files_to_copy.add_all_array (((HasFilesToCopy) addin).get_files_to_copy ());
            }
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
            update_performed_steps (passed_plugins);

            foreach (var file in files_to_copy) {
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
}
