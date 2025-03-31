/* Copyright 2024 rirusha
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

    public struct LanguagePageState {
        public bool show_more;
        public double scroll_position;
        public string search_query;
    }

    string current_language;

    public void set_msg_locale (string locale) {
        current_language = locale;
        Intl.setlocale (LocaleCategory.MESSAGES, locale);
    }

    public string get_current_language () {
        if (current_language != null) {
            return current_language;
        }

        foreach (string lang in Intl.get_language_names ()) {
            if (lang.length > 0) {
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

            default:
                page_content = new BasePage ();
                break;
        }

        return page_content;
    }
}
