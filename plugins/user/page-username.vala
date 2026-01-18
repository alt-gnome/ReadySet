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
    [GtkChild]
    unowned Adw.Avatar avatar_image;
    [GtkChild]
    unowned Gtk.Button remove_avatar_button;
    [GtkChild]
    unowned AvatarChooser avatar_chooser;

    bool username_manually_entered = false;

    string _user_avatar_file;
    public string user_avatar_file {
        get {
            return _user_avatar_file;
        }
        set {
            if (value == "") {
                avatar_image.set_custom_image (null);
                remove_avatar_button.visible = false;

            } else {
                try {
                    avatar_image.set_custom_image (Gdk.Texture.from_filename (value));
                } catch (Error e) {
                    warning (e.message);
                }
            }
            _user_avatar_file = value;
        }
    }

    construct {
        Addin.get_instance ().context.bind_context_to_property (
            "user-username",
            username_entry,
            "text",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE
        );

        Addin.get_instance ().context.bind_context_to_property (
            "user-fullname",
            fullname_entry,
            "text",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE
        );

        Addin.get_instance ().context.bind_context_to_property (
            "user-avatar-file",
            this,
            "user-avatar-file",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE
        );

        avatar_chooser.set_callback (on_avatar_selected);
    }

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
        update_avatar_text ();
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
        update_avatar_text ();
    }

    void update_avatar_text () {
        string? name = fullname_entry.text;

        if (name == "") {
            name = username_entry.text;
        }

        if (name == "") {
            name = null;
        }

        avatar_image.text = name;
    }

    [GtkCallback]
    void on_remove_avatar_button_clicked () {
        remove_avatar_button.visible = false;
        user_avatar_file = "";
    }

    void on_avatar_selected (owned string filename) {
        remove_avatar_button.visible = true;
        user_avatar_file = filename;
    }
}
