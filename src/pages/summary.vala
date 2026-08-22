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

[GtkTemplate (ui = "/org/altlinux/ReadySet/ui/summary-page.ui")]
public sealed class ReadySet.SummaryPage : ReadySet.BasePage {

    [GtkChild]
    unowned Gtk.ListBox list_box;

    PagesModel _model;
    public PagesModel model {
        get {
            return _model;
        }
        set {
            if (_model != null) {
                _model.items_changed.disconnect (update);
            }

            _model = value;

            if (_model != null) {
                _model.items_changed.connect (update);
                update ();
            }
        }
    }

    public Context context { get; construct; }

    public SummaryPage (Context context) {
        Object (context: context);
    }

    construct {
        Application.get_default ().bind_property (
            "model",
            this,
            "model",
            SYNC_CREATE
        );
        context.data_changed.connect (update);
    }

    void update () {
        list_box.remove_all ();

        for (int i = 0; i < model.get_n_items (); i++) {
            var page_info = (PageInfo) model.get_item (i);

            if (page_info.page is HasWidgetRepr || page_info.page is HasStringRepr) {
                list_box.append (
                    new PageStateRow (page_info) {
                        activatable = true
                    }
                );
            }
        }

        accessible = list_box.get_first_child () != null;
    }

    [GtkCallback]
    void on_listbox_row_activated (Gtk.ListBoxRow? row) {
        if (row == null) {
            return;
        }

        var state_row = row as PageStateRow;
        if (state_row == null) {
            return;
        }

        model.select (state_row.info);
    }
}
