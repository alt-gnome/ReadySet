/*
 * Copyright (C) 2025 Vladimir Romanov <rirusha@altlinux.org>
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

    public struct ApplyErrorData {
        public string message;
        public string description;
    }

    public errordomain ApplyError {
        BASE,
        NO_PERMISSION;

        public static ApplyError build_error (string message, string description) {
            return new ApplyError.BASE ("%s%s%s".printf (
                message,
                RSS,
                description
            ));
        }

        public static ApplyErrorData to_data (ApplyError error) {
            var parts = error.message.split (RSS, 2);

            if (parts.length == 2) {
                return {
                    message: parts[0],
                    description: parts[1]
                };
            } else {
                return {
                    message: _("Something went wrong"),
                    description: parts[0]
                };
            }
        }
    }

    public delegate void ApplyFunc () throws ApplyError;

    const string RSS = "\n::READY-SET-SEPARATOR::\n";

    public void pkexec (owned string[] cmd, string? user = null) throws Error {
        var launcher = new SubprocessLauncher (NONE);
        var argv = new Gee.ArrayList<string>.wrap ({ "pkexec" });

        if (user != null) {
            argv.add_all_array ({ "--user", user });
        }

        argv.add_all_array (cmd);

        //  pkexec won't let us run the program if $SHELL isn't in /etc/shells,
        //  so remove it from the environment.
        launcher.unsetenv ("SHELL");
        var process = launcher.spawnv (argv.to_array ().copy ());

        process.wait_check ();
    }
}
