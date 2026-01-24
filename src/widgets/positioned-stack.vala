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

public class ReadySet.PositionedStack : Adw.Bin {

    public int position {
        get {
            var name = stack.visible_child_name;
            for (int i = 0; i < childs.size; i++) {
                if (childs[i].id == name) {
                    return i;
                }
            }
            return -1;
        }
        set {
            if (childs.size == 0) {
                return;
            }

            value = value.clamp (0, childs.size - 1);

            Gtk.StackTransitionType tt = transition_type;

            if (tt == Gtk.StackTransitionType.NONE) {
                tt = position > value ? Gtk.StackTransitionType.SLIDE_RIGHT : Gtk.StackTransitionType.SLIDE_LEFT;
            }

            stack.set_visible_child_full (childs[(int) value].id, tt);
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
            return childs.size;
        }
    }

    public bool hhomogeneous { get; set; default = false; }

    public bool vhomogeneous { get; set; default = false; }

    public Gtk.StackTransitionType transition_type { get; set; default = Gtk.StackTransitionType.NONE; }

    public PagesModel? model { get; private set; }

    weak CreateFunc create_func;
    Gtk.Stack stack = new Gtk.Stack ();

    new Gee.ArrayList<PageInfo> childs = new Gee.ArrayList<PageInfo> ((el1, el2) => {
        return str_equal (el1.id, el2.id);
    });

    construct {
        child = stack;

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

        stack.notify["visible-child"].connect (() => {
            notify_property ("position");
            notify_property ("visible-child");
        });
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
            update ();
        }
    }

    public void clear () {
        for (int i = 0; i < childs.size; i++) {
            remove_page (childs[0]);
        }
    }

    void on_selection_changed (uint position, uint n_items) {
        this.position = (int) model.get_selected ();
    }

    void on_items_changed (uint position, uint removed, uint added) {
        //  We need to readd stack tail to simulate inserting
        Gee.ArrayList<PageInfo> readd = new Gee.ArrayList<PageInfo> ();

        message ("%u, %u, %u", position, removed, added);

        info ();

        for (uint i = 0; i < removed; i++) {
            var name = childs[(int) position];
            remove_page (name);
        }

        info ();

        if (position < childs.size && added > 0) {
            for (int i = (int) position; i < childs.size; i++) {
                var page_info = childs[(int) position];
                readd.add (page_info);
                remove_page (page_info);
            }
        }

        info ();

        for (uint i = position; i < position + added; i++) {
            var page = (PageInfo) model.get_item (i);

            add_page (page);
        }

        info ();

        foreach (var page_info in readd) {
            add_page (page_info);
        }

        info ();
    }
 
    void info () {
        message ("Info:");
        var childs_names = new Gee.ArrayList<string> ();
        foreach (var c in childs) {
            childs_names.add (c.id);
        }
        message (string.joinv (", ", childs_names.to_array ()));

        var stack_names = new Gee.ArrayList<string> ();
        var m = stack.pages;
        for (int i = 0; i < m.get_n_items (); i++) {
            stack_names.add (((Gtk.StackPage) m.get_item (i)).name);
        }
        message (string.joinv (", ", stack_names.to_array ()));
    }

    void remove_page (PageInfo page_info) {
        stack.remove (stack.get_child_by_name (page_info.id));
        childs.remove (page_info);
    }

    void add_page (PageInfo page_info) {
        message ("Add %s", page_info.id);
        message ((stack.get_child_by_name (page_info.id) == null).to_string ());
        stack.add_titled (
            create_func (page_info),
            page_info.id,
            page_info.title_header ?? "UNKNOWN"
        );
        childs.add (page_info);
    }

    void update () {
        on_items_changed (0, 0, model.get_n_items ());
    }
}
