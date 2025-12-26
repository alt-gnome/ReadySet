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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Language/ui/row.ui")]
public sealed class Language.Row : Adw.ActionRow {

    LocaleData _locale_data;
    public LocaleData locale_data {
        get {
            return _locale_data;
        }
        construct set {
            _locale_data = value;
            if (value != null) {
                var is_current_language = value.locale == get_current_language ();

                if (is_current_language) {
                    add_css_class ("property");
                    title = _("Current language");
                    subtitle = value.country_cur;
                } else {
                    remove_css_class ("property");
                    title = value.country_loc;
                    subtitle = value.country_cur;
                }
            } else {
                title = "";
                subtitle = "";
            }
        }
    }

    public Row (LocaleData locale_data) {
        Object (locale_data: locale_data);
    }

    [GtkCallback]
    void row_activated () {
        if (locale_data.locale == get_current_language ()) {
            return;
        }

        set_current_locale (locale_data.locale);

        Addin.get_instance ().context.reload_window ();
    }
}
