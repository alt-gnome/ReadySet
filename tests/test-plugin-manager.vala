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

void test_blank_init () {
    var ctx = new ReadySet.Context (true);
    var manager = new ReadySet.PluginManager (ctx);

    manager.blank_init ();
    var steps = manager.get_available_steps ();
    var installers = manager.get_available_installers ();

    if (steps.length != 2) {
        Test.fail_printf ("Expected 2 step, got %d", steps.length);
    }
    if (!("tests" in steps)) {
        Test.fail_printf ("Expected 'tests' in steps");
    }
    if (!("installer.disks" in steps)) {
        Test.fail_printf ("Expected 'installer.disks' in steps");
    }

    if (installers.length != 1) {
        Test.fail_printf ("Expected 1 installer, got %d", installers.length);
    }
    if (!("test-installer" in installers)) {
        Test.fail_printf ("Expected 'test-installer' in installers");
    }
}

void test_installer_only_steps () {
    var ctx = new ReadySet.Context (true);
    var manager = new ReadySet.PluginManager (ctx);
    string[] steps = { "installer.disks" };

    manager.init ("test-installer", steps);
    assert (manager.get_step_addin ("tests") == null);
    assert (manager.has_step ("installer.disks"));

    manager.check_steps (steps);
    manager.check_installers ();

    assert (manager.steps.length == 1);
    assert (manager.steps[0] == "installer.disks");
    assert (manager.get_installer_plugin ().context == ctx);
}

public static int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/plugin-manager/blank-init", test_blank_init);
    Test.add_func ("/plugin-manager/installer-only-steps", test_installer_only_steps);

    return Test.run ();
}
