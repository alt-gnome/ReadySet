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
    [GtkChild]
    unowned Adw.ActionRow timezone_row;
    [GtkChild]
    unowned Adw.ActionRow date_row;
    [GtkChild]
    unowned Adw.ActionRow time_row;

    string _timezone_label = "";
    public string timezone_label {
        get { return _timezone_label; }
        set {
            _timezone_label = value;

            if (value != "") {
                timezone_row.add_css_class ("property");
            } else {
                timezone_row.remove_css_class ("property");
            }
        }
    }

    string _date_label = "";
    public string date_label {
        get { return _date_label; }
        set {
            _date_label = value;

            if (value != "") {
                date_row.add_css_class ("property");
            } else {
                date_row.remove_css_class ("property");
            }
        }
    }

    string _time_label = "";
    public string time_label {
        get { return _time_label; }
        set {
            _time_label = value;

            if (value != "") {
                time_row.add_css_class ("property");
            } else {
                time_row.remove_css_class ("property");
            }
        }
    }

    bool _manual_timezone = Addin.get_instance ().context.get_boolean ("date-and-time.automatic-timezone");
    public bool manual_timezone {
        get {
            return _manual_timezone;
        }
        set {
            _manual_timezone = value;
            Addin.get_instance ().context.set_boolean ("date-and-time.automatic-timezone", !_manual_timezone);
            update_is_ready ();
        }
    }

    bool _manual_date_and_time = Addin.get_instance ().context.get_boolean ("date-and-time.automatic-datetime");
    public bool manual_date_and_time {
        get {
            return _manual_date_and_time;
        }
        set {
            _manual_date_and_time = value;
            Addin.get_instance ().context.set_boolean ("date-and-time.automatic-datetime", !_manual_date_and_time);
            update_is_ready ();
        }
    }

    public Gtk.StringList timezone_model { get; set; default = new Gtk.StringList (null); }

    TimeZone? _selected_timezone;
    TimeZone? selected_timezone {
        get { return _selected_timezone; }
        set {
            _selected_timezone = value;
            if (_selected_timezone != null) {
                Addin.get_instance ().context.set_string (
                    "date-and-time.timezone",
                    _selected_timezone.get_identifier ()
                );
            }
            update_is_ready ();
        }
    }
    DateTime? _selected_datetime;
    DateTime? selected_datetime {
        get { return _selected_datetime; }
        set {
            _selected_datetime = value;
            Addin.get_instance ().context.set_int ("date-and-time.datetime", _selected_datetime.to_unix ());
            update_is_ready ();
        }
    }

    protected bool date_selected { get; set; default = false; }
    protected bool time_selected { get; set; default = false; }

    static construct {
        typeof (TimezoneList).ensure ();
        typeof (TimezoneListItem).ensure ();
        typeof (TimezoneListRow).ensure ();

        typeof (CarouselSelector).ensure ();

        typeof (Case.InfinityCarousel).ensure ();
    }

    construct {
        var now_tz = new TimeZone.local ();
        var now_dt_tz = new DateTime.now (now_tz);
        timezone_label = @"$(now_tz.get_identifier ()) ($(now_dt_tz.get_timezone_abbreviation ()))";
        selected_timezone = now_tz;

        var now = new DateTime.now_local ();
        selected_datetime = now;
        date_label = now.format ("%d.%m.%Y");
        time_label = now.format ("%H:%M");
        date_selected = true;
        time_selected = true;

        update_is_ready ();
    }

    [GtkCallback]
    void update_is_ready () {
        is_ready = (!manual_date_and_time || date_selected && time_selected)
                && (!manual_timezone || selected_timezone != null);
    }

    [GtkCallback]
    void on_timezone_row_clicked () {
        var dialog = new DateAndTime.TimezoneList ();
        dialog.present (this);

        ulong handler_id = 0;
        handler_id = dialog.closed.connect ((d) => {
            SignalHandler.disconnect (dialog, handler_id);
            on_timezone_dialog_closed ((DateAndTime.TimezoneList) d);
        });
    }

    void on_timezone_dialog_closed (DateAndTime.TimezoneList dialog) {
        var item = dialog.selected_item;

        if (item == null) {
            return;
        }

        var timezone_abbreviation = (new DateTime.now (item.timezone)).get_timezone_abbreviation ();
        timezone_label = @"<b>$(item.country)</b> / $(item.city) ($timezone_abbreviation)";

        selected_timezone = item.timezone;
    }

    [GtkCallback]
    void on_date_row_clicked () {
        var dialog = new DateAndTime.DateSelector ();
        dialog.present (this);

        ulong handler_id = 0;
        handler_id = dialog.apply.connect ((d) => {
            SignalHandler.disconnect (dialog, handler_id);
            on_date_dialog_closed ((DateAndTime.DateSelector) d);
        });
    }

    void on_date_dialog_closed (DateAndTime.DateSelector dialog) {
        date_selected = true;

        selected_datetime = new DateTime.local (
            dialog.year,
            (int) dialog.month,
            dialog.day,
            selected_datetime.get_hour (),
            selected_datetime.get_minute (),
            0
        );

        date_label = selected_datetime.format ("%d.%m.%Y");
    }

    [GtkCallback]
    void on_time_row_clicked () {
        var dialog = new DateAndTime.TimeSelector ();
        dialog.present (this);

        ulong handler_id = 0;
        handler_id = dialog.apply.connect ((d) => {
            SignalHandler.disconnect (dialog, handler_id);
            on_time_dialog_apply ((DateAndTime.TimeSelector) d);
        });
    }

    void on_time_dialog_apply (DateAndTime.TimeSelector dialog) {
        time_selected = true;

        selected_datetime = new DateTime.local (
            selected_datetime.get_year (),
            selected_datetime.get_month (),
            selected_datetime.get_day_of_month (),
            dialog.hour,
            dialog.minute,
            0
        );

        time_label = selected_datetime.format ("%H:%M");
    }
}
