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
            return childs.index_of (stack.visible_child_name);
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

            stack.set_visible_child_full (childs[(int) value], tt);
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

    public PagesModel model { get; private set; }

    weak CreateFunc create_func;
    Gtk.Stack stack = new Gtk.Stack ();

    new Gee.ArrayList<string> childs = new Gee.ArrayList<string> ();

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

    public void bind_manager (PagesModel model, owned CreateFunc create_func) {
        clear ();

        this.model = model;
        this.create_func = create_func;

        this.model.selection_changed.connect (on_selection_changed);
        this.model.items_changed.connect (on_items_changed);

        update ();
    }

    public void clear () {
        if (model != null) {
            model.selection_changed.disconnect (on_selection_changed);
            model.items_changed.disconnect (on_items_changed);

            model = null;
        }

        light_clear ();
    }

    void light_clear () {
        while (stack.get_first_child () != null) {
            stack.remove (stack.get_first_child ());
        }
        childs.clear ();
    }

    void on_selection_changed (uint position, uint n_items) {
        this.position = (int) model.get_selected ();
    }

    void on_items_changed (uint position, uint removed, uint added) {
        //  We need to readd stack tail to simulate inserting
        Gee.ArrayList<StackPageInfo?> readd = new Gee.ArrayList<StackPageInfo?> ();

        for (uint i = 0; i < removed; i++) {
            var name = childs[(int) position];
            stack.remove (stack.get_child_by_name (name));
            childs.remove (name);
        }

        if (position < childs.size) {
            var need_to_remove = new Gee.ArrayList<string> ();
            for (int i = (int) position; i < childs.size; i++) {
                need_to_remove.add (childs[i]);
            }

            foreach (var name in need_to_remove) {
                var page = stack.get_page (stack.get_child_by_name (name));
                readd.add ({
                    page.name,
                    page.title,
                    page.child
                });
                stack.remove (page.child);
                childs.remove (name);
            }
        }

        for (uint i = position; i < position + added; i++) {
            var page = (PageInfo) model.get_item (i);
            var name = Uuid.string_random ();

            add_page ({
                name: name,
                title: page.title_header ?? "UNKNOWN",
                widget: create_func (page)
            });
        }

        foreach (var page_info in readd) {
            add_page ({
                name: page_info.name,
                title: page_info.title,
                widget: page_info.widget
            });
        }
    }

    void add_page (StackPageInfo page_info) {
        stack.add_titled (
            page_info.widget,
            page_info.name,
            page_info.title
        );
        childs.add (page_info.name);
    }

    void update () {
        on_items_changed (0, 0, model.get_n_items ());
    }
}
