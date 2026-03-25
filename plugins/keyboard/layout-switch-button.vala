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

public sealed class Keyboard.LayoutSwitchRow : Adw.ComboRow {

    public LayoutSwitchRow () {
        Object ();
    }

    construct {
        notify["selected-item"].connect (on_item_selected);
        var sfactory = new Gtk.SignalListItemFactory ();
        factory = sfactory;

        sfactory.bind.connect (on_bind);

        model = new Adw.EnumListModel (typeof (AdditionalLayoutSwitch));

        var settings = get_input_sources_settings ();
        var current_options = new Gee.ArrayList<string>.wrap (settings.get_strv ("xkb-options"));

        for (int i = 0; i < model.get_n_items (); i++) {
            var s = (AdditionalLayoutSwitch) ((Adw.EnumListItem) model.get_item (i)).value;

            if (s == NONE) {
                continue;
            }

            if (s.to_string () in current_options) {
                set_selected (i);
            }
        }
    }

    void on_bind (Gtk.SignalListItemFactory factory, Object object) {
        var list_item = (Gtk.ListItem) object;
        var item = (Adw.EnumListItem) list_item.item;

        var box = new Gtk.Box (HORIZONTAL, 6);
        list_item.child = box;

        var ls = ((AdditionalLayoutSwitch) item.value);

        if (ls == NONE) {
            box.append (new Gtk.Label (_("None")));

        } else {
            foreach (var b in ls.to_buttons ()) {
                box.append (new Gtk.Label (b) {
                    css_classes = { "keycap" }
                });
            }
        }
    }

    void on_item_selected (Object item, ParamSpec param) {
        var settings = get_input_sources_settings ();
        var current_options = new Gee.ArrayList<string>.wrap (settings.get_strv ("xkb-options"));

        var s = (AdditionalLayoutSwitch) ((Adw.EnumListItem) selected_item).value;

        var current_options_filtered = new Gee.ArrayList<string> ();
        current_options_filtered.add_all_iterator (current_options.filter ((el) => {
            return !el.has_prefix ("grp:");
        }));

        if (s != NONE) {
            current_options_filtered.add (s.to_string ());
            settings.set_strv ("xkb-options", current_options_filtered.to_array ().copy ());
        } else {
            settings.set_strv ("xkb-options", current_options_filtered.to_array ().copy ());
        }
    }
}
