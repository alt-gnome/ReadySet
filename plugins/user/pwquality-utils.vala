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

namespace User.Password {

    static PasswordQuality.Settings? _pwq_settings = null;

    unowned PasswordQuality.Settings get_pwq () {
        if (_pwq_settings == null) {
            _pwq_settings = new PasswordQuality.Settings ();

            var error = _pwq_settings.read_config (Addin.get_instance ().context.get_string ("passwd-conf-path"), null);
            if (error != PasswordQuality.Error.SUCCESS) {
                GLib.error (error.to_string ());
            }
        }

        return _pwq_settings;
    }

    public string generate () {
        string res;
        var error = get_pwq ().generate (0, out res);

        if (error != PasswordQuality.Error.SUCCESS) {
            GLib.error (error.to_string ());
        }

        return res;
    }

    internal string error_hint (PasswordQuality.Error error) {
        switch (error) {
            case PasswordQuality.Error.SAME_PASSWORD:
                return _("The new password needs to be different from the old one.");
            case PasswordQuality.Error.CASE_CHANGES_ONLY:
            case PasswordQuality.Error.TOO_SIMILAR:
            case PasswordQuality.Error.ROTATED:
                return _("This password is very similar to your last one. Try changing some letters and numbers.");
            case PasswordQuality.Error.USER_CHECK:
                return _("This is a weak password. A password without your user name would be stronger.");
            case PasswordQuality.Error.GECOS_CHECK:
                return _("This is a weak password. Try to avoid using your name in the password.");
            case PasswordQuality.Error.BAD_WORDS:
                return _("This is a weak password. Try to avoid some of the words included in the password.");
            case PasswordQuality.Error.CRACKLIB_CHECK:
                return _("This is a weak password. Try to avoid common words.");
            case PasswordQuality.Error.PALINDROME:
                return _("This is a weak password. Try to avoid reordering existing words.");
            case PasswordQuality.Error.MIN_DIGITS:
                return _("This is a weak password. Try to use more numbers.");
            case PasswordQuality.Error.MIN_UPPERS:
                return _("This is a weak password. Try to use more uppercase letters.");
            case PasswordQuality.Error.MIN_LOWERS:
                return _("This is a weak password. Try to use more lowercase letters.");
            case PasswordQuality.Error.MIN_OTHERS:
                return _("This is a weak password. Try to use more special characters, like punctuation.");
            case PasswordQuality.Error.MIN_CLASSES:
                return _("This is a weak password. Try to use a mixture of letters, numbers and punctuation.");
            case PasswordQuality.Error.MAX_CONSECUTIVE:
                return _("This is a weak password. Try to avoid repeating the same character.");
            case PasswordQuality.Error.MAX_CLASS_REPEAT:
                return _("This is a weak password. Try to avoid repeating the same type of character: you need to mix up letters, numbers and punctuation."); // vala-lint=line-length
            case PasswordQuality.Error.MAX_SEQUENCE:
                return _("This is a weak password. Try to avoid sequences like 1234 or abcd.");
            case PasswordQuality.Error.MIN_LENGTH:
                return _("This is a weak password. Try to add more letters, numbers and punctuation.");
            case PasswordQuality.Error.EMPTY_PASSWORD:
                return _("Mix uppercase and lowercase and try to use a number or two.");
            default:
                return _("Adding more letters, numbers and punctuation will make the password stronger.");
        }
    }

    public Strength strength (
        string password,
        string? old_password = null,
        string? username = null
    ) {
        var rv = get_pwq ().check (password, old_password, username, null);
        double strength = (0.02 * rv).clamp (0.0, 1.0);
        StrengthLevel strength_level;

        if (rv <= 0) {
            strength_level = BAD;
        } else if (rv <= 50) {
            strength_level = NOT_BAD;
        } else {
            strength_level = GOOD;
        }

        return {
            hint: error_hint (rv),
            level: strength_level,
            value: strength,
            support_value: true
        };
    }
}
