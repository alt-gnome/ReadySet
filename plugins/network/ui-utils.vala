/*
 * Copyright (C) 2026 Valery Zabrovsky <brow@altlinux.org>
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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Network/ui/modeled-stack.ui")]
public sealed class Network.ModeledStack : Adw.Bin {

    [GtkChild]
    unowned Gtk.Stack _stack;
    public Gtk.Stack stack {
        get { return _stack; }
    }

    public bool hhomogeneous { get; set; }
    public bool interpolate_size { get; set; }
    public Gtk.SelectionModel pages {
        owned get { return _stack.pages; }
    }
    public uint transition_duration { get; set; }
    public bool transition_running {
        get { return _stack.transition_running; }
    }
    public Gtk.StackTransitionType transition_type { get; set; }
    public bool vhomogeneous { get; set; }
    public Gtk.Widget visible_child { get; set; }
    public string visible_child_name { get; set; }

    public delegate Gtk.Widget WidgetCreateFunc (Object obj);
    public delegate string LabelCreateFunc (Object obj);

    unowned ListModel? model = null;
    WidgetCreateFunc? widget_func;
    LabelCreateFunc? name_func;
    LabelCreateFunc? title_func;

    public void bind_model (
            ListModel? model = null,
            owned WidgetCreateFunc? widget_func = null,
            owned LabelCreateFunc? name_func = null,
            owned LabelCreateFunc? title_func = null
    ) {
        if (this.model != null) {
            this.model.items_changed.disconnect (update_pages);
        }
        this.widget_func = (owned) widget_func;
        this.name_func = (owned) name_func;
        this.title_func = (owned) title_func;
        if ((this.model = model) != null) {
            this.model.items_changed.connect (update_pages);
            update_pages (0, 0, this.model.get_n_items ());
        }
    }

    void update_pages (uint pos, uint removed, uint added) {
        uint idx;

        for (idx = 0; idx < removed; ++idx) {
            _stack.remove (((Gtk.StackPage) _stack.pages.get_item (pos)).child);
        }

        // Save all pages starting from `pos` and remove them...
        var saved_w = new Gtk.Widget[_stack.pages.get_n_items () - pos] {};
        var saved_n = new string[saved_w.length] {};
        var saved_t = new string[saved_w.length] {};
        for (idx = 0; idx < saved_w.length; ++idx) {
            var page = (Gtk.StackPage) _stack.pages.get_item (pos);
            saved_w[idx] = page.child;
            saved_n[idx] = page.name;
            saved_t[idx] = page.title;
            _stack.remove (page.child);
        }

        for (idx = pos, added += pos; idx < added; ++idx) {
            Object obj = model.get_item (idx);

            var widget = (widget_func != null)
                ? widget_func (obj)
                : (obj as Gtk.Widget);
            return_if_fail (widget != null);

            string name = (name_func != null) ? name_func (obj) : null;
            string title = (title_func != null) ? title_func (obj) : null;
            _stack.add_titled (widget, name, title);
        }

        // ...and restore them after new ones so the order is consistent
        for (idx = 0; idx < saved_w.length; ++idx) {
            _stack.add_titled (saved_w[idx], saved_n[idx], saved_t[idx]);
        }
    }
}

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Network/ui/dd-stackswitcher.ui")]
public sealed class Network.DropDownStackSwitcher : Adw.Bin {

    [GtkChild]
    unowned Gtk.DropDown dd;

    unowned Gtk.Stack? _stack = null;
    public Gtk.Stack? stack {
        get {
            return _stack;
        }
        set {
            if (dd.model != null) {
                dd.model.items_changed.disconnect (set_sensitivity);
            }
            if ((_stack = value) == null) {
                dd.model = null;
            } else {
                dd.model = _stack.pages;
                dd.model.items_changed.connect (set_sensitivity);
            }
            set_sensitivity ();
        }
    }

    construct {
        dd.expression = new Gtk.PropertyExpression (
            typeof (Gtk.StackPage), null, "title"
        );
        set_sensitivity ();
    }

    void set_sensitivity () {
        sensitive = dd.model != null && dd.model.get_n_items () > 1;
    }

    [GtkCallback]
    void change_selection () {
        var page = (Gtk.StackPage) dd.selected_item;
        if (page != null) {
            stack.visible_child = page.child;
        }
    }
}

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Network/ui/combo-stackswitcher.ui")]
public sealed class Network.ComboRowStackSwitcher : Case.ComboRow {

    new ListModel? model { private get; }

    unowned Gtk.Stack? _stack = null;
    public Gtk.Stack stack {
        get {
            return _stack;
        }
        set {
            _stack = value;
            base.model = _stack?.pages;
        }
    }

    construct {
        expression = new Gtk.PropertyExpression (
            typeof (Gtk.StackPage), null, "title"
        );
    }

    [GtkCallback]
    void change_selection () {
        var page = (Gtk.StackPage) selected_item;
        if (page != null) {
            stack.visible_child = page.child;
        }
    }
}
