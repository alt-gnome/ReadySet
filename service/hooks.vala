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

    const string[] GOOD_TYPES = { "pre", "post" };

    const string[] GOOD_TARGETS = { "initial-setup", "installer" };

    public void check_type_target (string type_, string target) throws Error {
        if (!(type_ in GOOD_TYPES)) {
            throw new DBusError.INVALID_ARGS (
                "Wrong type: %s. Available types: %s",
                type_,
                string.joinv (", ", GOOD_TYPES)
            );
        }
        if (!(target in GOOD_TARGETS)) {
            throw new DBusError.INVALID_ARGS (
                "Wrong target: %s. Available targets: %s",
                target,
                string.joinv (", ", GOOD_TARGETS)
            );
        }
    }

    File get_system_hooks_dir (string type_, string target) {
        return File.new_build_filename (
            Config.DATADIR,
            Config.NAME,
            "%s-%s-hooks".printf (target, type_),
            "system"
        );
    }

    public File get_user_hooks_dir (string type_, string target) {
        return File.new_build_filename (
            Config.DATADIR,
            Config.NAME,
            "%s-%s-hooks".printf (target, type_),
            "user"
        );
    }

    public string[] get_all_hooks_from_dir (File dir) throws Error {
        var enumerator = dir.enumerate_children (
            "%s,%s,%s".printf (
                FileAttribute.STANDARD_NAME,
                FileAttribute.STANDARD_TYPE,
                FileAttribute.ACCESS_CAN_EXECUTE
            ),
            NONE
        );

        if (enumerator == null) {
            return {};
        }

        string[] output = {};

        FileInfo? info;
        while ((info = enumerator.next_file ()) != null) {
            if (!info.get_attribute_boolean (FileAttribute.ACCESS_CAN_EXECUTE)) {
                continue;
            }
            if (info.get_file_type () != FileType.REGULAR) {
                continue;
            }

            output += info.get_name ();
        }

        return output;
    }

    public bool env_exec (string program, owned string[] env) throws Error {
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

        return process.wait_check ();
    }

    public bool real_exec_hook (string type_, string target, string name, string[] env = {}) throws Error {
        var hooks_dir = get_system_hooks_dir (type_, target);

        return real_exec_hook_from_dir (hooks_dir, name, env);
    }

    bool real_exec_hook_from_dir (File dir, string name, string[] env = {}) throws Error {
        var script = Path.build_filename (dir.get_path (), name);

        var rs_env = new string[env.length];

        for (var i = 0; i < env.length; i++) {
            rs_env[i] = "READY_SET_" + env[i];
        }

        return env_exec (script, rs_env);
    }
}
