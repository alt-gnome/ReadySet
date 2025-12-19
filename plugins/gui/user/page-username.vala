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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/User/ui/page-username.ui")]
public class User.PageUsername : ReadySet.BasePage {

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

    bool username_manually_entered = false;

    void update_is_ready () {
        is_ready = fullname_is_correct (fullname_entry.text, null) &&
                   username_is_correct (username_entry.text, false, null);
    }

    string get_auto_username () {
        return correct_username (fullname_entry.text);
    }

    void auto_enter_username () {
        username_entry.text = get_auto_username ();
    }

    [GtkCallback]
    void fullname_changed () {
        Addin.get_instance ().context.set_string ("user-fullname", fullname_entry.text);

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
        Addin.get_instance ().context.set_string ("user-username", username_entry.text);

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
}
