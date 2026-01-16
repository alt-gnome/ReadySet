/*
 * Copyright (C) 2026 Vladimir Romanov <rirusha@altlinux.org>
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

[GtkTemplate (ui = "/org/altlinux/ReadySet/ui/devel-window.ui")]
public sealed class ReadySet.Devel.Window : Adw.Window {

    [GtkChild]
    unowned Gtk.ListBox list_box;

    Context context;

    construct {
        context = ReadySet.Application.get_default ().context;
        context.data_changed.connect (() => {
            list_box.remove_all ();
            fill ();
        });
        fill ();

        list_box.set_placeholder (new Gtk.Label ("No Context?"));
    }

    void fill () {
        foreach (var key in context.get_keys ()) {
            var row = new Adw.EntryRow () {
                title = key,
                text = context.get_raw (key),
                show_apply_button = true,
                css_classes = { "property" },
            };
            row.apply.connect (row_apply);
            row.activate.connect ((row) => {
                row_apply ((Adw.EntryRow) row);
            });
            list_box.append (row);
        }
    }

    void row_apply (Adw.EntryRow row) {
        context.set_raw (row.title, row.text);
    }

    [GtkCallback]
    void on_add_button_clicked () {
        var dialog = new Devel.AddContextDialog ();
        dialog.add.connect (() => {
            if (dialog.context_name.strip () != "") {
                context.set_raw (dialog.context_name, dialog.context_value);
                return true;
            } else {
                return false;
            }
        });
        dialog.present (this);
    }
}
