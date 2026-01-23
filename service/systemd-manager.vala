/*
 * Copyright (C) 2026 Vladimir Romanov <rirusha@altlinux.org>
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
    [DBus (name = "org.freedesktop.systemd1.Manager")]
    public interface SystemDManager : Object {
        public abstract Variant reload_unit (
            string name,
            string mode
        ) throws Error;
    }

    SystemDManager proxy;

    public SystemDManager get_systemd_proxy () throws Error {
        if (proxy == null) {
            var con = Bus.get_sync (BusType.SYSTEM);

            if (con == null) {
                error ("Failed to connect to bus");
            }

            proxy = con.get_proxy_sync<SystemDManager> (
                "org.freedesktop.systemd1",
                "/org/freedesktop/systemd1",
                DBusProxyFlags.NONE
            );
        }

        return proxy;
    }
}
