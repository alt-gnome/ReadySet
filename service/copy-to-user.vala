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

    //  src should be an absolute path
    //  dest should be an relative to user home dir path
    public void copy_to_user (string src, string dest, string username) throws Error {
        unowned Posix.Passwd? pwd = Posix.getpwnam (username);
        if (pwd == null) {
            throw new FileError.FAILED ("User '%s' not found", username);
        }

        var src_file = File.new_build_filename (src);

        if (!src_file.query_exists ()) {
            return;
        }

        var dest_file = File.new_build_filename (
            pwd.pw_dir,
            dest
        );

        message ("Copy '%s' to '%s'", src_file.get_path (), dest_file.get_path ());

        var uid = pwd.pw_uid;
        var gid = pwd.pw_gid;

        copy_with_chown (src_file, dest_file, uid, gid);
    }

    internal void copy_with_chown (File src, File dest, Posix.uid_t uid, Posix.gid_t gid) throws Error {
        var src_info = src.query_info (
            FileAttribute.STANDARD_TYPE + "," + FileAttribute.UNIX_MODE,
            FileQueryInfoFlags.NOFOLLOW_SYMLINKS
        );
        FileInfo? dest_info = null;

        bool src_is_dir = src_info.get_file_type () == FileType.DIRECTORY;
        bool dest_is_dir = false;

        if (dest.query_exists ()) {
            dest_info = dest.query_info (
                FileAttribute.STANDARD_TYPE + "," + FileAttribute.UNIX_MODE,
                FileQueryInfoFlags.NOFOLLOW_SYMLINKS
            );

            dest_is_dir = dest_info.get_file_type () == FileType.DIRECTORY;
        }

        if (src_is_dir) {
            if (dest_info != null) {
                if (!dest_is_dir) {
                    dest.delete ();
                }
            }

            ensure_dir_exist (dest, uid, gid);
        } else {
            if (dest_info != null) {
                if (dest_is_dir) {
                    rmtree (dest);
                } else {
                    dest.delete ();
                }
            }

            var dest_parent = dest.get_parent ();
            if (dest_parent != null) {
                ensure_dir_exist (dest_parent, uid, gid);
            }

            src.copy (dest, FileCopyFlags.OVERWRITE, null);
        }

        dest.set_attribute_uint32 (
            "unix::mode",
            src_info.get_attribute_uint32 (FileAttribute.UNIX_MODE),
            FileQueryInfoFlags.NONE,
            null
        );

        Posix.chown (dest.get_path (), uid, gid);

        if (src_is_dir) {
            var en = src.enumerate_children (
                FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE,
                FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                null
            );
            FileInfo? child;
            while ((child = en.next_file (null)) != null) {
                copy_with_chown (src.get_child (child.get_name ()), dest.get_child (child.get_name ()), uid, gid);
            }
        }
    }

    internal void ensure_dir_exist (File dir, Posix.uid_t uid, Posix.gid_t gid) throws Error {
        if (dir.query_exists ()) {
            return;
        }

        var parent = dir.get_parent ();
        if (parent != null && !parent.query_exists ()) {
            ensure_dir_exist (parent, uid, gid);
        }

        if (!dir.query_exists ()) {
            dir.make_directory (null);
            Posix.chown (dir.get_path (), uid, gid);
        }
    }

    void rmtree (File dir) {
        if (!dir.query_exists ()) {
            return;
        }

        try {
            var enumerator = dir.enumerate_children (
                FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE,
                FileQueryInfoFlags.NOFOLLOW_SYMLINKS
            );
            FileInfo? info;

            while ((info = enumerator.next_file ()) != null) {
                var file = dir.resolve_relative_path (info.get_name ());

                if (info.get_file_type () == FileType.DIRECTORY) {
                    rmtree (file);
                } else {
                    file.delete ();
                }
            }

            dir.delete ();
        } catch (Error e) {
            error (e.message);
        }
    }
}
