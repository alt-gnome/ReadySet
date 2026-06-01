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

static string temp_root;
static string test_user_home;
static uid_t test_uid;
static gid_t test_gid;

void set_up () {
    try {
        temp_root = DirUtils.make_tmp ("copy_test_XXXXXX");
    } catch (Error e) {
        critical ("Failed to create temp dir: %s", e.message);
        return;
    }
    test_user_home = Path.build_filename (temp_root, "user_home");
    DirUtils.create_with_parents (test_user_home, 0755);
    test_uid = Posix.getuid ();
    test_gid = Posix.getgid ();
}

File create_test_file (string path, string content, int mode) throws Error {
    var file = File.new_for_path (path);
    var parent = file.get_parent ();
    if (parent != null && !parent.query_exists ()) {
        parent.make_directory_with_parents (null);
    }
    FileUtils.set_contents (file.get_path (), content);
    Posix.chmod (file.get_path (), mode);
    return file;
}

private static void create_test_dir (string path, int mode) throws Error {
    DirUtils.create_with_parents (path, mode);
    Posix.chmod (path, mode);
}

private static void verify_ownership (File file, uid_t uid, gid_t gid) throws Error {
    var info = file.query_info ("unix::uid,unix::gid", FileQueryInfoFlags.NOFOLLOW_SYMLINKS, null);
    GLib.assert (info.get_attribute_uint32 ("unix::uid") == uid);
    GLib.assert (info.get_attribute_uint32 ("unix::gid") == gid);
}

private static void verify_mode (File file, uint32 mode) throws Error {
    var info = file.query_info ("unix::mode", FileQueryInfoFlags.NOFOLLOW_SYMLINKS, null);
    GLib.assert ((info.get_attribute_uint32 ("unix::mode") & 0777) == (mode & 0777));
}

private static void verify_content (File file, string expected) throws Error {
    string content;
    FileUtils.get_contents (file.get_path (), out content);
    GLib.assert (content == expected);
}

public static void test_src_not_exists () {
    try {
        ReadySet.copy_to_user ("/nonexistent/path", "dest/file", "root");
    } catch (Error e) {
        GLib.assert_not_reached ();
    }
    var dest = File.new_build_filename (test_user_home, "dest/file");
    GLib.assert (!dest.query_exists ());
}

public static void test_user_not_found () {
    try {
        ReadySet.copy_to_user ("/any/path", "dest", "nonexistent_user_xyz");
        GLib.assert_not_reached ();
    } catch (FileError.FAILED e) {
        GLib.assert (e.message.contains ("not found"));
    } catch (Error e) {
        GLib.assert_not_reached ();
    }
}

public static void test_copy_file_new_dest () {
    try {
        var src = create_test_file (Path.build_filename (temp_root, "src.txt"), "hello", 0644);
        ReadySet.copy_with_chown (src, File.new_build_filename (test_user_home, "out.txt"), test_uid, test_gid);

        var dest = File.new_build_filename (test_user_home, "out.txt");
        GLib.assert (dest.query_exists ());
        verify_content (dest, "hello");
        verify_ownership (dest, test_uid, test_gid);
        verify_mode (dest, 0644);
    } catch (Error e) {
        error (e.message);
    }
}

public static void test_copy_file_overwrite () {
    try {
        var dest_path = Path.build_filename (test_user_home, "overwrite.txt");
        create_test_file (dest_path, "old", 0600);
        var src = create_test_file (Path.build_filename (temp_root, "src.txt"), "new", 0755);

        ReadySet.copy_with_chown (src, File.new_for_path (dest_path), test_uid, test_gid);

        var dest = File.new_for_path (dest_path);
        verify_content (dest, "new");
        verify_mode (dest, 0755);
    } catch (Error e) {
        error (e.message);
    }
}

