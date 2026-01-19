/*
 * Copyright (C) 2025 Vladimir Romanov <rirusha@altlinux.org>
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

[GtkTemplate (ui = "/org/altlinux/ReadySet/ui/steps-sidebar.ui")]
public sealed class ReadySet.StepsSidebar : Adw.Bin {

    [GtkChild]
    unowned Gtk.ListBox menu_list_box;

    public bool show_close_button { get; set; }

    public Gtk.SingleSelection model { get; set; }

    public signal void request_close ();

    construct {
        notify["model"].connect (update_model);

        menu_list_box.selected_rows_changed.connect (() => {
            var row = menu_list_box.get_selected_row ();
            if (row != null) {
                model.select_item (row.get_index (), true);
            }
            update_selection ();
        });
    }

    void update_model () {
        menu_list_box.bind_model (model, (item) => {
            var page = (BaseBarePage) item;

            var row = new StepRow (
                page.title_header,
                page.icon_name
            );

            page.bind_property (
                "passed",
                row,
                "sensitive",
                BindingFlags.SYNC_CREATE
            );

            return row;
        });

        model.items_changed.connect (update_selection);
        model.selection_changed.connect (update_selection);
        update_selection ();
    }

    void update_selection () {
        menu_list_box.select_row (menu_list_box.get_row_at_index ((int) model.get_selected ()));
    }

    [GtkCallback]
    void request_close_sidebar () {
        if (show_close_button) {
            request_close ();
        }
    }
}
