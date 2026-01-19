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

[GtkTemplate (ui = "/org/altlinux/ReadySet/ui/pages-indicator.ui")]
public sealed class ReadySet.PagesIndicator : Gtk.Box {

    [GtkChild]
    unowned Gtk.Box icons_box;
    [GtkChild]
    unowned PositionedStack positioned_stack;

    const int DEFAULT_PIXEL_SIZE = 13;
    const int CURRENT_PIXEL_SIZE = 16;

    public Gtk.SingleSelection model {
        get {
            return positioned_stack.model;
        }
        set {
            if (model != null) {
                model.selection_changed.disconnect (on_selection_changed);
                model.items_changed.disconnect (on_items_changed);
            }

            if (value != null) {
                positioned_stack.bind_model (value, (page) => {
                    return new Gtk.Label (page.title_header) {
                        css_classes = { "heading" }
                    };
                });

                model.selection_changed.connect (on_selection_changed);
                model.items_changed.connect (on_items_changed);
            }
        }
    }

    public bool show_icons { get; set; default = true; }

    Gee.ArrayList<Gtk.Image> indicators = new Gee.ArrayList<Gtk.Image> ();

    Gtk.Image last_image;

    construct {
        icons_box.height_request = CURRENT_PIXEL_SIZE;
    }

    void on_selection_changed () {
        if (model.get_selected () >= indicators.size) {
            return;
        }

        if (last_image != null) {
            indicator_not_selected (last_image);
        }

        last_image = indicators[(int) model.get_selected ()];

        indicator_selected (last_image);
    }

    void on_items_changed (uint position, uint removed, uint added) {
        update ();
    }

    void update () {
        light_clear ();

        for (int i = 0; i < model.n_items; i++) {
            var page = (BaseBarePage) model.get_item (i);

            var img = new Gtk.Image.from_icon_name (page.icon_name) {
                valign = Gtk.Align.CENTER
            };
            indicator_not_selected (img);

            indicators.add (img);
            icons_box.append (img);
        }
    }

    void light_clear () {
        while (icons_box.get_first_child () != null) {
            icons_box.remove (icons_box.get_first_child ());
        }
        indicators.clear ();
    }

    void indicator_selected (Gtk.Image img) {
        animate_img (img, 0.5, 1.0);
    }

    void indicator_not_selected (Gtk.Image img) {
        animate_img (img, 1.0, 0.5);
    }

    void animate_img (Gtk.Image img, double start, double end, int duration = 300) {
        var ani = new Adw.TimedAnimation (
            img,
            start,
            end,
            duration,
            new Adw.CallbackAnimationTarget ((value) => {
                var old_min = double.min (start, end);
                var old_max = double.max (start, end);
                var new_min = (double) DEFAULT_PIXEL_SIZE;
                var new_max = (double) CURRENT_PIXEL_SIZE;

                var new_ps = new_min + (value - old_min) * (new_max - new_min) / (old_max - old_min);

                img.pixel_size = (int) new_ps;
                img.opacity = value;
            })
        );

        ani.play ();
    }
}
