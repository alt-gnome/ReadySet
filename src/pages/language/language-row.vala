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

[GtkTemplate (ui = "/space/rirusha/ReadySet/ui/language-row.ui")]
public sealed class ReadySet.LanguageRow : Adw.ActionRow {

    [GtkChild]
    unowned Gtk.Revealer suffix_revealer;

    public LocaleData locale_data { get; construct set; }

    public bool is_current_language { get; set; default = false; }

    public LanguageRow (LocaleData locale_data) {
        Object (locale_data: locale_data);
    }

    construct {
        suffix_revealer.reveal_child = locale_data.locale == get_current_language ();

        title = locale_data.country_loc;
        subtitle = locale_data.country_cur;
    }

    [GtkCallback]
    void row_activated () {
        if (locale_data.locale == get_current_language ()) {
            return;
        }

        set_msg_locale (locale_data.locale);

        ReadySet.Application.get_default ().reload_window ();
    }
}
