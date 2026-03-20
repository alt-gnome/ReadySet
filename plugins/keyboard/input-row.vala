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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Keyboard/ui/input-row.ui")]
public sealed class Keyboard.InputRow : Adw.ActionRow {

    public InputInfo input_info { get; construct; }

    public bool is_extra { get; construct set; }

    public new bool is_selected { get; set; }

    public bool draggable { get; construct; }

    public InputRow (InputInfo input_info, string name, bool is_extra = false, bool draggable = false) {
        Object (
            input_info: input_info,
            title: name,
            is_extra: is_extra,
            draggable: draggable
        );
    }

    construct {
        if (draggable) {
            var drag_src = new Gtk.DragSource ();
            var drop_trg = new Gtk.DropTarget (typeof (InputInfo), MOVE);

            drag_src.actions = MOVE;

            drag_src.prepare.connect (on_dragsource_prepare);
            drag_src.drag_begin.connect (on_dragsource_drag_begin);
            drag_src.drag_end.connect (on_dragsource_drag_end);

            drop_trg.drop.connect (on_droptarget_drop);

            add_controller (drag_src);
            add_controller (drop_trg);
        }
    }

    Gdk.ContentProvider? on_dragsource_prepare (Gtk.DragSource dnd_src, double x, double y) {
        dnd_src.set_icon (paintable (), (int) x, (int) y);
        return new Gdk.ContentProvider.for_value (input_info);
    }

    void on_dragsource_drag_begin (Gtk.DragSource dnd_src, Gdk.Drag drag) {
        add_css_class ("view");
    }

    void on_dragsource_drag_end (Gtk.DragSource dnd_src, Gdk.Drag drag, bool delete_data) {
        remove_css_class ("view");
    }

    bool on_droptarget_drop (Gtk.DropTarget drop_trg, Value value, double x, double y) {
        var where = input_info;
        var what = (InputInfo) value.get_object ();

        var cu = get_current_inputs ();
        cu.insert_before (what, where);

        set_current_inputs (cu);
        return true;
    }

    [GtkCallback]
    void on_preview_clicked () {
        var current_inputs = get_current_inputs ();
        set_user_inputs ({input_info});

        var dialog = new PreviewDialog ();

        dialog.title = title;
        dialog.present (this);
        dialog.closed.connect (() => {
            set_user_inputs (current_inputs.to_array ());
        });
    }

    Gdk.Paintable paintable () {
        var sshot = new Gtk.Snapshot ();
        snapshot (sshot);
        var node = sshot.to_node ();

        Graphene.Rect bounds;
        compute_bounds (this, out bounds);

        var s2shot = new Gtk.Snapshot ();
        s2shot.append_node (node);
        s2shot.render_background (get_style_context (), 0, 0, bounds.get_width (), bounds.get_height ());

        return s2shot.to_paintable (null);
    }
}
