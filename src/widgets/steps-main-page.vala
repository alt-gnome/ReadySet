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

[GtkTemplate (ui = "/space/rirusha/ReadySet/ui/steps-main-page.ui")]
public sealed class ReadySet.StepsMainPage : Adw.Bin {

    [GtkChild]
    unowned Adw.Carousel carousel;
    [GtkChild]
    unowned Gtk.Stack continue_stack;

    public bool show_steps_list { get; set; }

    public bool is_ready_to_continue { get; set; }

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

        model.items_changed.connect ((position, removed, added) => {
            for (int i = 0; i < removed; i++) {
                carousel.remove (carousel.get_nth_page (position));
            }
            for (int i = 0; i < added; i++) {
                var page = (BasePage) model.get_item (position + added - 1);

                if (carousel.n_pages <= ReadySet.Application.get_default ().last_position) {
                    page.passed = true;
                }

                carousel.insert (page, (int) (position + added - 1));
            }

            selection_changed ();
        });

        model.selection_changed.connect (selection_changed);

        carousel.page_changed.connect ((index) => {
            if (ReadySet.Application.get_default ().last_position < carousel.position) {
                ReadySet.Application.get_default ().last_position = (uint) carousel.position;
            }

            model.select_item (index, true);
        });
    }

    void selection_changed () {
        carousel.scroll_to ((BasePage) model.get_selected_item (), true);

        update_buttons ();

        if (last_current_page != null) {
            last_current_page.notify["is-ready"].connect (update_buttons);
        }

        last_current_page = current_page;
        last_current_page.notify["is-ready"].connect (update_buttons);

        current_page.passed = true;
    }

    void update_buttons () {
        is_ready_to_continue = model.get_selected () < model.get_n_items () - 1 && current_is_ready_to_continue;
        is_ready_to_finish = model.get_selected () == model.get_n_items () - 1;
        can_cancel = model.get_selected () > 0;
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
