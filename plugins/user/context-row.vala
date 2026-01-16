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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/User/ui/context-row.ui")]
public sealed class User.ContextRow : Gtk.Box {

    [GtkChild]
    unowned Gtk.ListBox list_box;

    public Gtk.Widget context { get; set; }

    Gtk.ListBoxRow _row;
    public Gtk.ListBoxRow row {
        get {
            return _row;
        }
        set {
            if (_row != null) {
                list_box.remove (_row);
            }

            list_box.append (value);

            _row = value;
        }
    }

    public bool reveal_context { get; set; default = false; }
}
