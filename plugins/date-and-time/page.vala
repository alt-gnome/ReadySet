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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/DateAndTime/ui/page.ui")]
public sealed class DateAndTime.Page : ReadySet.BasePage {
    public string timezone_label { get; set; default = "Goida (Heaven +∞)"; }
    public Gtk.StringList timezone_model { get; set; default = new Gtk.StringList (null); }

    public string date_label { get; set; default = "Fuck fuck FUCK"; }
    public string time_label { get; set; default = "Fu:ck"; }

    public bool automatic_timezone { get; set; default = false; }
    public bool automatic_date_and_time { get; set; default = false; }

    public Settings datetime_settings = new Settings ("org.gnome.desktop.datetime");

    static construct {
        typeof (TimezoneList).ensure ();
        typeof (DateAndTimeSelector).ensure ();
    }

    [GtkCallback]
    void on_automatic_timezone_changed () {
        datetime_settings.set_boolean ("automatic-timezone", automatic_timezone);
    }

    [GtkCallback]
    void on_timezone_row_clicked () {
        var dialog = new DateAndTime.TimezoneList ();
        dialog.present (this);
    }

    [GtkCallback]
    void on_date_and_time_row_clicked () {
        var dialog = new DateAndTime.DateAndTimeSelector ();
        dialog.present (this);
    }
}
