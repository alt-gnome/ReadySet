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

namespace User {

    public delegate void SelectAvatarCallback (owned string filename);

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

    public void update_css_by_strength (Gtk.Widget row, StrengthLevel strength_level) {
        row.remove_css_class ("error");
        row.remove_css_class ("warning");
        row.remove_css_class ("success");

        switch (strength_level) {
            case StrengthLevel.BAD:
                row.add_css_class ("error");
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

        foreach (char c in fullname.to_utf8 ()) {
            unichar uc = c.to_string ().get_char_validated ();

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
        const int MAXNAMELEN = 32;

        string uname = username;

        if (uname == "") {
            return "";
        }
        if (uname.length > MAXNAMELEN) {
            uname = uname[0:MAXNAMELEN];
        }

        int len = 0;
        var corrected_uname = new char[uname.length];

        for (int i = 0; i < uname.length; i++) {
            char ch = username[i];

            if (ch >= 'A' && ch <= 'Z') {
                corrected_uname[len] = ch.tolower ();
                len++;
            } else if (ch >= 'a' && ch <= 'z') {
                corrected_uname[len] = ch;
                len++;
            } else if (ch >= '0' && ch <= '9') {
                if (len > 0) {
                    corrected_uname[len] = ch;
                    len++;
                }
            } else if (ch == ' ' || ch == '-' || ch == '_') {
                if (len > 0) {
                    corrected_uname[len] = '-';
                    len++;
                }
            }
        }

        return (string) corrected_uname;
    }

    bool username_is_correct (string username, bool parental_controls_enabled, out string error) {
        bool empty;
        bool in_use;
        bool too_long;
        bool valid;
        bool parental_controls_conflict;

        error = "";

        const int MAXNAMELEN = 32;

        if (username == null || username == "") {
            empty = true;
            in_use = false;
            too_long = false;
        } else {
            empty = false;
            in_use = is_username_used (username);
            too_long = username.length > MAXNAMELEN;
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

    bool set_root_password (string password) {
        try {
            ReadySet.pkexec ({ Path.build_filename (Config.LIBEXECDIR, "ready-set-set-root-password"), password });
            return true;
        } catch (Error e) {
            return false;
        }
    }

    public string get_current_language () {
        var context = Addin.get_instance ().context;

        var locale = context.get_string ("locale");

        if (locale == null) {
            debug ("Languages: %s", string.joinv (", ", Intl.get_language_names ()));

            foreach (string lang in Intl.get_language_names ()) {
                if (Gnome.Languages.parse_locale (lang, null, null, null, null)) {
                    locale = lang;
                    break;
                }
            }

            if (locale == null) {
                locale = "C";
            }
        }

        return locale;
    }

    public string[] get_context_facesdirs () {
        var context = Addin.get_instance ().context;
        var facesdir = new Gee.ArrayList<string> ();

        var dirs = context.get_strv ("user-avatar-directories");
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
}
