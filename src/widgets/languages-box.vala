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

[GtkTemplate (ui = "/space/rirusha/ReadySet/ui/languages-box.ui")]
public sealed class ReadySet.LanguagesBox : Adw.Bin {

    [GtkChild]
    unowned Gtk.ListBox languages_listbox;

    public bool show_search_bar { get; set; default = false; }

    public string search_query { get; set; default = ""; }

    static construct {
        typeof (LanguageRow).ensure ();
    }

    construct {
        set_base_languages.begin ();

        languages_listbox.set_filter_func ((row) => {
            var action_row = (Adw.ActionRow) row;
            var search_q_downed = search_query.down ();

            if (search_q_downed in action_row.title.down () || search_q_downed in action_row.subtitle.down ()) {
                return true;
            }

            return false;
        });

        notify["search-query"].connect (() => {
            languages_listbox.invalidate_filter ();
        });

        languages_listbox.set_placeholder (new NothingToShow ());
    }

    async void set_base_languages () {
        yield set_languages ({
            "ru_RU.UTF-8",
            "en_US.UTF-8",
            "de_DE.UTF-8",
            "fr_FR.UTF-8",
            "es_ES.UTF-8",
            "zh_CN.UTF-8",
            "ja_JP.UTF-8",
            "ar_EG.UTF-8",
        });
    }

    public async void show_all_languages () {
        yield set_languages (Gnome.Languages.get_all_locales ());
    }

    async void set_languages (string[] language_locales) {
        languages_listbox.remove_all ();
        foreach (string locale in language_locales) {
            languages_listbox.append (new LanguageRow (locale));

            Idle.add (set_languages.callback, Priority.LOW);
            yield;
        }
    }
}
