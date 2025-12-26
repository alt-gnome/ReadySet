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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Language/ui/box.ui")]
public sealed class Language.Box : Adw.Bin {

    [GtkChild]
    unowned Gtk.ListBox languages_listbox;
    [GtkChild]
    unowned Gtk.SearchEntry search_entry;

    public LocaleData current_locale { get; set; default = new LocaleData (get_current_language ()); }

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
        typeof (Row).ensure ();
    }

    construct {
        languages_listbox.set_placeholder (
            new Gtk.Label (_("Nothing found")) {
                height_request = 48
            }
        );

        set_supported_languages.begin ();

        search_entry.changed.connect (() => {
            saved_search_query = search_entry.text;
        });

        search_entry.text = saved_search_query;
        show_more = saved_show_more;

        Idle.add_once (() => {
            search_entry.can_focus = true;
        });
    }

    async void set_supported_languages () {
        set_languages ({
            "ru_RU.UTF-8",
            "en_US.UTF-8",
            "fr_FR.UTF-8",
            "es_ES.UTF-8",
            "zh_CN.UTF-8",
            "ja_JP.UTF-8",
        });
    }

    public void show_all_languages () {
        set_languages (Gnome.Languages.get_all_locales (), true);
    }

    void set_languages (string[] language_locales, bool with_sorting = false) {
        var model = new ListStore (typeof (LocaleData));

        LocaleData locale_data;
        foreach (var locale in language_locales) {
            locale_data = new LocaleData (locale);
            if (
                locale_data.country_cur != "" &&
                locale_data.country_cur != "" &&
                locale_data.country_cur != null &&
                locale_data.country_cur != null
            ) {
                model.append (locale_data);
            }
        }

        Gtk.FilterListModel filter_model;
        if (with_sorting) {
            var sort_model = new Gtk.SortListModel (model, get_sorter ());
            filter_model = new Gtk.FilterListModel (sort_model, get_filter ());
        } else {
            filter_model = new Gtk.FilterListModel (model, get_filter ());
        }

        var filter_current_model = new Gtk.FilterListModel (filter_model, get_current_filter ());

        languages_listbox.bind_model (
            filter_current_model,
            (obj) => {
                return new Row ((LocaleData) obj);
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

    Gtk.Filter get_current_filter () {
        return new Gtk.CustomFilter ((item) => {
            return ((LocaleData) item).locale != current_locale.locale;
        });
    }

    [GtkCallback]
    void show_more_clicked () {
        show_more = true;
    }
}