public static void test_file_replaces_dir () {
    try {
        var dest_path = Path.build_filename (test_user_home, "target");
        create_test_dir (dest_path, 0755);
        create_test_file (Path.build_filename (dest_path, "inner.txt"), "x", 0644);

        var src = create_test_file (Path.build_filename (temp_root, "src.txt"), "file_content", 0644);
        ReadySet.copy_with_chown (src, File.new_build_filename (dest_path), test_uid, test_gid);

        var dest = File.new_for_path (dest_path);
        GLib.assert (dest.query_exists ());
        GLib.assert (dest.query_file_type (FileQueryInfoFlags.NOFOLLOW_SYMLINKS, null) == FileType.REGULAR);
        verify_content (dest, "file_content");
    } catch (Error e) {
        error (e.message);
    }
}

public static void test_copy_dir () {
    try {
        var src_dir = Path.build_filename (temp_root, "srcdir");
        create_test_dir (src_dir, 0750);
        create_test_file (Path.build_filename (src_dir, "a.txt"), "aaa", 0640);
        create_test_dir (Path.build_filename (src_dir, "sub"), 0700);
        create_test_file (Path.build_filename (src_dir, "sub", "b.txt"), "bbb", 0600);

        ReadySet.copy_with_chown (
            File.new_for_path (src_dir),
            File.new_build_filename (test_user_home, "destdir"),
            test_uid, test_gid
        );

        var dest = File.new_build_filename (test_user_home, "destdir");
        GLib.assert (dest.query_exists ());
        verify_ownership (dest, test_uid, test_gid);
        verify_mode (dest, 0750);

        var a = dest.get_child ("a.txt");
        verify_content (a, "aaa");
        verify_ownership (a, test_uid, test_gid);
        verify_mode (a, 0640);

        var b = dest.get_child ("sub/b.txt");
        verify_content (b, "bbb");
        verify_ownership (b, test_uid, test_gid);
        verify_mode (b, 0600);
    } catch (Error e) {
        error (e.message);
    }
}

public static void test_nested_dirs_chown () {
    try {
        var src = create_test_file (Path.build_filename (temp_root, "f.txt"), "x", 0644);
        ReadySet.copy_with_chown (
            src,
            File.new_build_filename (test_user_home, "a/b/c/f.txt"),
            test_uid, test_gid
        );

        string[] subs = {"a", "a/b", "a/b/c"};
        foreach (string sub in subs) {
            var d = File.new_build_filename (test_user_home, sub);
            verify_ownership (d, test_uid, test_gid);
        }
        var f = File.new_build_filename (test_user_home, "a/b/c/f.txt");
        verify_content (f, "x");
        verify_ownership (f, test_uid, test_gid);
    } catch (Error e) {
        error (e.message);
    }
}

public static void test_dir_replaces_file () {
    try {
        var dest_path = Path.build_filename (test_user_home, "target_file");
        create_test_file (dest_path, "old", 0644);

        var src_dir = Path.build_filename (temp_root, "srcdir");
        create_test_dir (src_dir, 0755);
        create_test_file (Path.build_filename (src_dir, "x.txt"), "y", 0644);

        ReadySet.copy_with_chown (
            File.new_for_path (src_dir),
            File.new_for_path (dest_path),
            test_uid, test_gid
        );

        var dest = File.new_for_path (dest_path);
        GLib.assert (dest.query_exists ());
        GLib.assert (dest.query_file_type (FileQueryInfoFlags.NOFOLLOW_SYMLINKS, null) == FileType.DIRECTORY);
        verify_ownership (dest, test_uid, test_gid);
    } catch (Error e) {
        error (e.message);
    }
}

public static int main (string[] args) {
    Test.init (ref args);

    set_up ();

    Test.add_func ("/copy/file_new", test_copy_file_new_dest);
    Test.add_func ("/copy/file_overwrite", test_copy_file_overwrite);
    Test.add_func ("/copy/file_replaces_dir", test_file_replaces_dir);
    Test.add_func ("/copy/dir_basic", test_copy_dir);
    Test.add_func ("/copy/nested_chown", test_nested_dirs_chown);
    Test.add_func ("/copy/dir_replaces_file", test_dir_replaces_file);
    Test.add_func ("/copy/src_not_exists", test_src_not_exists);
    Test.add_func ("/copy/user_not_found", test_user_not_found);

    Test.run ();
    return 0;
}
