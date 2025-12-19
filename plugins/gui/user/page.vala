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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/User/ui/page.ui")]
public class User.Page : ReadySet.BasePage {

    [GtkChild]
    unowned ContextRow fullname_context_row;
    [GtkChild]
    unowned MarginLabel fullname_label;
    [GtkChild]
    unowned Adw.EntryRow fullname_entry;
    [GtkChild]
    unowned ContextRow username_context_row;
    [GtkChild]
    unowned MarginLabel username_label;
    [GtkChild]
    unowned Adw.EntryRow username_entry;
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
    unowned Gtk.Switch equal_switch_row;
    [GtkChild]
    unowned ContextRow root_password_context_row;
    [GtkChild]
    unowned Adw.PasswordEntryRow root_password_entry;
    [GtkChild]
    unowned PasswordStrength root_password_strength;
    [GtkChild]
    unowned ContextRow root_password_repeat_context_row;
    [GtkChild]
    unowned Adw.PasswordEntryRow root_password_repeat_entry;

    public bool with_root_password { get; construct set; default = false; }

    bool username_manually_entered = false;

    void update_is_ready () {
        is_ready = fullname_is_correct (fullname_entry.text, null) &&
                   username_is_correct (username_entry.text, false, null) &&
                   password_is_correct (password_entry.text) &&
                   password_entry.text == password_repeat_entry.text &&
                   (equal_switch_row.active || (!equal_switch_row.active &&
                   (password_is_correct (root_password_entry.text) &&
                   root_password_entry.text == root_password_repeat_entry.text)));
    }

    public override async void apply () throws ReadySet.ApplyError {
        try {
            var user = yield Act.UserManager.get_default ().create_user_async (
                username_entry.text,
                fullname_entry.text,
                Act.UserAccountType.ADMINISTRATOR,
                null
            );

            user.set_password (password_entry.text, "");
            user.set_language (get_current_language ());

            set_root_password (equal_switch_row.active ? password_entry.text : root_password_entry.text);

        } catch (Error e) {
            throw ReadySet.ApplyError.build_error (_("Error when creating a user"), e.message);
        }
    }

    string get_auto_username () {
        return correct_username (fullname_entry.text);
    }

    void auto_enter_username () {
        username_entry.text = get_auto_username ();
    }

    [GtkCallback]
    void fullname_changed () {
        if (!username_manually_entered) {
            auto_enter_username ();
        }

        string error;
        var is_correct = fullname_is_correct (fullname_entry.text, out error);
        fullname_context_row.reveal_context = !is_correct;
        fullname_label.label = error;
        fullname_context_row.reveal_context = !is_correct && error != "";
        update_correct (fullname_entry, is_correct);

        update_is_ready ();
    }

    [GtkCallback]
    void username_changed () {
        username_manually_entered = username_entry.text != get_auto_username ();

        if (!username_manually_entered && username_entry.text == "") {
            return;
        }

        string error;
        var is_correct = username_is_correct (username_entry.text, false, out error);
        username_label.label = error;
        username_context_row.reveal_context = !is_correct && error != "";
        update_correct (username_entry, is_correct);

        update_is_ready ();
    }

    [GtkCallback]
    void password_changed () {
        var strength = Password.strength (
            password_entry.text,
            null,
            username_entry.text
        );

        password_strength.strength_level = strength.level;
        password_strength.strength = strength.value;
        password_strength.label = strength.hint;
        update_css_by_strength (password_entry, strength.level);
        password_strength.progress_bar_visible = strength.support_value;
        password_context_row.reveal_context = strength.level != GOOD;

        password_repeat_changed ();
        update_is_ready ();
    }

    [GtkCallback]
    void password_repeat_changed () {
        var is_correct = password_entry.text == password_repeat_entry.text;
        password_repeat_context_row.reveal_context = !is_correct;
        update_correct (password_repeat_entry, is_correct);

        update_is_ready ();
    }

    [GtkCallback]
    void root_password_changed () {
        var strength = Password.strength (
            root_password_entry.text,
            null,
            username_entry.text
        );

        root_password_strength.strength_level = strength.level;
        root_password_strength.strength = strength.value;
        root_password_strength.label = strength.hint;
        update_css_by_strength (root_password_entry, strength.level);
        root_password_strength.progress_bar_visible = strength.support_value;
        root_password_context_row.reveal_context = strength.level != GOOD;

        root_password_repeat_changed ();
        update_is_ready ();
    }

    [GtkCallback]
    void root_password_repeat_changed () {
        var is_correct = root_password_entry.text == root_password_repeat_entry.text;
        root_password_repeat_context_row.reveal_context = !is_correct;
        update_correct (root_password_repeat_entry, is_correct);

        update_is_ready ();
    }

    [GtkCallback]
    void switch_changed () {
        equal_switch_row.active = !equal_switch_row.active;
        root_password_entry.text = "";
        root_password_repeat_entry.text = "";

        root_password_entry.remove_css_class ("error");
        root_password_context_row.reveal_context = false;
        root_password_repeat_entry.remove_css_class ("error");
        root_password_repeat_context_row.reveal_context = false;

        update_is_ready ();
    }

    [GtkCallback]
    void generate_user_password () {
        var password = Password.generate ();

        password_entry.text = password;
    }

    [GtkCallback]
    void generate_root_password () {
        var password = Password.generate ();

        root_password_entry.text = password;
    }
}
