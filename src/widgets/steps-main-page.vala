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

[GtkTemplate (ui = "/org/altlinux/ReadySet/ui/steps-main-page.ui")]
public sealed class ReadySet.StepsMainPage : Adw.Bin {

    [GtkChild]
    unowned PositionedStack positioned_stack;
    [GtkChild]
    unowned Gtk.Stack continue_stack;
    [GtkChild]
    unowned Gtk.Box button_box;
    [GtkChild]
    unowned PagesIndicator pages_indicator;

    static uint saved_last_position = 0;

    bool _centerize_buttons = false;
    public bool centerize_buttons {
        get {
            return _centerize_buttons;
        }
        set {
            _centerize_buttons = value;

            button_box.halign = _centerize_buttons ? Gtk.Align.CENTER : Gtk.Align.END;
        }
    }

    public bool show_steps_list { get; set; }

    public bool is_ready_to_continue { get; set; }

    public bool dead_end { get; set; default = false; }

    BasePage last_current_page;

    public BasePage current_page {
        get {
            return (BasePage) model.get_selected_item ();
        }
    }

    bool current_is_ready_to_continue {
        get {
            return current_page.is_ready;
        }
    }

    bool _is_ready_to_finish = false;
    public bool is_ready_to_finish {
        get {
            return _is_ready_to_finish;
        }
        set {
            _is_ready_to_finish = value;

            if (_is_ready_to_finish) {
                continue_stack.visible_child_name = "finish";

            } else {
                continue_stack.visible_child_name = "continue";
            }
        }
    }

    public bool can_cancel { get; set; }

    public Gtk.SingleSelection model { get; set; }

    construct {
        model = new Gtk.SingleSelection (new ListStore (typeof (BasePage)));

        pages_indicator.model = model;
        positioned_stack.bind_model (model, (page, pos) => {
            if (pos <= saved_last_position) {
                page.passed = true;
            }

            return page;
        });

        model.selection_changed.connect (selection_changed);
    }

    void selection_changed () {
        var position = model.get_selected ();
        var n_items = model.get_n_items ();

        if (position == n_items - 1) {
            var end_page = model.get_item (n_items - 1) as EndPage;
            if (end_page != null) {
                show_steps_list = false;
                dead_end = true;

                end_page.start_action.begin ();
            };
        }

        update_buttons ();

        if (saved_last_position < position) {
            saved_last_position = position;
        }

        if (last_current_page != null) {
            last_current_page.notify["is-ready"].connect (update_buttons);
        }

        last_current_page = current_page;
        last_current_page.notify["is-ready"].connect (update_buttons);

        current_page.passed = true;
    }

    void update_buttons () {
        is_ready_to_continue = current_is_ready_to_continue;
        is_ready_to_finish = model.get_selected () == model.get_n_items () - 1;
        can_cancel = model.get_selected () > 0 && !dead_end;
    }

    public void add_page (BasePage page) {
        page.hexpand = true;
        ((ListStore) model.get_model ()).append (page);
    }

    [GtkCallback]
    void cancel_clicked () {
        model.select_item (model.get_selected () - 1, true);
    }

    [GtkCallback]
    void continue_clicked () {
        model.select_item (model.get_selected () + 1, true);
    }

    [GtkCallback]
    void finish_clicked () {
        GLib.Application.get_default ().quit ();
    }
}
