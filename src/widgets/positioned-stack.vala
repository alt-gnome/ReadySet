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

public class ReadySet.PositionedStack : Adw.Bin {

    public uint position {
        get {
            var name = stack.visible_child_name;
            for (uint i = 0; i < stack.pages.get_n_items (); i++) {
                if (get_page (i).name == name) {
                    return i;
                }
            }
            return -1;
        }
        set {
            if (stack.pages.get_n_items () == 0) {
                return;
            }

            value = value.clamp (0, stack.pages.get_n_items () - 1);

            stack.visible_child_name = get_page (value).name;
        }
    }

    public Gtk.Widget visible_child {
        get {
            return stack.visible_child;
        }
        set {
            stack.set_visible_child (value);
        }
    }

    public uint n_items {
        get {
            return stack.pages.get_n_items ();
        }
    }

    public bool hhomogeneous { get; set; default = false; }

    public bool vhomogeneous { get; set; default = false; }

    public Gtk.StackTransitionType transition_type { get; set; default = Gtk.StackTransitionType.NONE; }

    public PagesModel? model { get; private set; }

    weak CreateFunc create_func;
    Gtk.Stack stack = new Gtk.Stack ();

    construct {
        child = stack;

        bind_property (
            "transition-type",
            stack,
            "transition-type",
            GLib.BindingFlags.SYNC_CREATE
        );

        bind_property (
            "hhomogeneous",
            stack,
            "hhomogeneous",
            BindingFlags.SYNC_CREATE
        );

        bind_property (
            "vhomogeneous",
            stack,
            "vhomogeneous",
            BindingFlags.SYNC_CREATE
        );

        stack.notify["visible-child"].connect (visible_child_changed);
    }

    Gtk.StackPage get_page (uint position) {
        return (Gtk.StackPage) stack.pages.get_item (position);
    } 

    void visible_child_changed () {
        notify_property ("position");
        notify_property ("visible-child");
    }

    public void bind_model (PagesModel? model, owned CreateFunc create_func) {
        if (this.model != null) {
            this.model.selection_changed.disconnect (on_selection_changed);
            this.model.items_changed.disconnect (on_items_changed);

            this.model = null;
            clear ();
        }

        this.model = model;
        this.create_func = create_func;

        if (model != null) {
            model.selection_changed.connect (on_selection_changed);
            model.items_changed.connect (on_items_changed);
            fill ();
        }
    }

    public void clear () {
        var pages_names = new Array<string> ();

        for (uint i = 0; i < stack.pages.get_n_items (); i++) {
            pages_names.append_val (get_page (i).name);
        }

        foreach (var name in pages_names) {
            remove_page (name);
        }
    }

    void on_selection_changed (uint position, uint n_items) {
        this.position = (int) model.get_selected ();
    }

    void on_items_changed (uint position, uint removed, uint added) {
        if (removed > 0 && added > 0) {
            clear ();
            fill ();
            return;
        }

        if (removed > 0) {
            for (uint i = position; i < removed; i++) {
                remove_page (get_page (position).name);
            }
        }

        if (added > 0) {
            Gee.ArrayList<PageInfo> tail = new Gee.ArrayList<PageInfo> ();

            for (uint i = position; i < stack.pages.get_n_items (); i++) {
                var id = get_page (i).name;
                tail.add (find_page_info (id));
                remove_page (id);
            }

            for (uint i = position; i < added; i++) {
                var page = (PageInfo) model.get_item (position + i);
                add_page (page);
            }

            foreach (var page in tail) {
                add_page (page);
            }
        }
    }

    void remove_page (string id) {
        var child = stack.get_child_by_name (id);
        if (child != null) {
            stack.remove (stack.get_child_by_name (id));
        }
    }

    void add_page (PageInfo page_info) {
        var widget = create_func (page_info);

        if (widget.get_parent () != null) {
            widget.unparent ();
        }

        stack.add_titled (
            widget,
            page_info.id,
            page_info.title_header ?? "UNKNOWN"
        );
    }

    PageInfo find_page_info (string id) {
        for (uint i = position; i < model.get_n_items (); i++) {
            var page = (PageInfo) model.get_item (i);
            if (page.id == id) {
                return page;
            }
        }

        error ("What?");
    }

    void fill () {
        for (uint i = 0; i < model.get_n_items (); i++) {
            add_page ((PageInfo) model.get_item (i));
        }
        on_selection_changed (model.get_selected (), 1);
    }
}
