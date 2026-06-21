/*
 * Copyright (C) 2024-2026 Vladimir Romanov <rirusha@altlinux.org>
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see
 * <https://www.gnu.org/licenses/gpl-3.0-standalone.html>.
 * 
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Language/ui/locale-dialog.ui")]
public sealed class Language.LocaleDialog : Adw.Dialog {

    [GtkChild]
    unowned Gtk.ListView view;
    [GtkChild]
    unowned Gtk.SearchEntry search_entry;

    Gtk.NoSelection model;

    Gtk.Filter current_filter;

    construct {
        current_filter = new Gtk.CustomFilter (current_match_func);

        var filter = new Gtk.EveryFilter ();
        var filter_model = new Gtk.FilterListModel (
            build_model_from (Gnome.Languages.get_all_locales ()),
            build_filter ()
        );
        var sort_model = new Gtk.SortListModel (filter_model, build_sorter ());
        model = new Gtk.NoSelection (sort_model);

        view.model = model;

        map.connect (set_search_focus);
    }

    void set_search_focus () {
        search_entry.grab_focus ();
    }

    bool current_match_func (Object el) {
        var locale_data = (LocaleData) el;

        return locale_data.locale != Addin.get_instance ().current_locale;
    }

    Gtk.Sorter build_sorter () {
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

    Gtk.Filter build_filter () {
        var filter = new Gtk.EveryFilter ();

        var country_current_filter = new Gtk.StringFilter (new Gtk.PropertyExpression (
            typeof (LocaleData),
            null,
            "country-cur"
        ));
        search_entry.bind_property (
            "text",
            country_current_filter,
            "search",
            GLib.BindingFlags.SYNC_CREATE
        );

        var country_local_filter = new Gtk.StringFilter (new Gtk.PropertyExpression (
            typeof (LocaleData),
            null,
            "country-loc"
        ));
        search_entry.bind_property (
            "text",
            country_local_filter,
            "search",
            GLib.BindingFlags.SYNC_CREATE
        );

        filter.append (current_filter);
        filter.append (country_current_filter);
        filter.append (country_local_filter);

        return filter;
    }

    [GtkCallback]
    void on_listview_activate (uint position) {
        var locale_data = (LocaleData?) model.get_object (position);

        if (locale_data == null) {
            return;
        }

        Addin.get_instance ().current_locale = locale_data.locale;
        close ();
    }
}
