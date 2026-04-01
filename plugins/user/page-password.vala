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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/User/ui/page-password.ui")]
public class User.PagePassword : ReadySet.BasePage {

    [GtkChild]
    unowned ContextRow password_context_row;
    [GtkChild]
    unowned Adw.PasswordEntryRow password_entry;
    [GtkChild]
    unowned PasswordStrength password_strength;
    [GtkChild]
    unowned ContextRow password_repeat_context_row;
    [GtkChild]
    unowned Adw.PasswordEntryRow password_repeat_entry;
    [GtkChild]
    unowned Adw.SwitchRow autologin_switch_row;
    [GtkChild]
    unowned Gtk.ListBox autologin_list_box;

    construct {
        Addin.get_instance ().context.bind_context_to_property (
            "user-password",
            password_entry,
            "text",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE
        );

        Addin.get_instance ().context.bind_context_to_property (
            "user-autologin",
            autologin_switch_row,
            "active",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE
        );

        Addin.get_instance ().context.bind_context_to_property (
            "hide-autologin",
            autologin_list_box,
            "visible",
            BindingFlags.INVERT_BOOLEAN | BindingFlags.SYNC_CREATE
        );

        Addin.get_instance ().context.data_changed.connect (on_context_data_changed);

        update_is_ready ();
    }

    void on_context_data_changed (string key) {
        if (key == "hide-autologin") {
            if (Addin.get_instance ().context.get_boolean ("hide-autologin")) {
                autologin_switch_row.active = false;
            }
        }
    }

    void update_is_ready () {
        is_ready = password_is_ready (password_entry.text) &&
                   password_entry.text == password_repeat_entry.text;
    }

    [GtkCallback]
    void password_changed () {
        var strength = get_password_strength (
            password_entry.text,
            null,
            Addin.get_instance ().context.get_string ("user-username")
        );

        password_strength.strength_level = strength.level;
        password_strength.strength = strength.value;
        password_strength.label = strength.hint;
        update_css_by_strength (password_entry, strength.level);
        password_strength.progress_bar_visible = strength.support_value;
        password_context_row.reveal_context = strength.level != GOOD;

        password_repeat_changed ();
    }

    [GtkCallback]
    void password_repeat_changed () {
        var is_correct = password_entry.text == password_repeat_entry.text;
        password_repeat_context_row.reveal_context = !is_correct;
        update_correct (password_repeat_entry, is_correct);

        update_is_ready ();
    }

    [GtkCallback]
    void generate_user_password () {
        var password = Password.generate ();

        password_entry.text = password;
    }
}
