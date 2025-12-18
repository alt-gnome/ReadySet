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

[GtkTemplate (ui = "/org/altlinux/ReadySet/ui/user-page.ui")]
public class ReadySet.UserPage : BasePage {

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

    construct {
        var data = Data.get_instance ();

        data.user.bind_property (
            "fullname",
            fullname_entry,
            "text",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE
        );
        data.user.bind_property (
            "username",
            username_entry,
            "text",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE
        );
        data.user.bind_property (
            "password",
            password_entry,
            "text",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE
        );
        data.user.bind_property (
            "repeat-password",
            password_repeat_entry,
            "text",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE
        );
        data.user.bind_property (
            "root-password",
            root_password_entry,
            "text",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE
        );
        data.user.bind_property (
            "repeat-root-password",
            root_password_repeat_entry,
            "text",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE
        );
    }

    void update_is_ready () {
        var data = Data.get_instance ();

        is_ready = fullname_is_correct (data.user.fullname, null) &&
                   username_is_correct (data.user.username, false, null) &&
                   password_is_correct (data.user.password) &&
                   data.user.password == data.user.repeat_password &&
                   (data.user.equal_to_root || (!data.user.equal_to_root &&
                   (password_is_correct (data.user.root_password) &&
                   data.user.root_password == data.user.repeat_root_password)));
    }

    public override async void apply () throws ApplyError {
        var data = Data.get_instance ();

        try {
            var user = yield Act.UserManager.get_default ().create_user_async (
                data.user.username,
                data.user.fullname,
                Act.UserAccountType.ADMINISTRATOR,
                null
            );

            user.set_password (data.user.password, "");
            user.set_language (get_current_language ());

            set_root_password (data.user.equal_to_root ? data.user.password : data.user.root_password);

        } catch (Error e) {
            throw ApplyError.build_error (_("Error when creating a user"), e.message);
        }
    }

    string get_auto_username () {
        var data = Data.get_instance ();

        return correct_username (data.user.fullname);
    }

    void auto_enter_username () {
        var data = Data.get_instance ();

        data.user.username = get_auto_username ();
    }

    [GtkCallback]
    void fullname_changed () {
        var data = Data.get_instance ();

        if (!username_manually_entered) {
            auto_enter_username ();
        }

        string error;
        var is_correct = fullname_is_correct (data.user.fullname, out error);
        fullname_context_row.reveal_context = !is_correct;
        fullname_label.label = error;
        fullname_context_row.reveal_context = !is_correct && error != "";
        update_correct (fullname_entry, is_correct);

        update_is_ready ();
    }

    [GtkCallback]
    void username_changed () {
        var data = Data.get_instance ();

        username_manually_entered = username_entry.text != get_auto_username ();

        if (!username_manually_entered && data.user.username == "") {
            return;
        }

        string error;
        var is_correct = username_is_correct (data.user.username, false, out error);
        username_label.label = error;
        username_context_row.reveal_context = !is_correct && error != "";
        update_correct (username_entry, is_correct);

        update_is_ready ();
    }

    [GtkCallback]
    void password_changed () {
        var data = Data.get_instance ();

        string hint;
        StrengthLevel strength_level;

        double strength = pw_strength (
            data.user.password,
            null,
            data.user.username,
            out hint,
            out strength_level
        );

        password_strength.strength_level = strength_level;
        password_strength.strength = strength;
        password_strength.label = hint;
        update_css_by_strength (password_entry, strength_level);
        password_context_row.reveal_context = strength_level != GOOD;

        password_repeat_changed ();
        update_is_ready ();
    }

    [GtkCallback]
    void password_repeat_changed () {
        var data = Data.get_instance ();

        var is_correct = data.user.password == data.user.repeat_password;
        password_repeat_context_row.reveal_context = !is_correct;
        update_correct (password_repeat_entry, is_correct);

        update_is_ready ();
    }

    [GtkCallback]
    void root_password_changed () {
        var data = Data.get_instance ();

        string hint;
        StrengthLevel strength_level;

        double strength = pw_strength (
            data.user.root_password,
            null,
            data.user.username,
            out hint,
            out strength_level
        );

        root_password_strength.strength_level = strength_level;
        root_password_strength.strength = strength;
        root_password_strength.label = hint;
        update_css_by_strength (root_password_entry, strength_level);
        root_password_context_row.reveal_context = strength_level != GOOD;

        root_password_repeat_changed ();
        update_is_ready ();
    }

    [GtkCallback]
    void root_password_repeat_changed () {
        var data = Data.get_instance ();

        var is_correct = data.user.root_password == data.user.repeat_root_password;
        root_password_repeat_context_row.reveal_context = !is_correct;
        update_correct (root_password_repeat_entry, is_correct);

        update_is_ready ();
    }

    [GtkCallback]
    void switch_changed () {
        var data = Data.get_instance ();

        data.user.equal_to_root = !equal_switch_row.active;
        data.user.root_password = "";
        data.user.repeat_root_password = "";

        root_password_entry.remove_css_class ("error");
        root_password_context_row.reveal_context = false;
        root_password_repeat_entry.remove_css_class ("error");
        root_password_repeat_context_row.reveal_context = false;

        update_is_ready ();
    }

    [GtkCallback]
    void generate_user_password () {
        var password = pw_generate ();

        var data = Data.get_instance ();
        data.user.password = password;
    }

    [GtkCallback]
    void generate_root_password () {
        var password = pw_generate ();

        var data = Data.get_instance ();
        data.user.root_password = password;
    }
}
