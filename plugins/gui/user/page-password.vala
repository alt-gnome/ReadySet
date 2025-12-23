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
    unowned Gtk.Switch equal_switch_row;
    [GtkChild]
    unowned Adw.SwitchRow autologin_switch_row;
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

    construct {
        var password = Addin.get_instance ().context.get_string ("user-password");
        var root_password = Addin.get_instance ().context.get_string ("user-root-password");

        if (password != null) {
            password_entry.text = password;
        }
        if (root_password != null) {
            root_password_entry.text = root_password;
        }
        autologin_switch_row.active = Addin.get_instance ().context.get_boolean ("user-autologin");
    }

    void update_is_ready () {
        is_ready = password_is_ready (password_entry.text) &&
                   password_entry.text == password_repeat_entry.text &&
                   (!equal_switch_row.active || (equal_switch_row.active &&
                   (password_is_ready (root_password_entry.text) &&
                   root_password_entry.text == root_password_repeat_entry.text)));
    }

    bool password_is_ready (string password) {
        bool no_password_security = Addin.get_instance ().context.get_string ("no-password-security") == "true";
        if (no_password_security) {
            return true;
        } else {
            return password_is_correct (password);
        }
    }

    Strength get_password_strength (
        string password,
        string? old_password = null,
        string? username = null
    ) {
        bool no_password_security = Addin.get_instance ().context.get_string ("no-password-security") == "true";
        if (no_password_security) {
            return {
                hint: "",
                strength_level: GOOD,
                value: 0.0,
                support_value: false
            };
        } else {
            return Password.strength (
                password,
                old_password,
                username
            );
        }
    }

    [GtkCallback]
    void password_changed () {
        Addin.get_instance ().context.set_string ("user-password", password_entry.text);
        if (!equal_switch_row.active) {
            Addin.get_instance ().context.set_string ("user-root-password", root_password_entry.text);
        }

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
        Addin.get_instance ().context.set_string ("user-root-password", root_password_entry.text);

        var strength = get_password_strength (
            root_password_entry.text,
            null,
            Addin.get_instance ().context.get_string ("user-username")
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
        root_password_entry.text = "";
        root_password_repeat_entry.text = "";

        root_password_entry.remove_css_class ("error");
        root_password_context_row.reveal_context = false;
        root_password_repeat_entry.remove_css_class ("error");
        root_password_repeat_context_row.reveal_context = false;

        update_is_ready ();
    }

    [GtkCallback]
    void autologin_switch_changed () {
        Addin.get_instance ().context.set_boolean ("user-autologin", autologin_switch_row.active);
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
