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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/DateAndTime/ui/date-selector.ui")]
public class DateAndTime.DateSelector : Adw.PreferencesDialog {
    [GtkChild]
    unowned DateAndTime.CarouselSelector selector;

    public int day { get; set; }
    public uint month { get; set; }
    public int year { get; set; }

    public Serialize.Array<Gtk.Adjustment> adjustments {
        get; set;
        default = new Serialize.Array<Gtk.Adjustment> ();
    }

    public int day_limit { get; set; }

    public signal void apply ();

    construct {
        var date = new DateTime.now_local ();
        day = date.get_day_of_month ();
        month = date.get_month ();
        year = date.get_year ();

        update_day ();

        var day_adjustment = new Gtk.Adjustment (0, 1, 31, 0, 0, 0);
        bind_property ("day", day_adjustment, "value", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        bind_property ("day-limit", day_adjustment, "upper", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        adjustments.add (day_adjustment);

        var month_adjustment = new Gtk.Adjustment (0, 1, 12, 0, 0, 0);
        bind_property ("month", month_adjustment, "value", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        adjustments.add (month_adjustment);

        var year_adjustment = new Gtk.Adjustment (0, 1, 9999, 0, 0, 0);
        bind_property ("year", year_adjustment, "value", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        adjustments.add (year_adjustment);

        selector.adjustments = adjustments;
        selector.refill_models ();
    }

    [GtkCallback]
    void update_day () {
        day_limit = month % 2 != 0 ? 31 : 30;
        if (month == 2) {
            day_limit = 28;

            if (year % 4 == 0) {
                ++day_limit;
            }
            if (year % 100 == 0) {
                --day_limit;
            }
            if (year % 400 == 0) {
                ++day_limit;
            }
        }

        if (day > day_limit) {
            day = day_limit;
        }
    }

    [GtkCallback]
    public void on_close_button_clicked () {
        close ();
    }

    [GtkCallback]
    public void on_apply_button_clicked () {
        close ();
        apply ();
    }
}
