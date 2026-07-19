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

void set_up () {
    try {
        temp_root = DirUtils.make_tmp ("hooks_test_XXXXXX");
    } catch (Error e) {
        critical ("Failed to set up test: %s", e.message);
    }
}

void create_executable_script (string path, string content) throws Error {
    FileUtils.set_contents (path, content);
    Posix.chmod (path, 0755);
}

void create_non_executable_file (string path, string content) throws Error {
    FileUtils.set_contents (path, content);
    Posix.chmod (path, 0644);
}

void test_exec_hooks_empty_dir () {
    try {
        var hooks_dir = Path.build_filename (temp_root, "empty_hooks");
        DirUtils.create_with_parents (hooks_dir, 0755);

        string[] env = { "TEST=value" };
        var res = ReadySet.get_all_hooks_from_dir (File.new_for_path (hooks_dir)).length;
        if (res != 0) {
            Test.fail_printf ("Expected 0, got %i", res);
        }
    } catch (Error e) {
        Test.fail_printf ("Expected get_all_hooks_from_dir to succeed with empty dir, got error: %s", e.message);
    }
}

void test_exec_hooks_nonexistent_dir () {
    try {
        var hooks_dir = Path.build_filename (temp_root, "nonexistent");
        string[] env = { "TEST=value" };
        ReadySet.get_all_hooks_from_dir (File.new_for_path (hooks_dir));
        Test.fail_printf ("Expected get_all_hooks_from_dir to throw error for nonexistent dir");
    } catch (Error e) {
        // Expected - directory doesn't exist
    }
}

void test_exec_hook_script () {
    try {
        var hooks_dir = Path.build_filename (temp_root, "single_hook");
        DirUtils.create_with_parents (hooks_dir, 0755);

        var marker_file = Path.build_filename (temp_root, "marker_single");
        var script_path = Path.build_filename (hooks_dir, "01-test.sh");
        create_executable_script (script_path, "#!/bin/sh\ntouch " + marker_file);

        string[] env = { "TEST=value" };
        ReadySet.real_exec_hook_from_dir (File.new_for_path (hooks_dir), "01-test.sh", env);

        var marker = File.new_for_path (marker_file);
        if (!marker.query_exists ()) {
            Test.fail_printf ("Expected hook script to be executed and create marker file");
        }
    } catch (Error e) {
        Test.fail_printf ("Expected exec_hooks to succeed, got error: %s", e.message);
    }
}

void test_exec_hooks_multiple_scripts () {
    try {
        var hooks_dir = Path.build_filename (temp_root, "multi_hooks");
        DirUtils.create_with_parents (hooks_dir, 0755);

        var marker1 = Path.build_filename (temp_root, "marker1");
        var marker2 = Path.build_filename (temp_root, "marker2");
        var marker3 = Path.build_filename (temp_root, "marker3");

        create_executable_script (
            Path.build_filename (hooks_dir, "01-first.sh"),
            "#!/bin/sh\ntouch " + marker1
        );
        create_executable_script (
            Path.build_filename (hooks_dir, "02-second.sh"),
            "#!/bin/sh\ntouch " + marker2
        );
        create_executable_script (
            Path.build_filename (hooks_dir, "03-third.sh"),
            "#!/bin/sh\ntouch " + marker3
        );

        var f = File.new_for_path (hooks_dir);

        string[] env = { "TEST=value" };
        foreach (var name in ReadySet.get_all_hooks_from_dir (f)) {
            ReadySet.real_exec_hook_from_dir (f, name, env);
        }

        if (!File.new_for_path (marker1).query_exists ()) {
            Test.fail_printf ("Expected first hook to be executed");
        }
        if (!File.new_for_path (marker2).query_exists ()) {
            Test.fail_printf ("Expected second hook to be executed");
        }
        if (!File.new_for_path (marker3).query_exists ()) {
            Test.fail_printf ("Expected third hook to be executed");
        }
    } catch (Error e) {
        Test.fail_printf ("Expected exec_hooks to succeed, got error: %s", e.message);
    }
}

