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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Language/ui/box.ui")]
public sealed class Language.Box : Adw.Bin {

    [GtkChild]
    unowned Gtk.ListBox languages_listbox;
    [GtkChild]
    unowned Gtk.Stack languages_stack;

    public LocaleData current_locale { get; set; default = new LocaleData (Addin.get_instance ().current_locale); }

    static construct {
        typeof (CurrentRow).ensure ();
        typeof (Row).ensure ();
        typeof (ViewRow).ensure ();
    }

    construct {
        set_supported_languages ();
    }

    void set_supported_languages () {
        set_languages ({
            "ru_RU.UTF-8",
            "en_US.UTF-8",
            "fr_FR.UTF-8",
            "es_ES.UTF-8",
            "zh_CN.UTF-8",
            "ja_JP.UTF-8",
        });
    }

    void set_languages (string[] language_locales) {
        var model = build_model_from (language_locales);

        var filter_current_model = new Gtk.FilterListModel (model, get_current_filter ());

        filter_current_model.notify["n-items"].connect (model_n_items_changed);
        model_n_items_changed (filter_current_model, filter_current_model.get_class ().find_property ("n-items"));

        languages_listbox.bind_model (filter_current_model, create_row_func);
    }

    Gtk.Widget create_row_func (Object item) {
        return new Row ((LocaleData) item);
    }

    void model_n_items_changed (Object obj, ParamSpec param) {
        if (((ListModel) obj).get_n_items () > 0) {
            languages_stack.visible_child_name = "languages";
        } else {
            languages_stack.visible_child_name = "nothing-found";
        }
    }

    Gtk.Filter get_current_filter () {
        return new Gtk.CustomFilter (filter_func);
    }

    bool filter_func (Object item) {
        return ((LocaleData) item).locale != current_locale.locale;
    }

    [GtkCallback]
    void show_more_clicked () {
        new LocaleDialog ().present (this);
    }

    [GtkCallback]
    void on_listbox_row_activated (Gtk.ListBoxRow row) {
        var locale_row = (Row) row;
        Addin.get_instance ().current_locale = locale_row.locale_data.locale;
    }
}
