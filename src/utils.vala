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

        switch (step_id) {
            case "welcome":
                page_content = new WelcomePage ();
                break;

            case "language":
                page_content = new LanguagePage ();
                break;

            case "test":
                page_content = new TestPage ();
                break;

            case "end":
                page_content = new EndPage ();
                break;

            case "keyboard":
                page_content = new KeyboardPage ();
                break;

            default:
                page_content = new BasePage () {
                    is_ready = true
                };
                break;
        }

        return page_content;
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
}
