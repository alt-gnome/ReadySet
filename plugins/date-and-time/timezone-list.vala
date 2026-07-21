/*
 * Copyright (C) 2026 David Sultaniiazov <x1z53@alt-gnome.ru>
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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/DateAndTime/ui/timezone-list.ui")]
public class DateAndTime.TimezoneList : Adw.Dialog {
    [GtkChild]
    unowned Gtk.Stack stack;
    [GtkChild]
    unowned Gtk.FilterListModel filter_list_model;

    public ListStore model { get; set; default = new ListStore (typeof (TimezoneListItem)); }

    Gee.ArrayList<TimezoneListItem> timezones = new Gee.ArrayList<TimezoneListItem> ();
    Gee.ArrayList<string> timezone_metainfos = new Gee.ArrayList<string> ();

    public TimezoneListItem selected_item { get; set; }

    public TimezoneList () {
        var file = File.new_for_path ("/usr/share/zoneinfo/zone1970.tab");
        if (!file.query_exists ()) {
            error ("No timezones list");
        }

        try {
            uint8[] data;
            file.load_contents (null, out data, null);
            var content = (string) data;

            var comment_regex = new Regex ("#.*\n");
            content = comment_regex.replace (content, -1, 0, "", RegexMatchFlags.DEFAULT);

            var entry_regex = new Regex ("([^\t]*)\t[^\t]*\t([^\t\n]*)[^\n]*\n");
            content = entry_regex.replace (content, -1, 0, "\\1 \\2\n", RegexMatchFlags.DEFAULT);

            var entries = content.split ("\n");
            foreach (var entry in entries) {
                if (entry == null || entry == "") {
                    continue;
                }

                var item = new TimezoneListItem (entry);

                timezones.add (item);
                timezone_metainfos.add (item.metainfo);
            }

            var sorted = new Gee.ArrayList<TimezoneListItem> ();
            foreach (var item in timezones) {
                sorted.add (item);
            }

            sorted.sort ((_a, _b) => {
                var a = _a.utc_offset;
                var b = _b.utc_offset;

                if (a > b) return Gtk.Ordering.LARGER;
                if (a < b) return Gtk.Ordering.SMALLER;
                return Gtk.Ordering.EQUAL;
            });

            foreach (var item in sorted) {
                model.append (item);
            }
        } catch (Error e) {
            warning ("Failed to load timezones: %s", e.message);
        }
    }

    [GtkCallback]
    public void on_selected_item_changed () {
        if (selected_item != null) {
            close ();
        }
    }

    [GtkCallback]
    public void on_filter_items_count_changed () {
        stack.visible_child_name = filter_list_model.get_n_items () != 0
            ? "results"
            : "empty";
    }
}
