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
        temp_root = DirUtils.make_tmp ("env_exec_test_XXXXXX");
    } catch (Error e) {
        critical ("Failed to create temp dir: %s", e.message);
    }
}

void test_env_exec_success () {
    try {
        string[] env = { "TEST_VAR=hello" };
        bool result = ReadySet.env_exec ("/bin/sh", env);
        if (!result) {
            Test.fail_printf ("Expected env_exec to return true for successful command");
        }
    } catch (Error e) {
        Test.fail_printf ("Expected env_exec to succeed, got error: %s", e.message);
    }
}

void test_env_exec_with_multiple_vars () {
    try {
        string[] env = { "VAR1=value1", "VAR2=value2", "VAR3=value3" };
        bool result = ReadySet.env_exec ("/bin/true", env);
        if (!result) {
            Test.fail_printf ("Expected env_exec to return true with multiple env vars");
        }
    } catch (Error e) {
        Test.fail_printf ("Expected env_exec to succeed with multiple vars, got error: %s", e.message);
    }
}

void test_env_exec_empty_env () {
    try {
        string[] env = {};
        bool result = ReadySet.env_exec ("/bin/true", env);
        if (!result) {
            Test.fail_printf ("Expected env_exec to return true with empty env");
        }
    } catch (Error e) {
        Test.fail_printf ("Expected env_exec to succeed with empty env, got error: %s", e.message);
    }
}

void test_env_exec_nonexistent_program () {
    try {
        string[] env = { "TEST=value" };
        ReadySet.env_exec ("/nonexistent/program/xyz", env);
        Test.fail_printf ("Expected env_exec to throw error for nonexistent program");
    } catch (Error e) {
        // Expected - program doesn't exist
    }
}

void test_env_exec_failing_command () {
    try {
        string[] env = { "TEST=value" };
        bool result = ReadySet.env_exec ("/bin/false", env);
        if (result) {
            Test.fail_printf ("Expected env_exec to return false for failing command");
        }
    } catch (Error e) {
        // Some systems may throw error instead of returning false
    }
}

void test_env_exec_with_equals_in_value () {
    try {
        string[] env = { "TEST_VAR=value=with=equals" };
        bool result = ReadySet.env_exec ("/bin/true", env);
        if (!result) {
            Test.fail_printf ("Expected env_exec to handle equals in value");
        }
    } catch (Error e) {
        Test.fail_printf ("Expected env_exec to succeed with equals in value, got error: %s", e.message);
    }
}

public static int main (string[] args) {
    Test.init (ref args);

    set_up ();

    Test.add_func ("/env-exec/success", test_env_exec_success);
    Test.add_func ("/env-exec/multiple-vars", test_env_exec_with_multiple_vars);
    Test.add_func ("/env-exec/empty-env", test_env_exec_empty_env);
    Test.add_func ("/env-exec/nonexistent-program", test_env_exec_nonexistent_program);
    Test.add_func ("/env-exec/failing-command", test_env_exec_failing_command);
    Test.add_func ("/env-exec/equals-in-value", test_env_exec_with_equals_in_value);

    return Test.run ();
}
