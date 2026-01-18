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
            Adw.PreferencesRow row;

            var value_type = context.get_value_type (key);

            switch (value_type) {
                case STRING:
                    var erow = new Adw.EntryRow () {
                        title = key,
                        text = context.get_string (key) ?? "",
                        show_apply_button = true,
                    };
                    erow.apply.connect (row_apply_string);
                    erow.activate.connect (() => {
                        row_apply_string (erow);
                    });
                    row = erow;
                    break;

                case BOOLEAN:
                    var srow = new Adw.SwitchRow () {
                        title = key,
                        active = context.get_boolean (key),
                    };
                    srow.notify["active"].connect (() => {
                        row_apply_boolean (srow);
                    });
                    row = srow;
                    break;

                case STRV:
                    var erow = new Adw.EntryRow () {
                        title = key,
                        text = string.joinv (",", context.get_strv (key)),
                        show_apply_button = true,
                    };
                    erow.apply.connect (row_apply_strv);
                    erow.activate.connect (() => {
                        row_apply_strv (erow);
                    });
                    row = erow;
                    break;

                case INT:
                    var erow = new Adw.EntryRow () {
                        title = key,
                        text = context.get_int (key).to_string (),
                        show_apply_button = true,
                    };
                    erow.apply.connect (row_apply_int);
                    erow.activate.connect (() => {
                        row_apply_int (erow);
                    });
                    row = erow;
                    break;

                case DOUBLE:
                    var erow = new Adw.EntryRow () {
                        title = key,
                        text = context.get_double (key).to_string (),
                        show_apply_button = true,
                    };
                    erow.apply.connect (row_apply_double);
                    erow.activate.connect (() => {
                        row_apply_double (erow);
                    });
                    row = erow;
                    break;

                default:
                    assert_not_reached ();
            }

            list_box.append (row);
        }
    }

    void row_apply_double (Adw.EntryRow row) {
        double res;
        if (double.try_parse (row.text, out res)) {
            context.set_double (row.title, res);
            row.remove_css_class ("error");
        } else {
            row.add_css_class ("error");
        }
    }

    void row_apply_int (Adw.EntryRow row) {
        int res;
        if (int.try_parse (row.text, out res)) {
            context.set_int (row.title, res);
            row.remove_css_class ("error");
        } else {
            row.add_css_class ("error");
        }
    }

    void row_apply_strv (Adw.EntryRow row) {
        context.set_strv (row.title, row.text.split (","));
    }

    void row_apply_string (Adw.EntryRow row) {
        context.set_string (row.title, row.text);
    }

    void row_apply_boolean (Adw.SwitchRow row) {
        context.set_boolean (row.title, row.active);
    }
}
