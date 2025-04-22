/*
 * Copyright (C) 2025 Vladimir Vaskov <rirusha@altlinux.org>
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

[GtkTemplate (ui = "/space/rirusha/ReadySet/ui/user-page.ui")]
public sealed class ReadySet.UserPage : BasePage {

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
    unowned Adw.SwitchRow equal_switch_row;
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

    static string fullname;
    static string username;
    static string password;
    static string root_password;

    void update_is_ready () {
        fullname = fullname_entry.text;
        username = username_entry.text;
        password = password_entry.text;
        root_password = root_password_entry.text;

        is_ready = fullname_is_correct (fullname, null)
                   && username_is_correct (username, false, null)
                   && password_is_correct (password)
                   && password == password_repeat_entry.text
                   && (equal_switch_row.active || (!equal_switch_row.active && (password_is_correct (root_password)
                   && root_password == root_password_repeat_entry.text)));
    }

    protected override void apply () throws ApplyError {
        try {
            var user = Act.UserManager.get_default ().create_user (
                username,
                fullname,
                Act.UserAccountType.STANDARD
            );

            user.set_password (password, "");
            user.set_language (get_current_language ());

            set_root_password (root_password != "" ? root_password : password);

        } catch (Error e) {
            throw new ApplyError.BASE (_("Failed to create user"));
        }
    }

    [GtkCallback]
    void fullname_changed () {
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
        string error;
        var is_correct = username_is_correct (username_entry.text, false, out error);
        username_label.label = error;
        username_context_row.reveal_context = !is_correct && error != "";
        update_correct (username_entry, is_correct);

        update_is_ready ();
    }

    [GtkCallback]
    void password_changed () {
        string hint;
        int strength_level;

        double strength = pw_strength (
            password_entry.text,
            null,
            username_entry.text,
            out hint,
            out strength_level
        );

        password_strength.strength_level = strength_level;
        password_strength.strength = strength;
        password_strength.label = hint;
        update_css_by_strength (password_entry, strength_level);
        password_context_row.reveal_context = strength_level < 5;

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
        string hint;
        int strength_level;

        double strength = pw_strength (
            root_password_entry.text,
            null,
            username_entry.text,
            out hint,
            out strength_level
        );

        root_password_strength.strength_level = strength_level;
        root_password_strength.strength = strength;
        root_password_strength.label = hint;
        update_css_by_strength (root_password_entry, strength_level);
        root_password_context_row.reveal_context = strength_level < 5;

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
        if (equal_switch_row.active) {
            root_password_entry.text = "";
            root_password_repeat_entry.text = "";

            root_password_entry.remove_css_class ("error");
            root_password_context_row.reveal_context = false;
            root_password_repeat_entry.remove_css_class ("error");
            root_password_repeat_context_row.reveal_context = false;

        }

        update_is_ready ();
    }
}
