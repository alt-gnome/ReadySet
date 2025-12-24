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

[DBus (name = "org.freedesktop.locale1")]
public interface Locale1 : Object {
    public abstract string[] locale { owned get; }
    public abstract string v_console_toggle { owned get; }
    public abstract string v_console_keymap_toggle { owned get; }
    public abstract string x_11_layout { owned get; }
    public abstract string x_11_model { owned get; }
    public abstract string x_11_options { owned get; }
    public abstract string x_11_variant { owned get; }

    public abstract async void set_locale (
        string[] locale,
        bool interactive
    ) throws Error;

    public abstract async void set_v_console_keyboard (
        string keymap,
        string keymap_toggle,
        bool convert,
        bool interactive
    ) throws Error;

    public abstract async void set_x_11_keyboard (
        string layout,
        string model,
        string variant,
        string options,
        bool convert,
        bool interactive
    ) throws Error;
}

namespace Language {

    public void set_current_locale (string locale) {
        var context = Addin.get_instance ().context;

        Intl.setlocale (LocaleCategory.ALL, locale);
        context.set_string ("locale", locale);
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

    string fix_locale (string locale) {
        switch (locale) {
            case "en":
                return "en_US.UTF-8";
            case "ru":
                return "ru_RU.UTF-8";
            default:
                return locale;
        }
    }

    public string[] get_supported_languages () {
        return {"en", "ru"};
    }

    Locale1 get_locale_proxy () {
        try {
            var con = Bus.get_sync (BusType.SYSTEM);

            if (con == null) {
                error ("Failed to connect to bus");
            }

            return con.get_proxy_sync<Locale1> (
                "org.freedesktop.locale1",
                "/org/freedesktop/locale1",
                DBusProxyFlags.NONE
            );
        } catch (Error e) {
            error (e.message);
        }
    }
}
