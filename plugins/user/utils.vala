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

[DBus (name = "org.freedesktop.Accounts.User")]
public interface User.AccountsUser : Object {

    public abstract async void set_password (
        string password,
        string hint
    ) throws Error;
}

namespace User {

    public struct Strength {
        public string hint;
        public StrengthLevel level;
        public double value;
        public bool support_value;
    }

    public enum StrengthLevel {
        BAD,
        NOT_BAD,
        GOOD;
    }

    async User.AccountsUser get_user_proxy (uint uid) throws Error {
        var con = yield Bus.get (BusType.SYSTEM);

        if (con == null) {
            error ("Failed to connect to bus");
        }

        return con.get_proxy_sync<User.AccountsUser> (
            "org.freedesktop.Accounts",
            "/org/freedesktop/Accounts/User%u".printf (uid),
            DBusProxyFlags.NONE
        );
    }

    async void set_user_password (string password_hash, uint uid) throws Error {
        var proxy = yield get_user_proxy (uid);
        yield proxy.set_password (password_hash, "");
    }

    public void update_correct (Adw.PreferencesRow row, bool is_correct) {
        row.add_css_class ("error");

        if (is_correct)
            row.remove_css_class ("error");
    }

    bool is_username_used (string? username) {
        if (username == null || username == "") {
            return false;
        }

        weak Posix.Passwd? pwent = Posix.getpwnam (username);

        return pwent != null;
    }

    public void update_css_by_strength (Gtk.Widget row, StrengthLevel strength_level, bool enforce_password_qwcheck) {
        row.remove_css_class ("error");
        row.remove_css_class ("warning");
        row.remove_css_class ("success");

        switch (strength_level) {
            case StrengthLevel.BAD:
                if (enforce_password_qwcheck) {
                    row.add_css_class ("error");
                } else {
                    row.add_css_class ("warning");
                }
                break;
            case StrengthLevel.NOT_BAD:
                row.add_css_class ("warning");
                break;
            case StrengthLevel.GOOD:
                //  row.add_css_class ("success");
                break;
        }
    }

    bool fullname_is_correct (string fullname, out string error) {
        bool is_empty = true;

        error = "";

        int next_index = 0;
        unichar uc;

        while (fullname.get_next_char (ref next_index, out uc)) {
            if (uc == (unichar) (-1) || uc == (unichar) (-2))
                break;

            if (!uc.isspace ()) {
                is_empty = false;
                break;
            }
        }

        if (is_empty)
            error = _ ("Name cannot be empty");

        return !is_empty;
    }

    string correct_username (string username) {
        string uname = username;

        if (uname == "") {
            return "";
        }

        var corrected_builder = new StringBuilder ();

        int next_index = 0;
        unichar c;

        while (uname.get_next_char (ref next_index, out c)) {
            if (c >= 'A' && c <= 'Z') {
                corrected_builder.append_unichar (c.tolower ());
            } else if (c >= 'a' && c <= 'z') {
                corrected_builder.append_unichar (c);
            } else if (c >= 'А' && c <= 'Я') {
                corrected_builder.append (translit_char_cyrillic (c.tolower ()));
            } else if (c >= 'а' && c <= 'я') {
                corrected_builder.append (translit_char_cyrillic (c));
            } else if (c >= '0' && c <= '9') {
                if (corrected_builder.len > 0) {
                    corrected_builder.append_unichar (c);
                }
            } else if (c == ' ' || c == '-' || c == '_') {
                if (corrected_builder.len > 0) {
                    corrected_builder.append_unichar ('-');
                }
            }
        }

        var res = corrected_builder.free_and_steal ();

        if (res.length >= Posix.Limits.LOGIN_NAME_MAX) {
            return res[0:Posix.Limits.LOGIN_NAME_MAX];
        }
        return res;
    }

