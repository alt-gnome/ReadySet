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

[GtkTemplate (ui = "/space/rirusha/ReadySet/ui/language-page.ui")]
public sealed class ReadySet.LanguagePage : BasePage {

    [GtkChild]
    unowned LanguagesBox languages_box;

    weak LanguagePageState page_state {
        get {
            return ((ReadySet.Application) GLib.Application.get_default ()).lang_page_state;
        }
    }

    construct {
        root_scrolled_window.vadjustment.value_changed.connect (() => {
            page_state.scroll_position = root_scrolled_window.vadjustment.value;
        });

        Idle.add_once (() => {
            root_scrolled_window.vadjustment.value = page_state.scroll_position;
        });
    }
}
