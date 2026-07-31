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

[DBus (name = "org.altlinux.ReadySet.UserRoot")]
public sealed class UserRoot.Service : Object {

    public void set_root_password (string password, BusName sender) throws Error {
        //  echo "root:$1" | /usr/sbin/chpasswd
        var sp = new Subprocess.newv ({ "echo", "password set" }, NONE);
        sp.wait ();
    }
}

public sealed class UserRoot.Addin : ReadySetService.Addin {

    public override string get_object_path () {
        return "/UserRoot";
    }

    public override void register_service (DBusConnection conn, string path) throws GLib.IOError {
        conn.register_object (path, new UserRoot.Service ());
    }
}

public void peas_register_types (TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type (typeof (ReadySetService.Addin), typeof (UserRoot.Addin));
}
