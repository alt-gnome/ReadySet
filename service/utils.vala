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

namespace ReadySet {

    public bool env_exec (string program, owned string[] env) throws Error {
        var launcher = new SubprocessLauncher (NONE);
        launcher.set_environ (env);

        var process = launcher.spawn (program);

        return process.wait_check ();
    }

    public void exec_user_pre_hooks (string[] env) throws Error {
        exec_hooks (File.new_build_filename (Config.DATADIR, Config.NAME, "pre-hooks", "system"), env);
    }

    public void exec_user_post_hooks (string[] env) throws Error {
        exec_hooks (File.new_build_filename (Config.DATADIR, Config.NAME, "post-hooks", "system"), env);
    }

    void exec_hooks (File hooks_dir, string[] env) throws Error {
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

            if (!env_exec (script, rs_env)) {
                warning ("Failed to exec hook '%s'", script);
            }
        }
    }

    void polkit_check (BusName sender, string action_id) throws DBusError {
        Polkit.AuthorizationResult result;

        try {
            var authority = Polkit.Authority.get_sync (null);
            var subject = new Polkit.SystemBusName (sender);
            result = authority.check_authorization_sync (
                subject,
                action_id,
                null,
                Polkit.CheckAuthorizationFlags.ALLOW_USER_INTERACTION,
                null
            );

        } catch (Error e) {
            throw new DBusError.ACCESS_DENIED ("Failed to check authorization: " + e.message);
        }

        if (!result.get_is_authorized ()) {
            throw new DBusError.ACCESS_DENIED ("Not authorized");
        }
    }
}
