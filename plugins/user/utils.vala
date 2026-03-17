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

    public string translit_char (unichar c) {
        switch (c) {
            case 'а': return "a";
            case 'б': return "b";
            case 'в': return "v";
            case 'г': return "g";
            case 'д': return "d";
            case 'е': return "e";
            case 'ё': return "yo";
            case 'ж': return "zh";
            case 'з': return "z";
            case 'и': return "i";
            case 'й': return "y";
            case 'к': return "k";
            case 'л': return "l";
            case 'м': return "m";
            case 'н': return "n";
            case 'о': return "o";
            case 'п': return "p";
            case 'р': return "r";
            case 'с': return "s";
            case 'т': return "t";
            case 'у': return "u";
            case 'ф': return "f";
            case 'х': return "kh";
            case 'ц': return "ts";
            case 'ч': return "ch";
            case 'ш': return "sh";
            case 'щ': return "shch";
            case 'ъ': return "";
            case 'ы': return "y";
            case 'ь': return "";
            case 'э': return "e";
            case 'ю': return "yu";
            case 'я': return "ya";

            case 'А': return "A";
            case 'Б': return "B";
            case 'В': return "V";
            case 'Г': return "G";
            case 'Д': return "D";
            case 'Е': return "E";
            case 'Ё': return "Yo";
            case 'Ж': return "Zh";
            case 'З': return "Z";
            case 'И': return "I";
            case 'Й': return "Y";
            case 'К': return "K";
            case 'Л': return "L";
            case 'М': return "M";
            case 'Н': return "N";
            case 'О': return "O";
            case 'П': return "P";
            case 'Р': return "R";
            case 'С': return "S";
            case 'Т': return "T";
            case 'У': return "U";
            case 'Ф': return "F";
            case 'Х': return "Kh";
            case 'Ц': return "Ts";
            case 'Ч': return "Ch";
            case 'Ш': return "Sh";
            case 'Щ': return "Shch";
            case 'Ъ': return "";
            case 'Ы': return "Y";
            case 'Ь': return "";
            case 'Э': return "E";
            case 'Ю': return "Yu";
            case 'Я': return "Ya";

            default: return c.to_string ();
        }
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

        var corrected_builder = new StringBuilder ();

        int next_index = 0;
        unichar c;

        while (uname.get_next_char (ref next_index, out c)) {
            if (c >= 'A' && c <= 'Z') {
                corrected_builder.append_unichar (c.tolower ());
            } else if (c >= 'a' && c <= 'z') {
                corrected_builder.append_unichar (c);
            } else if (c >= 'А' && c <= 'Я') {
                corrected_builder.append (translit_char (c.tolower ()));
            } else if (c >= 'а' && c <= 'я') {
                corrected_builder.append (translit_char (c));
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

        return corrected_builder.free_and_steal ();
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

#if WITH_ROOT_SET
    bool set_root_password (string password) {
        try {
            ReadySet.pkexec ({ Path.build_filename (Config.LIBEXECDIR, "ready-set-set-root-password"), password });
            return true;
        } catch (Error e) {
            return false;
        }
    }
#endif

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
