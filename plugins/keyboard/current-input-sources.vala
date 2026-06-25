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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Keyboard/ui/current-input-sources.ui")]
public sealed class Keyboard.CurrentInputSources : Gtk.Box {

    [GtkChild]
    unowned Gtk.Stack current_input_list_stack;
    [GtkChild]
    unowned Gtk.ListBox current_input_list;

    static construct {
        typeof (LayoutSwitchRow).ensure ();
    }

    construct {
        Addin.get_instance ().context.data_changed.connect (on_context_data_changed);
        update_current ();
    }

    void on_context_data_changed (string key) {
        if (key == "keyboard-input-sources") {
            update_current ();
        }
    }

    void update_current () {
        current_input_list.remove_all ();

        var current_inputs = get_current_inputs ();

        if (current_inputs.size == 0) {
            current_input_list_stack.visible_child_name = "nothing-selected";
        } else {
            current_input_list_stack.visible_child_name = "sources";
        }

        foreach (var info in current_inputs.to_array ()) {
            current_input_list.append (new CurrentInputRow (info));
        }
    }

    [GtkCallback]
    void row_activated (Gtk.ListBox list_box, Gtk.ListBoxRow row) {
        if (row == null) {
            return;
        }

        var inputs = get_current_inputs ();

        var input_row = (CurrentInputRow) row;
        inputs.remove (input_row.input_info);

        set_current_inputs (inputs);
    }

    [GtkCallback]
    void on_buttonrow_activated () {
        new InputSourcesDialog ().present (this);
    }
}
