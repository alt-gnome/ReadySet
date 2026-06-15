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
    string default_timezone_label = _("Choose time zone");
    string default_date_and_time_label = _("Choose date and time");

    public string timezone_label { get; set; }
    public string date_and_time_label { get; set; }

    bool _automatic_timezone = Addin.get_instance ().context.get_boolean ("date-and-time-automatic-timezone");
    public bool automatic_timezone {
        get {
            return _automatic_timezone;
        }
        set {
            _automatic_timezone = value;
            Addin.get_instance ().context.set_boolean ("date-and-time-automatic-timezone", _automatic_timezone);
            update_is_ready ();
        }
    }

    bool _automatic_date_and_time = Addin.get_instance ().context.get_boolean ("date-and-time-automatic-datetime");
    public bool automatic_date_and_time {
        get {
            return _automatic_date_and_time;
        }
        set {
            _automatic_date_and_time = value;
            Addin.get_instance ().context.set_boolean ("date-and-time-automatic-datetime", _automatic_date_and_time);
            update_is_ready ();
        }
    }

    public Gtk.StringList timezone_model { get; set; default = new Gtk.StringList (null); }

    TimeZone _selected_timezone;
    TimeZone selected_timezone {
        get { return _selected_timezone; }
        set {
            _selected_timezone = value;
            Addin.get_instance ().context.set_string ("date-and-time-timezone", _selected_timezone.get_identifier ());
            update_is_ready ();
        }
    }
    DateTime _selected_datetime;
    DateTime selected_datetime {
        get { return _selected_datetime; }
        set {
            _selected_datetime = value;
            Addin.get_instance ().context.set_int ("date-and-time-datetime", _selected_datetime.to_unix ());
            update_is_ready ();
        }
    }

    static construct {
        typeof (TimezoneList).ensure ();
        typeof (TimezoneListItem).ensure ();
        typeof (TimezoneListRow).ensure ();

        typeof (DateAndTimeSelector).ensure ();
    }

    construct {
        timezone_label = default_timezone_label;
        date_and_time_label = default_date_and_time_label;
        update_is_ready ();
    }

    void update_is_ready () {
        is_ready = (automatic_date_and_time || selected_datetime != null)
                && (automatic_timezone || selected_timezone != null);
    }

    [GtkCallback]
    void on_timezone_row_clicked () {
        var dialog = new DateAndTime.TimezoneList ();
        dialog.present (this);

        dialog.closed.connect (on_timezone_dialog_closed);
    }

    void on_timezone_dialog_closed (Adw.Dialog dialog) {
        var timezone_dialog = (DateAndTime.TimezoneList) dialog;
        var item = timezone_dialog.selected_item;

        if (item == null) {
            timezone_label = default_timezone_label;
            return;
        }

        var utc = DateAndTime.get_utc_offset_string (item.utc_offset);
        timezone_label = @"<b>$(item.country)</b> / $(item.city) ($utc)";

        selected_timezone = item.timezone;
    }

    [GtkCallback]
    void on_date_and_time_row_clicked () {
        var dialog = new DateAndTime.DateAndTimeSelector ();
        dialog.present (this);

        dialog.apply.connect (on_date_and_time_dialog_closed);
    }

    void on_date_and_time_dialog_closed (Adw.Dialog dialog) {
        var date_and_time_dialog = (DateAndTime.DateAndTimeSelector) dialog;

        var hour = date_and_time_dialog.hour;
        var minute = date_and_time_dialog.minute;

        var day = date_and_time_dialog.day;
        var month = (int) date_and_time_dialog.month;
        var year = date_and_time_dialog.year;

        var datetime = new DateTime.local (year, month, day, hour, minute, 0);
        date_and_time_label = datetime.format ("%d.%m.%Y, %H:%M");

        selected_datetime = datetime;
    }
}
