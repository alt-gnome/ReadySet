/*
 * Copyright (C) 2026 Valery Zabrovsky <brow@altlinux.org>
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

[CCode (cprefix = "Net", lower_case_cprefix = "net_")]
namespace Net {
    [CCode (cheader_filename = "net-connection-editor.h", type_id = "net_connection_editor_get_type ()")]
    public class ConnectionEditor : Adw.Window, Gtk.Accessible, Gtk.Buildable, Gtk.ConstraintTarget, Gtk.Native, Gtk.Root, Gtk.ShortcutManager {
        [CCode (has_construct_function = false)]
        public ConnectionEditor (NM.Connection? connection, NM.Device? device, NM.AccessPoint? ap, NM.Client client);
        public void forget ();
        public void set_title (string title);
        public signal void done (bool object);
    }
}
