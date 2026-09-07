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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Keyboard/ui/page.ui")]
public sealed class Keyboard.Page : ReadySet.BasePage, ReadySet.HasStringRepr {

    [GtkChild]
    unowned Adw.Banner select_at_least_one_banner;
    [GtkChild]
    unowned Gtk.ListBox switch_box;
    [GtkChild]
    unowned LayoutSwitchRow switch_row;

    bool has_hw_keybaord = try_to_detect_hw_keyboatd ();

    construct {
        Addin.get_instance ().context.data_changed.connect (on_context_data_changed);
        update_is_ready ();

        Addin.get_instance ().is_manager.init.begin ();

        if (!Addin.get_instance ().context.sandbox) {
            BindingFlags flags = BIDIRECTIONAL;

            if (Addin.get_instance ().context.get_string ("keyboard.additinal-layout-grp") != "") {
                flags |= SYNC_CREATE;
            }

            Addin.get_instance ().context.bind_context_to_property (
                "keyboard.additinal-layout-grp",
                switch_row,
                "selected-grp",
                flags
            );
        }
    }

    async void on_context_data_changed (string key) {
        if (key == "keyboard.input-sources") {
            update_is_ready ();
            update_has_hw ();
        }
    }

    void update_is_ready () {
        bool has_latin_is = false;
        foreach (var i in get_current_inputs ().to_array ()) {
            if (i.is_latin ()) {
                has_latin_is = true;
                break;
            }
        }
        is_ready = has_latin_is;
        select_at_least_one_banner.revealed = !has_latin_is;
    }

    void update_has_hw () {
        var current_inputs = get_current_inputs ();

        switch_box.visible = current_inputs.size > 1 && has_hw_keybaord;
    }

    public string get_string_repr () {
        var inputs = get_current_inputs ();

        string[] simple_inputs = {};
        foreach (var i in inputs.to_array ()) {
            simple_inputs += i.id;
        }
        return string.joinv (", ", simple_inputs);
    }
}
