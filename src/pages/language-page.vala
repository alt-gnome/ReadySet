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
    unowned Adw.ToolbarView view;
    [GtkChild]
    unowned Gtk.Stack title_stack;
    [GtkChild]
    unowned Gtk.SearchEntry search_entry;
    [GtkChild]
    unowned LanguagesBox languages_box;
    [GtkChild]
    unowned Gtk.ListBox bottom_list_box;

    construct {
        notify["search-enabled"].connect (() => {
            title_stack.visible_child_name = search_enabled ? "search" : "title";

            if (search_enabled) {
                search_entry.focus (Gtk.DirectionType.UP);
            } else {
                search_entry.text = "";
            }
        });
    }

    [GtkCallback]
    void on_show_more_activated () {
        languages_box.show_all_languages.begin ();
        languages_box.show_search_bar = true;
        view.reveal_bottom_bars = false;
    }
}
