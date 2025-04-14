/*
 * Copyright (C) 2025 Vladimir Vaskov <rirusha@altlinux.org>
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

    public delegate Gtk.Widget CreateFunc (BasePage page, int pos);

    public int position {
        get {
            return childs.index_of (stack.get_page (stack.visible_child));
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

            stack.set_visible_child_full (childs[(int) value].name, tt);
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

    public Gtk.SingleSelection model { get; private set; }

    weak CreateFunc create_func;
    Gtk.Stack stack = new Gtk.Stack ();

    new Gee.ArrayList<Gtk.StackPage> childs = new Gee.ArrayList<Gtk.StackPage> ();

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

    public void bind_model (Gtk.SingleSelection model, owned CreateFunc create_func) {
        clear ();

        this.model = model;
        this.create_func = create_func;

        this.model.selection_changed.connect (on_selection_changed);
        this.model.items_changed.connect (on_items_changed);

        update ();
    }

    void remove_page (Gtk.Widget widget) {
        var page = stack.get_page (widget);

        stack.remove (page.child);
        childs.remove (page);
    }

    void add_page (Gtk.Widget widget, string? title = null) {
        var page = stack.add_titled (widget, Uuid.string_random (), title ?? "UNKNOWN");
        childs.add (page);
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

    void on_items_changed () {
        update ();
    }

    void update () {
        light_clear ();

        for (int i = 0; i < model.n_items; i++) {
            var page = (BasePage) model.get_item (i);

            add_page (
                create_func (page, i),
                page.title
            );
        }

        if (model.n_items > 0) {
            model.selection_changed (0, model.n_items);
        }
    }
}
