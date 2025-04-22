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

namespace ReadySet {

    public class ApplyCallback : Object {

        public weak ApplyFunc func;

        public ApplyCallback (ApplyFunc func_) {
            func = func_;
        }

        public void apply () throws ApplyError {
            func ();
        }
    }

    public errordomain ApplyError {
        BASE;
    }

    public delegate void ApplyFunc () throws ApplyError;

    public class InputInfo : Object {

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

    public void set_msg_locale (string locale) {
        var result = Result.get_instance ();

        result.current_language = locale;
        Intl.setlocale (LocaleCategory.MESSAGES, locale);
    }

    public string get_current_language () {
        var result = Result.get_instance ();

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
        var default_steps = new string[] {
            "language",
            "keyboard",
            "user",
            "end"
        };

        File? steps_file = null;

        foreach (var sysconfig_dif in Environment.get_system_config_dirs ()) {
            steps_file = File.new_build_filename (sysconfig_dif, "ready-set", "steps");

            if (steps_file.query_exists ()) {
                break;
            }

            steps_file = null;
        }

        if (steps_file == null) {
            return default_steps;
        }

        try {
            uint8[] steps_file_content;
            if (!steps_file.load_contents (null, out steps_file_content, null)) {
                return default_steps;
            }

            string[] data = ((string) steps_file_content).split ("\n");

            for (int i = 0; i < data.length; i++) {
                data[i] = data[i].strip ();
            };

            var data_arr = new Array<string> ();

            foreach (var line in data) {
                if (line != "") {
                    data_arr.append_val (line);
                }
            }

            if (data_arr.index (data_arr.length - 1) != "end") {
                data_arr.append_val ("end");
            }

            return data_arr.data;

        } catch (Error e) {
            warning ("Failed to read steps file: %s", e.message);
            return default_steps;
        }
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
            var keyfile_file = File.new_build_filename ("/etc/dconf/db/local.d/00-ready-set");

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
