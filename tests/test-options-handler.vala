/*
 * Copyright (C) 2025-2026 David Sultaniiazov <x1z53@alt-gnome.ru>
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

const string APP_GROUP = "Application";
const string CTX_GROUP = "Context";

File create_temp_dir () {
    return File.new_for_path (DirUtils.make_tmp ("readyset-conf-XXXXXX"));
}

void write_conf_file (File dir, string name, string contents) {
    try {
        FileUtils.set_contents (dir.get_child (name).get_path (), contents);
    } catch (Error e) {
        Test.fail_printf ("Failed to write %s: %s", name, e.message);
    }
}

KeyFile create_target_keyfile (string main_config) {
    var keyfile = new KeyFile ();
    keyfile.set_list_separator (',');
    try {
        keyfile.load_from_data (main_config, -1, KeyFileFlags.NONE);
    } catch (Error e) {
        Test.fail_printf ("Failed to load initial config: %s", e.message);
    }
    return keyfile;
}

void cleanup_dir (File dir) {
    try {
        var enumerator = dir.enumerate_children (
            FileAttribute.STANDARD_NAME,
            FileQueryInfoFlags.NONE
        );
        FileInfo info;
        while ((info = enumerator.next_file ()) != null) {
            dir.get_child (info.get_name ()).delete ();
        }
        dir.delete ();
    } catch (Error e) {
        Test.fail_printf ("Failed to cleanup: %s", e.message);
    }
}

void assert_string_value (KeyFile keyfile, string key, string expected) {
    string value;
    try {
        value = keyfile.get_string (APP_GROUP, key);
    } catch (Error e) {
        Test.fail_printf ("Key '%s' not found in [%s]: %s", key, APP_GROUP, e.message);
        return;
    }
    if (value != expected) {
        Test.fail_printf ("Expected '%s' = '%s', got '%s'", key, expected, value);
    }
}

void assert_boolean_value (KeyFile keyfile, string key, bool expected) {
    bool value;
    try {
        value = keyfile.get_boolean (APP_GROUP, key);
    } catch (Error e) {
        Test.fail_printf ("Key '%s' not found in [%s]: %s", key, APP_GROUP, e.message);
        return;
    }
    if (value != expected) {
        Test.fail_printf ("Expected '%s' = %s, got %s", key, expected.to_string (), value.to_string ());
    }
}

void assert_string_list_value (KeyFile keyfile, string key, string[] expected) {
    string[] value;
    try {
        value = keyfile.get_string_list (APP_GROUP, key);
    } catch (Error e) {
        Test.fail_printf ("Key '%s' not found in [%s]: %s", key, APP_GROUP, e.message);
        return;
    }
    if (value.length != expected.length) {
        Test.fail_printf ("Expected '%s' length %d, got %d", key, expected.length, value.length);
        return;
    }
    for (int i = 0; i < expected.length; i++) {
        if (value[i] != expected[i]) {
            Test.fail_printf ("Expected '%s'[%d] = '%s', got '%s'", key, i, expected[i], value[i]);
        }
    }
}

void test_merge_not_replace () {
    var dir = create_temp_dir ();
    var keyfile = create_target_keyfile (
        "[Application]\n"
        + "fullscreen=true\n"
        + "sandbox=true\n"
        + "height=1234\n"
    );

    write_conf_file (dir, "a.conf", "[Application]\nfullscreen=false\n");

    try {
        ReadySet.OptionsHandler.load_conf_files_from_dir (dir, keyfile);
    } catch (Error e) {
        Test.fail_printf ("Unexpected error: %s", e.message);
    }

    assert_boolean_value (keyfile, "fullscreen", false);
    assert_boolean_value (keyfile, "sandbox", true);
    assert_string_value (keyfile, "height", "1234");

    cleanup_dir (dir);
}

void test_alphabetical_order () {
    var dir = create_temp_dir ();
    var keyfile = create_target_keyfile ("[Application]\nsteps=language,keyboard\n");

    write_conf_file (dir, "10-first.conf", "[Application]\nsteps=language,keyboard,user-passwdqc\n");
    write_conf_file (dir, "20-second.conf", "[Application]\nsteps=language,user-passwdqc\n");

    try {
        ReadySet.OptionsHandler.load_conf_files_from_dir (dir, keyfile);
    } catch (Error e) {
        Test.fail_printf ("Unexpected error: %s", e.message);
    }

    assert_string_list_value (keyfile, "steps", { "language", "user-passwdqc" });

    cleanup_dir (dir);
}

void test_string_list_merge () {
    var dir = create_temp_dir ();
    var keyfile = create_target_keyfile (
        "[Context]\n"
        + "user.with-root=true\n"
    );

    write_conf_file (dir, "a.conf", "[Context]\nkeyboard.input-sources=xkb::us,xkb::ru\n");

    try {
        ReadySet.OptionsHandler.load_conf_files_from_dir (dir, keyfile);
    } catch (Error e) {
        Test.fail_printf ("Unexpected error: %s", e.message);
    }

    string[] sources;
    try {
        sources = keyfile.get_string_list (CTX_GROUP, "keyboard.input-sources");
    } catch (Error e) {
        Test.fail_printf ("Key 'keyboard.input-sources' not found: %s", e.message);
        return;
    }
    if (sources.length != 2 || sources[0] != "xkb::us" || sources[1] != "xkb::ru") {
        Test.fail_printf ("Expected 'keyboard.input-sources' = [xkb::us][xkb::ru], got [%s][%s]", sources[0], sources[1]);
    }

    cleanup_dir (dir);
}

void test_missing_dir () {
    var keyfile = create_target_keyfile ("[Application]\nfullscreen=true\n");
    var dir = File.new_for_path ("/nonexistent/ready-set-conf-d-test");

    try {
        ReadySet.OptionsHandler.load_conf_files_from_dir (dir, keyfile);
    } catch (Error e) {
        Test.fail_printf ("Unexpected error: %s", e.message);
    }

    assert_boolean_value (keyfile, "fullscreen", true);
}

void test_empty_dir () {
    var dir = create_temp_dir ();
    var keyfile = create_target_keyfile ("[Application]\nfullscreen=true\n");

    try {
        ReadySet.OptionsHandler.load_conf_files_from_dir (dir, keyfile);
    } catch (Error e) {
        Test.fail_printf ("Unexpected error: %s", e.message);
    }

    assert_boolean_value (keyfile, "fullscreen", true);

    cleanup_dir (dir);
}

public static int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/options-handler/load-conf-files-from-dir/merge-not-replace", test_merge_not_replace);
    Test.add_func ("/options-handler/load-conf-files-from-dir/alphabetical-order", test_alphabetical_order);
    Test.add_func ("/options-handler/load-conf-files-from-dir/string-list", test_string_list_merge);
    Test.add_func ("/options-handler/load-conf-files-from-dir/missing-dir", test_missing_dir);
    Test.add_func ("/options-handler/load-conf-files-from-dir/empty-dir", test_empty_dir);

    return Test.run ();
}
