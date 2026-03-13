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

namespace ReadySet {

    public string context_key_to_env_key (string key) {
        var builder = new StringBuilder ();

        int next_index = 0;
        unichar c;

        while (key.get_next_char (ref next_index, out c)) {
            if (c == '-') {
                builder.append_unichar ('_');
            } else {
                builder.append_unichar (c.toupper ());
            }
        }

        return "CONTEXT_" + builder.free_and_steal ();
    }

    public const string STEP_ID_LABEL = "step-id";

    public delegate Gtk.Widget CreateFunc (PageInfo page);

    public async bool env_exec (string program, owned string[] env) throws Error {
        var launcher = new SubprocessLauncher (NONE);

        foreach (var e in env) {
            var parts = e.split ("=", 2);
            if (parts.length != 2) {
                warning ("Invalid environment variable: %s", e);
                return false;
            }
            launcher.setenv (parts[0], parts[1], true);
        }

        var process = launcher.spawn (program);

        return yield process.wait_check_async ();
    }

    public async void exec_user_pre_hooks (string[] env = {}) throws Error {
        yield exec_hooks (File.new_build_filename (Config.DATADIR, Config.NAME, "pre-hooks", "user"), env);
    }

    public async void exec_user_post_hooks (string[] env) throws Error {
        yield exec_hooks (File.new_build_filename (Config.DATADIR, Config.NAME, "post-hooks", "user"), env);
    }

    async void exec_hooks (File hooks_dir, string[] env) throws Error {
        var enumerator = hooks_dir.enumerate_children (
            "%s,%s,%s".printf (
                FileAttribute.STANDARD_NAME,
                FileAttribute.STANDARD_TYPE,
                FileAttribute.ACCESS_CAN_EXECUTE
            ),
            NONE
        );

        if (enumerator == null) {
            return;
        }

        FileInfo? info;
        while ((info = enumerator.next_file ()) != null) {
            if (!info.get_attribute_boolean (FileAttribute.ACCESS_CAN_EXECUTE)) {
                continue;
            }
            var type_ = info.get_file_type ();
            if (type_ != FileType.REGULAR) {
                continue;
            }

            var script = Path.build_filename (hooks_dir.get_path (), info.get_name ());

            var rs_env = new string[env.length];

            for (var i = 0; i < env.length; i++) {
                rs_env[i] = "READY_SET_" + env[i];
            }

            if (!(yield env_exec (script, rs_env))) {
                warning ("Failed to exec hook '%s'", script);
            }
        }
    }

    public bool in_group (string group_name) {
        unowned Posix.Passwd? passwd = Posix.getpwuid (Posix.getuid ());
        if (passwd == null) {
            return false;
        }

        var groups_n = Linux.getgroups (null);

        Posix.gid_t[] all_group_ids = new Posix.gid_t[groups_n];
        if (Linux.getgroups (all_group_ids) == -1) {
            return false;
        }

        foreach (var gid in all_group_ids) {
            unowned Posix.Group? gr = Posix.getgrgid (gid);
            if (gr.gr_name == group_name) {
                return true;
            }
        }

        return false;
    }
}
