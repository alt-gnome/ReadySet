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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Keyboard/ui/current-input-row.ui")]
public sealed class Keyboard.CurrentInputRow : Adw.ActionRow {

    InputInfo _input_info;
    public InputInfo input_info {
        get {
            return _input_info;
        }
        construct set {
            _input_info = value;
            title = Addin.get_instance ().is_manager.get_humanity_name (_input_info);
        }
    }

    public bool draggable { get; private set; }

    public CurrentInputRow (InputInfo input_info) {
        Object (
            input_info: input_info
        );
    }

    construct {
        Addin.get_instance ().context.data_changed.connect (on_context_data_changed);
        update ();

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

    void on_context_data_changed (string key) {
        if (key == "keyboard.input-sources") {
            update ();
        }
    }

    Gdk.ContentProvider? on_dragsource_prepare (Gtk.DragSource dnd_src, double x, double y) {
        if (!draggable) {
            return null;
        }

        dnd_src.set_icon (new Gtk.WidgetPaintable (this).get_current_image (), (int) x, (int) y);
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
        var dialog = new PreviewDialog (input_info) {
            title = title
        };
        dialog.present (this);
    }

    void update () {
        draggable = get_current_inputs ().size > 1;
    }
}
