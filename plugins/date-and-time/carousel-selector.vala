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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/DateAndTime/ui/carousel-selector.ui")]
public class DateAndTime.CarouselSelector : Adw.Bin {
    [GtkChild]
    unowned Gtk.Stack stack;
    [GtkChild]
    unowned Gtk.Text text;
    [GtkChild]
    unowned Gtk.Box carousels_box;

    public string separator { get; construct set; default = ""; }
    public bool carousel_separator { get; construct set; default = true; }

    public Serialize.Array<Gtk.Adjustment> adjustments =
        new Serialize.Array<Gtk.Adjustment> ();

    Serialize.Array<DateAndTime.InfinityCarousel> carousels =
        new Serialize.Array<DateAndTime.InfinityCarousel> ();

    string current_text;

    construct {
        var text_attributes = new Pango.AttrList ();

        text_attributes.insert (new Pango.AttrSize (Pango.SCALE * 32));
        text_attributes.insert (Pango.attr_weight_new (Pango.Weight.LIGHT));
        text_attributes.insert (new Pango.AttrFontFeatures ("tnum"));

        text.set_attributes (text_attributes);
    }

    public void refill_models () {
        carousels.clear ();

        Gtk.Widget child;
        while ((child = carousels_box.get_first_child ()) != null) {
            carousels_box.remove (child);
        }

        for (var i = 0; i < adjustments.size; ++i) {
            var adjustment = adjustments[i];

            var carousel = new DateAndTime.InfinityCarousel () {
                height_request = 200,
                infinite = true,
                spacing = 6,
            };

            var model = new Gtk.StringList (null);
            for (var v = (int) adjustment.lower; v <= (int) adjustment.upper; ++v) {
                var item = "%0*d".printf (adjustment.upper.to_string ().length, v);
                model.append (item);
            }

            var selection = new Gtk.SingleSelection (model) {
                selected = (uint) (adjustment.value - adjustment.lower)
            };

            carousel.create.connect ((item) => {
                var string_object = (Gtk.StringObject) item;
                var label = new Gtk.Label (string_object.string);
                label.add_css_class ("title-1");
                return label;
            });

            carousel.model = selection;

            carousel.page_changed.connect ((index) => {
                adjustment.value = (double) (index + (int) adjustment.lower);
            });

            carousel.item_pressed.connect (() => {
                on_gesture_click_pressed ();
            });

            carousels_box.append (carousel);
            carousels.add (carousel);

            if (i + 1 < adjustments.size && carousel_separator && separator != "") {
                var sep = new Gtk.Label (separator);
                sep.add_css_class ("title-1");
                carousels_box.append (sep);
            }
        }

        update_text ();
    }

    void update_text () {
        current_text = "";
        for (var i = 0; i < adjustments.size; ++i) {
            var adjustment = adjustments[i];

            if (current_text != "") {
                current_text += separator;
            }

            current_text += "%0*d".printf (
                adjustment.upper.to_string ().length,
                (int) adjustment.value
            );
        }
        text.set_text (current_text);
    }

    public void on_gesture_click_pressed () {
        update_text ();
        stack.set_visible_child_name ("entry");
    }

    [GtkCallback]
    public void on_text_apply_button_clicked () {
        refill_models ();
        stack.set_visible_child_name ("selector");
    }

    [GtkCallback]
    public void on_delete_from_cursor (Gtk.Text widget, Gtk.DeleteType delete_type, int _) {
        Signal.stop_emission_by_name (widget, "delete-from-cursor");
    }

    [GtkCallback]
    public void on_backspace (Gtk.Text widget) {
        Signal.stop_emission_by_name (widget, "backspace");
    }

    [GtkCallback]
    public void on_cut_clipboard (Gtk.Text widget) {
        Signal.stop_emission_by_name (widget, "cut-clipboard");
    }

    [GtkCallback]
    public void on_paste_clipboard (Gtk.Text widget) {
        Signal.stop_emission_by_name (widget, "paste-clipboard");
    }

    [GtkCallback]
    public void on_move_cursor (Gtk.MovementStep step, int count, bool extend) {
        var current_pos = text.get_position ();

        if (is_separator (current_pos + count)) {
            count > 0 ? count++ : count--;
        } else if (current_pos + count < 0) {
            current_pos = current_text.length - 1;
            count = 0;
        } else if (current_pos + count >= current_text.length) {
            current_pos = 0;
            count = 0;
        }

        SignalHandler.block_by_func (text, (void*) on_move_cursor, this);
        text.set_position (current_pos + count);
        SignalHandler.unblock_by_func (text, (void*) on_move_cursor, this);

        Signal.stop_emission_by_name (text, "move-cursor");
    }

    [GtkCallback]
    public bool on_key_pressed (uint keyval, uint keycode = 0, Gdk.ModifierType state = 0) {
        bool increment = keyval == Gdk.Key.Up || keyval == Gdk.Key.KP_Up;
        bool decrement = keyval == Gdk.Key.Down || keyval == Gdk.Key.KP_Down;

        if (!increment && !decrement) {
            return Gdk.EVENT_PROPAGATE;
        }

        var position = text.get_position ();

        var adjustment = adjustments[get_segment (position)];
        adjustment.value = clamp_value (
            (int) adjustment.value + (increment ? 1 : -1),
            (int) adjustment.lower,
            (int) adjustment.upper + 1
        );

        update_text ();
        text.set_position (position);

        return Gdk.EVENT_STOP;
    }

    [GtkCallback]
    public void on_insert_text (string new_text, int length, ref int position) {
        if (length != 1) {
            return;
        }

        if ("0" < new_text > "9") {
            text.set_text (current_text);
            Signal.stop_emission_by_name (text, "insert-text");
            return;
        }

        var adjustment = adjustments[get_segment (position)];
        var old_value = adjustment.value;
        var new_value = int.parse (new_text);

        var a = 0;
        foreach (var item in adjustments) {
            a += item.upper.to_string ().length;

            if (position < a) {
                a -= position + 1;
                break;
            }

            a++;
        }

        var left = Math.pow (10, a + 1);
        var right = Math.pow (10, a);

        var value = (int) (old_value / left) * left
                    + new_value * right
                    + old_value % right;
        adjustment.value = value;

        update_text ();

        position++;

        if (is_separator (position)) {
            position++;
        } else if (position > current_text.length - 1) {
            position--;
        }

        Signal.stop_emission_by_name (text, "insert-text");
    }

    bool is_separator (int position) {
        if (position < 0 || position >= current_text.length) {
            return false;
        }

        var index = 0;

        foreach (var adjustment in adjustments) {
            index += adjustment.upper.to_string ().length;

            if (index == position) {
                return true;
            }

            index++;
        }

        return false;
    }

    int get_segment (int position) {
        if (position < 0 || position >= current_text.length) {
            return -1;
        }

        var segment_index = 0;
        var previous = 0;

        foreach (var adjustment in adjustments) {
            var next = previous + adjustment.upper.to_string ().length;

            if (previous <= position < next) {
                return segment_index;
            }

            segment_index++;
            previous = next + 1;
        }

        return -1;
    }
}
