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

namespace ReadySet {

    [DBus (name = "org.altlinux.ReadySet")]
    public interface Service : Object {

        public abstract void generate_rules (
            string user = "ready-set"
        ) throws Error;

        public abstract void clear_rules () throws Error;

        public abstract void exec_pre_hooks (
            string[] env = {}
        ) throws Error;

        public abstract void exec_post_hooks (
            string[] env = {}
        ) throws Error;
    }

    Service proxy;

    public Service get_ready_set_proxy () throws Error {
        if (proxy == null) {
            var con = Bus.get_sync (BusType.SYSTEM);

            if (con == null) {
                error ("Failed to connect to bus");
            }

            proxy = con.get_proxy_sync<Service> (
                "org.altlinux.ReadySet",
                "/org/altlinux/ReadySet",
                DBusProxyFlags.NONE
            );
        }

        return proxy;
    }

    public string context_key_to_env_key (string key) {
        var builder = new StringBuilder ();

        int next_index = 0;
        unichar c;

        while (key.get_next_char (ref next_index, out c)) {
            if (c == '-') {
                builder.append_unichar ('_');
            } else {
                builder.append_unichar (c.toupper ());
            }
        }

        return "CONTEXT_%s" + builder.free_and_steal ();
    }

    public const string STEP_ID_LABEL = "step-id";

    public delegate Gtk.Widget CreateFunc (PageInfo page);

    public struct StackPageInfo {
        public string name;
        public string title;
        public Gtk.Widget widget;
    }
}
