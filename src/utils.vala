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

namespace ReadySet {

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

        return "CONTEXT_" + builder.free_and_steal ();
    }

    public delegate Gtk.Widget CreateFunc (PageInfo page);

    public bool in_group (string group_name) {
        unowned Posix.Passwd? passwd = Posix.getpwuid (Posix.getuid ());
        if (passwd == null) {
            return false;
        }

        var groups_n = Linux.getgroups (null);

        Posix.gid_t[] all_group_ids = new Posix.gid_t[groups_n];
        if (Linux.getgroups (all_group_ids) == -1) {
            return false;
        }

        foreach (var gid in all_group_ids) {
            unowned Posix.Group? gr = Posix.getgrgid (gid);
            if (gr.gr_name == group_name) {
                return true;
            }
        }

        return false;
    }
}
