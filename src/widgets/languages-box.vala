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
    [GtkChild]
    unowned Gtk.SearchEntry search_entry;

    bool _show_more = false;
    public bool show_more {
        get {
            return _show_more;
        }
        set {
            _show_more = value;

            if (_show_more) {
                show_all_languages ();
            }
        }
    }

    static construct {
        typeof (LanguageRow).ensure ();
    }

    Gtk.ScrolledWindow scrolled_window {
        get {
            return (Gtk.ScrolledWindow) get_parent ().get_parent ().get_parent ().get_parent ().get_parent ().get_parent ();
        }
    }

    LanguagePageState page_state {
        get {
            return ((ReadySet.Application) GLib.Application.get_default ()).lang_page_state;
        }
    }

    construct {
        set_base_languages.begin ();

        languages_listbox.set_filter_func ((row) => {
            var action_row = (Adw.ActionRow) row;
            var search_q_downed = search_entry.text.down ();

            if (search_q_downed in action_row.title.down () || search_q_downed in action_row.subtitle.down ()) {
                return true;
            }

            return false;
        });

        search_entry.search_changed.connect (() => {
            languages_listbox.invalidate_filter ();
        });

        languages_listbox.row_activated.connect ((row) => {
            var lr = (LanguageRow) row;
            set_msg_locale (lr.language_locale);

            ((ReadySet.Application) GLib.Application.get_default ()).reload_window ({
                show_more,
                scrolled_window.vadjustment.value,
                search_entry.text
            });
        });

        search_entry.text = page_state.search_query;
        show_more = page_state.show_more;
        Idle.add_once (() => {
            scrolled_window.vadjustment.value = page_state.scroll_position;
        });

        Idle.add_once (() => {
            search_entry.can_focus = true;
        });
    }

    async void set_base_languages () {
        set_languages ({
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

    public void show_all_languages () {
        set_languages (Gnome.Languages.get_all_locales ());
    }

    void set_languages (string[] language_locales) {
        languages_listbox.remove_all ();
        foreach (string locale in language_locales) {
            languages_listbox.append (new LanguageRow (locale));
        }
    }

    [GtkCallback]
    void show_more_clicked () {
        show_more = true;
    }
}