void test_exec_hooks_skips_non_executable () {
    try {
        var hooks_dir = Path.build_filename (temp_root, "non_exec_hooks");
        DirUtils.create_with_parents (hooks_dir, 0755);

        var marker_exec = Path.build_filename (temp_root, "marker_exec");
        var marker_non_exec = Path.build_filename (temp_root, "marker_non_exec");

        create_executable_script (
            Path.build_filename (hooks_dir, "01-executable.sh"),
            "#!/bin/sh\ntouch " + marker_exec
        );
        create_non_executable_file (
            Path.build_filename (hooks_dir, "02-non-executable.sh"),
            "#!/bin/sh\ntouch " + marker_non_exec
        );

        var f = File.new_for_path (hooks_dir);

        string[] env = { "TEST=value" };
        foreach (var name in ReadySet.get_all_hooks_from_dir (f)) {
            ReadySet.real_exec_hook_from_dir (f, name, env);
        }

        if (!File.new_for_path (marker_exec).query_exists ()) {
            Test.fail_printf ("Expected executable hook to be executed");
        }
        if (File.new_for_path (marker_non_exec).query_exists ()) {
            Test.fail_printf ("Expected non-executable file to be skipped");
        }
    } catch (Error e) {
        Test.fail_printf ("Expected exec_hooks to succeed, got error: %s", e.message);
    }
}

void test_exec_hooks_skips_directories () {
    try {
        var hooks_dir = Path.build_filename (temp_root, "dir_hooks");
        DirUtils.create_with_parents (hooks_dir, 0755);

        var marker_file = Path.build_filename (temp_root, "marker_file");
        var sub_dir = Path.build_filename (hooks_dir, "01-subdir.sh");
        DirUtils.create_with_parents (sub_dir, 0755);

        create_executable_script (
            Path.build_filename (hooks_dir, "02-real-script.sh"),
            "#!/bin/sh\ntouch " + marker_file
        );

        var f = File.new_for_path (hooks_dir);

        string[] env = { "TEST=value" };
        foreach (var name in ReadySet.get_all_hooks_from_dir (f)) {
            ReadySet.real_exec_hook_from_dir (f, name, env);
        }

        if (!File.new_for_path (marker_file).query_exists ()) {
            Test.fail_printf ("Expected real script to be executed, directory should be skipped");
        }
    } catch (Error e) {
        Test.fail_printf ("Expected exec_hooks to succeed, got error: %s", e.message);
    }
}

void test_exec_hooks_with_env_vars () {
    try {
        var hooks_dir = Path.build_filename (temp_root, "env_hooks");
        DirUtils.create_with_parents (hooks_dir, 0755);

        var output_file = Path.build_filename (temp_root, "env_output");
        var script_path = Path.build_filename (hooks_dir, "01-env.sh");
        var script_content = "#!/bin/sh\necho \"$READY_SET_VAR1 $READY_SET_VAR2\" > " + output_file;
        create_executable_script (script_path, script_content);

        var f = File.new_for_path (hooks_dir);

        string[] env = { "VAR1=hello", "VAR2=world" };
        foreach (var name in ReadySet.get_all_hooks_from_dir (f)) {
            ReadySet.real_exec_hook_from_dir (f, name, env);
        }

        string content;
        FileUtils.get_contents (output_file, out content);
        content = content.strip ();
        if (content != "hello world") {
            Test.fail_printf ("Expected 'hello world' in output, got '%s'", content);
        }
    } catch (Error e) {
        Test.fail_printf ("Expected exec_hooks to succeed, got error: %s", e.message);
    }
}

public static int main (string[] args) {
    Test.init (ref args);

    set_up ();

    Test.add_func ("/hooks/empty-dir", test_exec_hooks_empty_dir);
    Test.add_func ("/hooks/nonexistent-dir", test_exec_hooks_nonexistent_dir);
    Test.add_func ("/hooks/single-script", test_exec_hook_script);
    Test.add_func ("/hooks/multiple-scripts", test_exec_hooks_multiple_scripts);
    Test.add_func ("/hooks/skips-non-executable", test_exec_hooks_skips_non_executable);
    Test.add_func ("/hooks/skips-directories", test_exec_hooks_skips_directories);
    Test.add_func ("/hooks/with-env-vars", test_exec_hooks_with_env_vars);

    return Test.run ();
}
