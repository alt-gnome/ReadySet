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

    public void copy_to_user (string src, string destination, string username) throws Error {
        unowned Posix.Passwd? pwd = Posix.getpwnam (username);
        if (pwd == null) {
            throw new FileError.FAILED("User not found");
        }

        var src_file = File.new_for_path (src);
        var destination_file = File.new_build_filename (
            pwd.pw_dir,
            destination == "" ? src_file.get_basename () : destination
        );

        var uid = pwd.pw_uid;
        var gid = pwd.pw_gid;

        copy_with_chown (src_file, destination_file, uid, gid);
    }

    void copy_with_chown (File src, File dest, Posix.uid_t uid, Posix.gid_t gid) throws Error {
        var info = src.query_info("standard::type,unix::mode", FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
        bool is_dir = info.get_file_type() == FileType.DIRECTORY;

        if (is_dir) {
            if (!dest.query_exists ()) {
                dest.make_directory_with_parents(null);
            }
        } else {
            if (dest.query_exists ()) {
                dest.delete ();
            }
            src.copy(dest, FileCopyFlags.OVERWRITE, null);
        }

        dest.set_attribute_uint32("unix::mode", info.get_attribute_uint32("unix::mode"), FileQueryInfoFlags.NONE, null);

        Posix.chown(dest.get_path(), uid, gid);

        if (is_dir) {
            var en = src.enumerate_children("standard::name,standard::type", FileQueryInfoFlags.NOFOLLOW_SYMLINKS, null);
            FileInfo? child;
            while ((child = en.next_file(null)) != null) {
                copy_with_chown(src.get_child(child.get_name()), dest.get_child(child.get_name()), uid, gid);
            }
        }
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