    bool username_is_correct (string username, bool parental_controls_enabled, out string error) {
        bool empty;
        bool in_use;
        bool too_long;
        bool valid;
        bool parental_controls_conflict;

        error = "";

        if (username == null || username == "") {
            empty = true;
            in_use = false;
            too_long = false;
        } else {
            empty = false;
            in_use = is_username_used (username);
            too_long = username.length > Posix.Limits.LOGIN_NAME_MAX;
        }

        valid = true;

        if (!in_use && !empty && !too_long) {
            for (int i = 0; i < username.length; i++) {
                char ch = username[i];
                if (i == 0) {
                    if (!(ch >= 'a' && ch <= 'z'))
                        valid = false;
                } else {
                    if (!((ch >= 'a' && ch <= 'z') ||
                        (ch >= '0' && ch <= '9') ||
                        ch == '-' || ch == '_')) {
                        valid = false;
                    }
                }
            }
        }

        parental_controls_conflict = parental_controls_enabled && username == "administrator";

        valid = !empty && !in_use && !too_long && !parental_controls_conflict && valid;

        if (!empty && (in_use || too_long || parental_controls_conflict || !valid)) {
            if (in_use || parental_controls_conflict) {
                error = _("That username isn't available. Please try another");
            } else if (too_long) {
                error = _("The username is too long");
            } else if (!(username[0] >= 'a' && username[0] <= 'z')) {
                error = _("The username must start with a lower case letter from a-z");
            } else {
                error = _("The username should only consist of lower case letters from a-z, digits, and the following characters: '-', '_'"); // vala-lint=line-length
            }
        } else if (empty) {
            error = _("Username cannot be empty");
        }

        return valid;
    }

    bool password_is_correct (string password) {
        return Password.strength (password).level != BAD;
    }

    string build_homed_password_record (string password) {
        var passwords = new Serialize.Array<string> ();
        passwords.add (password);

        var record = new Serialize.Dict<Serialize.Array<string>> ();
        record.set ("password", passwords);

        return Serialize.JsonWorker.serialize (record);
    }

    async void set_homed_password (string username, string password) throws Error {
        var bus = yield Bus.get (BusType.SYSTEM);

        string new_secret = build_homed_password_record (password);
        string old_secret = build_homed_password_record ("");

        yield bus.call (
            "org.freedesktop.home1",
            "/org/freedesktop/home1",
            "org.freedesktop.home1.Manager",
            "ChangePasswordHome",
            new Variant ("(sss)", username, new_secret, old_secret),
            null,
            DBusCallFlags.NONE,
            2 * 60 * 1000,
            null
        );
    }

    void set_user_icon_file (Act.User user, string icon_file) {
        if (user.uses_homed ()) {
            user.set_icon_file (icon_file);
            return;
        }

        File? temporary_file = null;

        try {
            FileIOStream temporary_stream;
            temporary_file = File.new_tmp ("ready-set-avatar-XXXXXX", out temporary_stream);

            // A private source makes classic AccountsService store the icon in
            // its managed directory instead of retaining a path under /usr/share.
            temporary_stream.output_stream.splice (
                File.new_for_path (icon_file).read (),
                OutputStreamSpliceFlags.CLOSE_SOURCE
            );
            temporary_stream.close ();

            user.set_icon_file (temporary_file.get_path ());
        } catch (Error e) {
            warning ("Failed to prepare avatar for AccountsService: %s", e.message);
            user.set_icon_file (icon_file);
        } finally {
            if (temporary_file != null)
                FileUtils.unlink (temporary_file.get_path ());
        }
    }

    public string[] get_context_facesdirs () {
        var context = Addin.get_instance ().context;
        var facesdir = new Gee.ArrayList<string> ();

        var dirs = context.get_strv ("user.avatar-directories");
        if (dirs == null) {
            return {};
        }

        foreach (var dir_path in dirs) {
            if (dir_path != "") {
                facesdir.add (dir_path);
            }
        }

        return facesdir.to_array ();
    }

    public string[] get_settings_facesdirs () {
        var facesdir = new Gee.ArrayList<string> ();
        var settings = new Settings ("org.gnome.desktop.interface");

        var dirs = settings.get_strv ("avatar-directories");
        if (dirs == null) {
            return {};
        }

        foreach (var dir_path in dirs) {
            if (dir_path != "") {
                facesdir.add (dir_path);
            }
        }

        return facesdir.to_array ();
    }

    public string[] get_system_facesdirs () {
        var facesdir = new Gee.ArrayList<string> ();

        foreach (var dir in Environment.get_system_data_dirs ()) {
            facesdir.add (Path.build_filename (dir, "pixmaps", "faces"));
        }

        return facesdir.to_array ();
    }

    public string capital (string str) {
        var builder = new StringBuilder ();

        int next_index = 0;
        unichar c;

        while (str.get_next_char (ref next_index, out c)) {
            if (builder.len == 0) {
                builder.append_unichar (c.toupper ());
            } else {
                builder.append_unichar (c);
            }
        }

        return builder.free_and_steal ();
    }

    bool password_is_ready (string password) {
        bool enforce = Addin.get_instance ().context.get_boolean ("user.enforce-password-quality");
        if (!enforce) {
            return password.length > 0;
        } else {
            return password_is_correct (password);
        }
    }
}
