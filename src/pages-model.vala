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

public sealed class ReadySet.PageInfo : Object {

    public string id { get; default = Uuid.string_random (); }

    public BaseBarePage page { get; construct; }

    public Addin? plugin { get; construct; }

    public bool apply_plugin { get; construct; }

    public bool accessible { get; private set; }

    public bool is_ready { get; set; }

    public bool passed { get; set; }

    public string title_header { get; set; }

    public string icon_name { get; set; }

    public PageInfo (BaseBarePage page, Addin? plugin, bool apply_plugin = true) {
        Object (
            page: page,
            plugin: plugin,
            apply_plugin: apply_plugin
        );
    }

    construct {
        string[] props = {
            "is-ready",
            "passed",
            "title-header",
            "icon-name"
        };

        foreach (var prop in props) {
            page.bind_property (prop, this, prop, BIDIRECTIONAL | SYNC_CREATE);
        }

        page.notify["accessible"].connect (update_accessible);
        if (plugin != null) {
            plugin.notify["accessible"].connect (update_accessible);
        }
        update_accessible ();
    }

    void update_accessible () {
        if (plugin != null) {
            accessible = plugin.accessible && page.accessible;
        } else {
            accessible = page.accessible;
        }
    }
}

public sealed class ReadySet.PagesModel : Object, ListModel, Gtk.SelectionModel {

    Gtk.SingleSelection real_model;
    Gtk.Filter filter;

    public signal void changed (uint position, uint removed, uint added, uint selection_position);

    construct {
        filter = new Gtk.BoolFilter (new Gtk.PropertyExpression (
            typeof (PageInfo),
            null,
            "accessible"
        ));
        real_model = new Gtk.SingleSelection (null);

        real_model.selection_changed.connect (on_real_model_selection_changed);
        real_model.items_changed.connect (on_real_model_items_changed);

        unselect_all ();
    }

    void on_real_model_selection_changed (uint position, uint n_items) {
        selection_changed (position, n_items);
    }

    void on_real_model_items_changed (uint position, uint removed, uint added) {
        uint new_selection_position = get_selected ();

        //  Calculate selection offset
        if (position <= new_selection_position) {
            if (removed > new_selection_position - position) {
                new_selection_position = position > 0 ? position - 1 : 0;
            } else {
                new_selection_position -= removed;
            }
        }

        select_item (new_selection_position, true);
        items_changed (position, removed, added);
    }

    public void set_pages (PageInfo[] pages) {
        uint removed = 0;
        if (real_model != null) {
            removed = real_model.n_items;
        }

        var store = new ListStore (typeof (PageInfo));
        foreach (var page in pages) {
            store.append (page);

            page.notify["accessible"].connect (() => {
                filter.changed (Gtk.FilterChange.DIFFERENT);
            });
        }

        real_model.model = new Gtk.FilterListModel (
            store, filter
        );
    }

    public unowned PageInfo? get_selected_item () {
        return (PageInfo?) real_model.get_selected_item ();
    }

    public uint get_selected () {
        return real_model.get_selected ();
    }

    public Gtk.Bitset get_selection_in_range (uint position, uint n_items) {
        return real_model.get_selection_in_range (position, n_items);
    }

    public bool is_selected (uint position) {
        return real_model.is_selected (position);
    }

    public bool select_all () {
        return select_item (0, true);
    }

    public bool select_item (uint position, bool unselect_rest) {
        var res = real_model.select_item (position, true);
        if (get_n_items () > 0) {
            selection_changed (position, 1);
        } else {
        }
        return res;
    }

    public bool select_range (uint position, uint n_items, bool unselect_rest) {
        return select_item (position, unselect_rest);
    }

    public bool set_selection (Gtk.Bitset selected, Gtk.Bitset mask) {
        assert_not_reached ();
    }

    public bool unselect_all () {
        return select_all ();
    }

    public bool unselect_item (uint position) {
        return unselect_all ();
    }

    public bool unselect_range (uint position, uint n_items) {
        assert_not_reached ();
    }

    public GLib.Object? get_item (uint position) {
        return real_model.get_item (position);
    }

    public GLib.Type get_item_type () {
        return real_model.get_item_type ();
    }

    public uint get_n_items () {
        return real_model.get_n_items ();
    }
}
