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

[GtkTemplate (ui = "/space/rirusha/ReadySet/ui/languages-box.ui")]
public sealed class ReadySet.LanguagesBox : Adw.Bin {

    [GtkChild]
    unowned Gtk.ListBox languages_listbox;
    [GtkChild]
    unowned Gtk.SearchEntry search_entry;

    static bool saved_show_more = false;
    static string saved_search_query = "";

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

            saved_show_more = _show_more;
        }
    }

    static construct {
        typeof (LanguageRow).ensure ();
    }

    construct {
        set_supported_languages.begin ();

        search_entry.changed.connect (() => {
            saved_search_query = search_entry.text;
        });

        search_entry.text = saved_search_query;
        show_more = saved_show_more;

        Idle.add_once (() => {
            search_entry.can_focus = true;
        });

        languages_listbox.set_placeholder (new Gtk.Label ("ABOBA"));
    }

    async void set_supported_languages () {
        var lang_arr = new Array<string> ();
        foreach (string locale in get_supported_languages ()) {
            lang_arr.append_val (fix_locale (locale));
        }

        var cl = get_current_language ();

        if (!(cl in lang_arr.data) && cl != "C" && Gnome.Languages.get_language_from_code (cl, null) != null) {
            lang_arr.append_val (cl);
        }

        set_languages (lang_arr.data);

        //  set_languages ({
        //      "ru_RU.UTF-8",
        //      "en_US.UTF-8",
        //      "de_DE.UTF-8",
        //      "fr_FR.UTF-8",
        //      "es_ES.UTF-8",
        //      "zh_CN.UTF-8",
        //      "ja_JP.UTF-8",
        //      "ar_EG.UTF-8",
        //  });
    }

    public void show_all_languages () {
        set_languages (Gnome.Languages.get_all_locales ());
    }

    void set_languages (string[] language_locales) {
        var model = new ListStore (typeof (LocaleData));

        LocaleData locale_data;
        foreach (var locale in language_locales) {
            locale_data = new LocaleData (locale);
            if (locale_data.country_cur != "" && locale_data.country_cur != "" && locale_data.country_cur != null && locale_data.country_cur != null) {
                model.append (locale_data);
            }
        }

        var sort_model = new Gtk.SortListModel (model, get_sorter ());
        var filter_model = new Gtk.FilterListModel (sort_model, get_filter ());

        languages_listbox.bind_model (
            filter_model,
            (obj) => {
                return new LanguageRow ((LocaleData) obj);
            }
        );
    }

    Gtk.Sorter get_sorter () {
        var multisorter = new Gtk.MultiSorter ();

        var current_sorter = new Gtk.StringSorter (new Gtk.PropertyExpression (
            typeof (LocaleData),
            null,
            "country-loc"
        ));

        var local_sorter = new Gtk.StringSorter (new Gtk.PropertyExpression (
            typeof (LocaleData),
            null,
            "country-cur"
        ));

        multisorter.append (current_sorter);
        multisorter.append (local_sorter);

        return multisorter;
    }

    Gtk.Filter get_filter () {
        var multifilter = new Gtk.AnyFilter ();

        var current_filter = new Gtk.StringFilter (new Gtk.PropertyExpression (
            typeof (LocaleData),
            null,
            "country-cur"
        ));
        current_filter.bind_property (
            "search",
            search_entry,
            "text",
            GLib.BindingFlags.BIDIRECTIONAL
        );

        var local_filter = new Gtk.StringFilter (new Gtk.PropertyExpression (
            typeof (LocaleData),
            null,
            "country-loc"
        ));
        local_filter.bind_property (
            "search",
            search_entry,
            "text",
            GLib.BindingFlags.BIDIRECTIONAL
        );

        multifilter.append (current_filter);
        multifilter.append (local_filter);

        return multifilter;
    }

    [GtkCallback]
    void show_more_clicked () {
        show_more = true;
    }
}
