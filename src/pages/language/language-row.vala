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

[GtkTemplate (ui = "/space/rirusha/ReadySet/ui/language-row.ui")]
public sealed class ReadySet.LanguageRow : Adw.ActionRow {

    public string language_locale { get; construct set; }

    public bool is_current_language { get; set; default = false; }

    public LanguageRow (string language_locale) {
        Object (language_locale: language_locale);
    }

    construct {
        is_current_language = language_locale == get_current_language ();

        title = Gnome.Languages.get_country_from_locale (language_locale, language_locale);
        subtitle = Gnome.Languages.get_country_from_locale (language_locale, get_current_language ());
    }
}
