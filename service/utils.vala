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

    const string RULE_PREFIX = "org.altlinux.ReadySet.Plugin.";
    const string REPLACE_USER_PATTERN = "--READY-SET-USER--";

    inline File get_rs_rules_dir_file () {
        return File.new_build_filename (Config.DATADIR, Config.NAME, "rules.d");
    }

    inline File get_rules_dir_file () {
        return File.new_build_filename (Config.SYSCONFDIR, "polkit-1", "rules.d");
    }

    public void reload_polkit () throws Error {
        get_systemd_proxy ().reload_unit ("polkit.service", "replace");
    }

    public void generate_rules_internal (string user) {
        var rules_dir_file = get_rs_rules_dir_file ();

        try {
            var enumerator = rules_dir_file.enumerate_children (
                "%s,%s".printf (
                    FileAttribute.STANDARD_NAME,
                    FileAttribute.STANDARD_TYPE
                ),
                NONE
            );

            if (enumerator == null) {
                return;
            }

            FileInfo? info;
            while ((info = enumerator.next_file ()) != null) {
                var type_ = info.get_file_type ();
                if (type_ != FileType.REGULAR && type_ != FileType.SYMBOLIC_LINK) {
                    continue;
                }

                var dest_file = File.new_build_filename (get_rules_dir_file ().get_path (), info.get_name ());

                if (dest_file.query_exists ()) {
                    warning ("Rule file %s already exists, skipping", dest_file.get_path ());
                    continue;
                }

                var rules_file = rules_dir_file.get_child (info.get_name ());

                string rule_content;
                FileUtils.get_contents (rules_file.get_path (), out rule_content);

                FileUtils.set_contents (
                    dest_file.get_path (),
                    rule_content.replace (REPLACE_USER_PATTERN, user)
                );
            }

            enumerator.close ();

        } catch (Error e) {
            error ("Failed to generate rules: %s", e.message);
        }
    }

    public void clear_rules_internal () {
        var rules_dir_file = get_rules_dir_file ();

        try {
            var enumerator = rules_dir_file.enumerate_children (
                "%s,%s".printf (
                    FileAttribute.STANDARD_NAME,
                    FileAttribute.STANDARD_TYPE
                ),
                NONE
            );

            if (enumerator == null) {
                return;
            }

            FileInfo? info;
            while ((info = enumerator.next_file ()) != null) {
                var type_ = info.get_file_type ();
                if (type_ != FileType.REGULAR) {
                    continue;
                }

                if (info.get_name ().has_prefix (RULE_PREFIX)) {
                    File.new_build_filename (rules_dir_file.get_path (), info.get_name ()).delete ();
                }
            }

            enumerator.close ();

        } catch (Error e) {
            error ("Failed to generate rules: %s", e.message);
        }
    }

    public bool env_exec (string program, string[] env) throws Error {
        var launcher = new SubprocessLauncher (NONE);
        launcher.set_environ (env);

        var process = launcher.spawn (program);

        return process.wait_check ();
    }

    public void exec_pre_hooks_internal (string[] env) throws Error {
        exec_hooks_internal (File.new_build_filename (Config.DATADIR, Config.NAME, "pre-hooks"), env);
    }

    public void exec_post_hooks_internal (string[] env) throws Error {
        exec_hooks_internal (File.new_build_filename (Config.DATADIR, Config.NAME, "post-hooks"), env);
    }

    void exec_hooks_internal (File hooks_dir, string[] env) throws Error {
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
            var type_ = info.get_file_type ();
            if (type_ != FileType.REGULAR) {
                continue;
            }

            var script = Path.build_filename (hooks_dir.get_path (), info.get_name ());

            env_exec (script, env);
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
