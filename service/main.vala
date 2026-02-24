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

void on_bus_aquired (DBusConnection conn, string name) {
    try {
        var service = new ReadySet.Service ();
        conn.register_object ("/org/altlinux/ReadySet", service);

    } catch (IOError e) {
        ml.quit ();
        error ("Could not register service: %s\n", e.message);
    }
}

MainLoop ml;

int main (string[] args) {
    ml = new MainLoop ();

    Bus.own_name (
        BusType.SYSTEM, "org.altlinux.ReadySet",
        BusNameOwnerFlags.NONE,
        on_bus_aquired,
        (con, name) => {
            print ("Name '%s' acquired. Stopping\n", name);
        },
        (con, name) => {
            print ("Could not acquire name '%s'. Stopping\n", name);
            ml.quit ();
        }
    );

    ml.run ();

    return 0;
}
