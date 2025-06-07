/* Copyright 2024-2025 Vladimir Vaskov <rirusha@altlinux.org>
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

    const string[] DEFAULT_STEPS = {
        "language",
        "keyboard",
        "user",
        "end",
    };

    public errordomain ApplyError {
        BASE;
    }

    public delegate void ApplyFunc () throws ApplyError;

    public void set_msg_locale (string locale) {
        var result = Data.get_instance ();

        result.current_language = locale;
        Intl.setlocale (LocaleCategory.MESSAGES, locale);
    }

    public string get_current_language () {
        var result = Data.get_instance ();

        if (result.current_language != null) {
            return result.current_language;
        }

        foreach (string lang in Intl.get_language_names ()) {
            if (Gnome.Languages.parse_locale (lang, null, null, null, null)) {
                return lang;
            }
        }

        return "C";
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

    void create_override (string schema_name, string key, Variant value) {
        try {
            var keyfile_file = File.new_build_filename (Config.SYSCONFDIR, "dconf/db/local.d/00-ready-set");

            if (!keyfile_file.query_exists ()) {
                keyfile_file.create (FileCreateFlags.NONE, null);
            }

            var keyfile = new KeyFile ();
            keyfile.load_from_file (keyfile_file.peek_path (), KeyFileFlags.NONE);

            keyfile.set_value (schema_name, key, value.print (false));

            keyfile.save_to_file (keyfile_file.peek_path ());

        } catch (Error e) {
            warning (e.message);
        }
    }
}
