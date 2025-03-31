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

[GtkTemplate (ui = "/space/rirusha/ReadySet/ui/carousel-page-titles.ui")]
public sealed class ReadySet.CarouselPageTitles : Adw.Bin {

    [GtkChild]
    unowned Gtk.Overlay overlay;

    Gee.ArrayList<Gtk.Label> titles { get; set; default = new Gee.ArrayList<Gtk.Label> (); }

    Adw.Carousel _carousel;
    public Adw.Carousel carousel {
        get {
            return _carousel;
        }
        set {
            if (_carousel != null) {
                _carousel.notify["position"].disconnect (carousel_position_changed);
                _carousel.notify["n-pages"].disconnect (update_titles);
            }

            _carousel = value;

            _carousel.notify["position"].connect (carousel_position_changed);
            _carousel.notify["n-pages"].connect (update_titles);

            update_titles ();
        }
    }

    construct {

    }

    void update_titles () {
        foreach (var title in titles) {
            overlay.remove_overlay (title);
        }
        titles.clear ();

        for (uint i = 0; i < carousel.n_pages; i++) {
            var page = (BasePage) carousel.get_nth_page (i);
            var label = new Gtk.Label (page.title_header) {
                css_classes = { "heading" },
                justify = Gtk.Justification.CENTER,
                hexpand = true,
                halign = Gtk.Align.CENTER,
                opacity = 0.0
            };

            titles.add (label);
            overlay.add_overlay (label);
        }
    }

    void carousel_position_changed () {
        int ai = (int) carousel.position;
        int bi = ai + 1;

        double bv = carousel.position - ai;
        double av = 1.0 - bv;

        if (av == 0.0) {
            foreach (var title in titles) {
                title.opacity = 0.0;
            }
            titles[ai].opacity = 1.0;

        } else {
            titles[ai].opacity = av;
            if (bi < titles.size) {
                titles[bi].opacity = bv;
            }
        }

        for (int i = 0; i < titles.size; i++) {
            if (i != ai && i != bi) {
                titles[i].opacity = 0.0;
            }
        }
    }
}
