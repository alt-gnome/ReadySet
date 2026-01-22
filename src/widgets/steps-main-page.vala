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

    public string continue_state { get; set; default = "continue"; }

    public bool show_steps_list { get; set; }

    public bool is_ready_to_continue { get; set; }

    public bool dead_end { get; set; default = false; }

    public bool can_up { get; set; }

    static Gee.ArrayList<string> passed_pages = new Gee.ArrayList<string> ();

    PageInfo last_current_page;

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

    public PagesModel model { get; construct; }

    construct {
        model = Application.get_default ().model;

        pages_indicator.model = model;
        positioned_stack.bind_manager (model, (page) => {
            if (page.id in passed_pages) {
                page.passed = true;
            }

            return page.page;
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
            var page_info = (PageInfo) model.get_item (n_items - 1);
            var end_page = page_info.page as EndPage;
            if (end_page != null) {
                show_steps_list = false;
                dead_end = true;

                end_page.start_action.begin ();
            };
        }

        update_buttons ();
        update_scroll ();

        if (last_current_page != null) {
            last_current_page.notify["is-ready"].connect (update_buttons);
        }

        last_current_page = model.get_selected_item ();
        last_current_page.notify["is-ready"].connect (update_buttons);
        last_current_page.notify["scroll-on-top"].connect (update_scroll);

        passed_pages.add (last_current_page.id);
        last_current_page.passed = true;
    }

    void update_scroll () {
        can_up = !model.get_selected_item ().page.scroll_on_top;
    }

    void update_buttons () {
        is_ready_to_continue = model.get_selected_item ().is_ready;
        is_ready_to_finish = model.get_selected () == model.get_n_items () - 1;
        can_cancel = model.get_selected () > 0 && !dead_end;
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
        model.get_selected_item ().page.to_up ();
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
