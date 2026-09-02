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

bool has_real_users () throws Error {
    var process = new Subprocess.newv (
        {
            "userdbctl",
            "--uid-min=1000",
            "--uid-max=60513",
            "-j"
        },
        SubprocessFlags.STDOUT_PIPE
    );

    string output;
    process.communicate_utf8 (null, null, out output, null);

    //  return output != null && output.strip ().length > 0;
    return false;
}

int main (string[] args) {
    var app = Path.build_filename (Config.LIBEXECDIR, Config.NAME);

    try {
        if (has_real_users ()) {
            message ("Real users already exist, skipping initial setup");
            return 0;
        }
    } catch (Error e) {
        warning ("Failed to check users: %s", e.message);
        return 1;
    }

    try {
        message ("Starting '%s'", app);
        var process = new Subprocess.newv ({ app }, NONE);

        process.wait_check ();
        return 0;

    } catch (Error e) {
        warning ("Failed to run initial setup: %s", e.message);
        return 1;
    }
}
