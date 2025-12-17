/* Copyright (C) 2024-2025 Vladimir Romanov <rirusha@altlinux.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
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

public class ReadySet.InputInfo : Object {

    public string id { get; construct; }

    public string type_ { get; construct; }

    public string format { get; construct; }

    public InputInfo (string type, string id_) {
        Object (
            id: id_,
            type_: type,
            format: "%s::%s".printf (type, id_)
        );
    }

    public uint _hash () {
        return format.hash ();
    }

    public static uint hash (InputInfo a) {
        return a._hash ();
    }

    public static bool equal (InputInfo a, InputInfo b) {
        return strcmp (a.format, b.format) == 0;
    }
}

namespace ReadySet {

    const string RSS = "\n::READY-SET-SEPARATOR::\n";

    const string[] DEFAULT_STEPS = {
        "language",
        "keyboard",
        "user",
        "end",
    };

    public void set_msg_locale (string locale) {
        var result = Data.get_instance ();

        result.language.current_language = locale;
    }

    public string get_current_language () {
        var result = Data.get_instance ();

        return result.language.current_language;
    }

    public string[] get_supported_languages () {
        return Config.SUPPORTED_LANGUAGES.split ("|");
    }

    string kebab2pascal (string kebab_string) {
        var builder = new StringBuilder ();
        bool capitalize = true;

        for (int i = 0; i < kebab_string.length; i++) {
            char c = kebab_string[i];
            if (c == '-') {
                capitalize = true;
            } else {
                if (capitalize) {
                    builder.append_c (c.toupper ());
                    capitalize = false;
                } else {
                    builder.append_c (c);
                }
            }
        }

        return builder.free_and_steal ();
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

    bool is_username_used (string? username) {
        if (username == null || username == "") {
            return false;
        }

        weak Posix.Passwd? pwent = Posix.getpwnam (username);

        return pwent != null;
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

    void pkexec (owned string[] cmd, string? user = null) throws Error {
        var launcher = new SubprocessLauncher (NONE);
        var argv = new Gee.ArrayList<string>.wrap ({ "pkexec" });

        if (user != null) {
            argv.add_all_array ({ "--user", user });
        }

        argv.add_all_array (cmd);

        //  pkexec won't let us run the program if $SHELL isn't in /etc/shells,
        //  so remove it from the environment.
        launcher.unsetenv ("SHELL");
        var process = launcher.spawnv (argv.to_array ().copy ());

        process.wait_check ();
    }
}
