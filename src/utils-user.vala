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

//  Took from gnome-initial-setup

namespace ReadySet {

    static PasswordQuality.Settings? _pwq_settings = null;

    public void update_correct (Adw.PreferencesRow row, bool is_correct) {
        row.add_css_class ("error");

        if (is_correct)
            row.remove_css_class ("error");
    }

    public void update_css_by_strength (Gtk.Widget row, int strength) {
        row.remove_css_class ("error");
        row.remove_css_class ("warning");
        row.remove_css_class ("success");

        if (strength <= 1)
            row.add_css_class ("error");
        else if (strength <= 3)
            row.add_css_class ("warning");
        else if (strength < 5)
            row.add_css_class ("success");
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
        int password_strength;
        pw_strength (password, null, null, null, out password_strength);

        return password_strength >= 4;
    }

    unowned PasswordQuality.Settings get_pwq () {
        if (_pwq_settings == null) {
            _pwq_settings = new PasswordQuality.Settings ();

            var error = _pwq_settings.read_config (null, null);
            if (error != PasswordQuality.Error.SUCCESS) {
                GLib.error (error.to_string ());
            }
        }

        return _pwq_settings;
    }

    int pw_min_length () {
        int value;
        var error = get_pwq ().get_int_value (PasswordQuality.Setting.MIN_LENGTH, out value);

        if (error != PasswordQuality.Error.SUCCESS) {
            GLib.error (error.to_string ());
        }

        return value;
    }

    //  string pw_generate () {
    //      string res;
    //      var error = get_pwq ().generate (0, out res);

    //      if (error != PasswordQuality.Error.SUCCESS) {
    //          GLib.error (error.to_string ());
    //      }

    //      return res;
    //  }

    string pw_error_hint (PasswordQuality.Error error) {
        switch (error) {
            case PasswordQuality.Error.SAME_PASSWORD:
                return "The new password needs to be different from the old one.";
            case PasswordQuality.Error.CASE_CHANGES_ONLY:
            case PasswordQuality.Error.TOO_SIMILAR:
            case PasswordQuality.Error.ROTATED:
                return "This password is very similar to your last one. Try changing some letters and numbers.";
            case PasswordQuality.Error.USER_CHECK:
                return "This is a weak password. A password without your user name would be stronger.";
            case PasswordQuality.Error.GECOS_CHECK:
                return "This is a weak password. Try to avoid using your name in the password.";
            case PasswordQuality.Error.BAD_WORDS:
                return "This is a weak password. Try to avoid some of the words included in the password.";
            case PasswordQuality.Error.CRACKLIB_CHECK:
                return "This is a weak password. Try to avoid common words.";
            case PasswordQuality.Error.PALINDROME:
                return "This is a weak password. Try to avoid reordering existing words.";
            case PasswordQuality.Error.MIN_DIGITS:
                return "This is a weak password. Try to use more numbers.";
            case PasswordQuality.Error.MIN_UPPERS:
                return "This is a weak password. Try to use more uppercase letters.";
            case PasswordQuality.Error.MIN_LOWERS:
                return "This is a weak password. Try to use more lowercase letters.";
            case PasswordQuality.Error.MIN_OTHERS:
                return "This is a weak password. Try to use more special characters, like punctuation.";
            case PasswordQuality.Error.MIN_CLASSES:
                return "This is a weak password. Try to use a mixture of letters, numbers and punctuation.";
            case PasswordQuality.Error.MAX_CONSECUTIVE:
                return "This is a weak password. Try to avoid repeating the same character.";
            case PasswordQuality.Error.MAX_CLASS_REPEAT:
                return "This is a weak password. Try to avoid repeating the same type of character: you need to mix up letters, numbers and punctuation."; // vala-lint=line-length
            case PasswordQuality.Error.MAX_SEQUENCE:
                return "This is a weak password. Try to avoid sequences like 1234 or abcd.";
            case PasswordQuality.Error.MIN_LENGTH:
                return "This is a weak password. Try to add more letters, numbers and punctuation.";
            case PasswordQuality.Error.EMPTY_PASSWORD:
                return "Mix uppercase and lowercase and try to use a number or two.";
            default:
                return "Adding more letters, numbers and punctuation will make the password stronger.";
        }
    }

    double pw_strength (
        string password,
        string? old_password,
        string? username,
        out string hint,
        out int strength_level
    ) {
        var rv = get_pwq ().check (password, old_password, username, null);
        int length = password.length;
        double strength = (0.01 * rv).clamp (0.0, 1.0);

        if (rv < 0)
            strength_level = (length > 0) ? 1 : 0;
        else if (strength < 0.50)
            strength_level = 2;
        else if (strength < 0.75)
            strength_level = 3;
        else if (strength < 0.90)
            strength_level = 4;
        else
            strength_level = 5;

        if (length > 0 && length < pw_min_length ())
            hint = pw_error_hint (PasswordQuality.Error.MIN_LENGTH);
        else
            hint = pw_error_hint (rv);

        return strength;
    }

    bool set_root_password (string password) {
        try {
            var subprocess = new Subprocess.newv (
                { "pkexec", "/usr/sbin/chpasswd" },
                SubprocessFlags.STDIN_PIPE | SubprocessFlags.STDOUT_SILENCE | SubprocessFlags.STDERR_SILENCE
            );

            var stdin_stream = new DataOutputStream (subprocess.get_stdin_pipe ());

            stdin_stream.put_string ("root:%s\n".printf (password));
            stdin_stream.close (); // закрываем stdin

            subprocess.wait_check ();

            return true;
        } catch (Error e) {
            return false;
        }
    }
}
