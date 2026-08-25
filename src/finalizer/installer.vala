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

public sealed class ReadySet.InstallerFinalizer : Finalizer {

    public override async void run (ProgressData progress_data) throws ApplyError {
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
