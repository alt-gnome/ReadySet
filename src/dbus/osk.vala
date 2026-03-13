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

    [DBus (name = "sm.puri.OSK0")]
    public interface Osk : Object {

        public abstract bool visible { get; }

        public abstract async void set_visible (bool visible) throws Error;
    }

    Osk osk_proxy;

    public async Osk get_osk_proxy () throws Error {
        if (osk_proxy == null) {
            var con = yield Bus.get (BusType.SESSION);

            if (con == null) {
                error ("Failed to connect to bus");
            }

            osk_proxy = con.get_proxy_sync<Osk> (
                "sm.puri.OSK0",
                "/sm/puri/OSK0",
                DBusProxyFlags.NONE
            );

            //  Ensure
            yield osk_proxy.set_visible (osk_proxy.visible);
        }

        return osk_proxy;
    }
}
