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
    unowned PagesIndicator pages_indicator;
    [GtkChild]
    unowned Adw.HeaderBar header_bar;
    [GtkChild]
    unowned Gtk.Label idle_label_left;
    [GtkChild]
    unowned Gtk.Label idle_label_right;
    [GtkChild]
    unowned Gtk.Button context_button;

    Devel.Window devel_window;

    static uint saved_last_position = 0;

    public string continue_state { get; set; default = "continue"; }

    public bool show_steps_list { get; set; }

    public bool is_ready_to_continue { get; set; }

    public bool dead_end { get; set; default = false; }

    public bool can_up { get; set; }

    BaseBarePage last_current_page;

    public BaseBarePage current_page {
        get {
            return (BaseBarePage) model.get_selected_item ();
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
                continue_state = "finish";

            } else {
                continue_state = "continue";
            }
        }
    }

    public bool can_cancel { get; set; }

    public Gtk.SingleSelection model { get; set; }

    construct {
        model = new Gtk.SingleSelection (new ListStore (typeof (BaseBarePage)));

        pages_indicator.model = model;
        positioned_stack.bind_model (model, (page, pos) => {
            if (pos <= saved_last_position) {
                page.passed = true;
            }

            return page;
        });

        model.selection_changed.connect (selection_changed);

        header_bar.show_end_title_buttons = Config.IS_DEVEL;
        context_button.visible = Config.IS_DEVEL;
        idle_label_left.visible = ReadySet.Application.get_default ().context.idle && Config.IS_DEVEL;
        idle_label_right.visible = ReadySet.Application.get_default ().context.idle && !Config.IS_DEVEL;
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
        update_scroll ();

        if (saved_last_position < position) {
            saved_last_position = position;
        }

        if (last_current_page != null) {
            last_current_page.notify["is-ready"].connect (update_buttons);
        }

        last_current_page = current_page;
        last_current_page.notify["is-ready"].connect (update_buttons);
        last_current_page.notify["scroll-on-top"].connect (update_scroll);

        current_page.passed = true;
    }

    void update_scroll () {
        can_up = !current_page.scroll_on_top;
    }

    void update_buttons () {
        is_ready_to_continue = current_is_ready_to_continue;
        is_ready_to_finish = model.get_selected () == model.get_n_items () - 1;
        can_cancel = model.get_selected () > 0 && !dead_end;
    }

    public void add_page (BaseBarePage page) {
        page.hexpand = true;
        ((ListStore) model.get_model ()).append (page);
    }

    [GtkCallback]
    void on_context_button_clicked () {
        if (devel_window == null) {
            devel_window = new Devel.Window ();
            devel_window.close_request.connect (() => {
                devel_window = null;
                return false;
            });
        }

        devel_window.present ();
    }

    [GtkCallback]
    void up_clicked () {
        current_page.to_up ();
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
