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

public class ReadySet.ApplyCallback : Object {

    public weak ApplyFunc func;

    public ApplyCallback (ApplyFunc func_) {
        func = func_;
    }

    public void apply () throws ApplyError {
        func ();
    }
}

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

    public errordomain ApplyError {
        BASE,
        NO_PERMISSION;
    }

    public delegate void ApplyFunc () throws ApplyError;

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

    public BasePage build_page_by_step_id (string step_id) {
        BasePage page_content;

        var page_type = Type.from_name ("ReadySet%sPage".printf (kebab2pascal (step_id)));

        if (page_type == 0) {
            page_content = new BasePage () {
                is_ready = true
            };
        } else {
            page_content = (BasePage) Object.new (page_type);
        }

        return page_content;
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

    string[] get_all_steps () {
        var app = ((ReadySet.Application) GLib.Application.get_default ());

        var steps_data = new Array<string> ();

        if (app.steps_filename != null) {
            var steps_file = File.new_for_path (app.steps_filename);

            if (!steps_file.query_exists ()) {
                error (_("Steps file doesn't exists"));
            }

            uint8[] steps_file_content;
            try {
                if (!steps_file.load_contents (null, out steps_file_content, null)) {
                    error (_("Steps file is empty"));
                }
            } catch (Error e) {
                error (_("Error loading steps file: %s"), e.message);
            }

            string[] data = ((string) steps_file_content).split ("\n");

            for (int i = 0; i < data.length; i++) {
                data[i] = data[i].strip ();
            };

            foreach (var line in data) {
                var stripped_line = line.strip ();

                if (stripped_line != "" && !stripped_line.has_prefix ("#")) {
                    steps_data.append_val (stripped_line);
                }
            }

        } else if (app.steps != null) {
            foreach (var step in app.steps) {
                steps_data.append_val (step);
            }

        } else {
            return DEFAULT_STEPS;
        }

        if (steps_data.index (steps_data.length - 1) != "end") {
            steps_data.append_val ("end");
        }

        return steps_data.data;
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
