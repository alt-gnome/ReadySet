/*
 * Copyright (C) 2026 David Sultaniiazov <x1z53@alt-gnome.ru>
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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/DateAndTime/ui/infinity-carousel.ui")]
public class DateAndTime.InfinityCarousel : Gtk.Box {
    [GtkChild]
    unowned Case.InfinityCarousel carousel;

    public new uint spacing {
        get { return carousel.spacing; }
        set { carousel.spacing = value; }
    }

    public bool infinite {
        get { return carousel.infinite; }
        set { carousel.infinite = value; }
    }

    public bool full_page {
        get { return carousel.full_page; }
        set { carousel.full_page = value; }
    }

    public Gtk.SingleSelection? model {
        get { return carousel.model; }
        set { carousel.model = value; }
    }

    public signal Gtk.Widget create (Object item);
    public signal void page_changed (uint index);
    public signal void item_pressed ();

    construct {
        carousel.create.connect ((item) => {
            return create (item);
        });
        carousel.page_changed.connect ((index) => {
            page_changed (index);
        });
    }

    [GtkCallback]
    public void on_previous_button_clicked () {
        carousel.scroll_to_prev ();
    }

    [GtkCallback]
    public void on_next_button_clicked () {
        carousel.scroll_to_next ();
    }

    [GtkCallback]
    public void on_items_pressed (int n_press, double x, double y) {
        if (y < 0 || y > carousel.get_height () || x < 0 || x > carousel.get_width ()) {
            return;
        }
        item_pressed ();
    }

    public void scroll_to (uint index, bool animate = true) {
        carousel.scroll_to (index, animate);
    }

    public Gtk.Widget? get_nth_page (uint index) {
        return carousel.get_nth_page (index);
    }

    public uint get_n_pages () {
        return carousel.get_n_pages ();
    }
}
