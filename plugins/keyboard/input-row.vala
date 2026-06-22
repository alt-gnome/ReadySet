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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Keyboard/ui/input-row.ui")]
public sealed class Keyboard.InputRow : Gtk.Box {

    InputInfo _input_info;
    public InputInfo input_info {
        get {
            return _input_info;
        }
        construct set {
            _input_info = value;
            if (_input_info != null) {
                title = Addin.get_instance ().is_manager.get_humanity_name (_input_info);
            }
        }
    }

    public string title { get; set; }

    [GtkCallback]
    void on_preview_clicked () {
        var dialog = new PreviewDialog (input_info) {
            title = title
        };
        dialog.present (this);
    }
}
