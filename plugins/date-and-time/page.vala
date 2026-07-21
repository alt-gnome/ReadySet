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
    unowned Adw.ActionRow date_row;
    [GtkChild]
    unowned Adw.ActionRow time_row;

    string default_timezone_label = _("Choose time zone");
    public string timezone_label { get; set; }

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
            Addin.get_instance ().context.set_string ("date-and-time.timezone", _selected_timezone.get_identifier ());
            update_is_ready ();
        }
    }
    DateTime? _selected_datetime = new DateTime.local (1, 1, 1, 0, 0, 0);
    DateTime? selected_datetime {
        get { return _selected_datetime; }
        set {
            message ("datetime update");
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
    }

    construct {
        timezone_label = default_timezone_label;

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

        dialog.closed.connect (on_timezone_dialog_closed);
    }

    void on_timezone_dialog_closed (Adw.Dialog dialog) {
        var timezone_dialog = (DateAndTime.TimezoneList) dialog;
        var item = timezone_dialog.selected_item;

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
        dialog.apply.connect (on_date_dialog_closed);
    }

    void on_date_dialog_closed (Adw.Dialog dialog) {
        var date_dialog = (DateAndTime.DateSelector) dialog;

        date_selected = true;

        selected_datetime = new DateTime.local (
            date_dialog.year,
            (int) date_dialog.month,
            date_dialog.day,
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
        dialog.apply.connect (on_time_dialog_apply);
    }

    void on_time_dialog_apply (Adw.Dialog dialog) {
        var time_dialog = (DateAndTime.TimeSelector) dialog;

        time_selected = true;

        var datetime = new DateTime.local (
            selected_datetime.get_year (),
            selected_datetime.get_month (),
            selected_datetime.get_day_of_month (),
            time_dialog.hour,
            time_dialog.minute,
            0
        );

        time_label = datetime.format ("%H:%M");
    }
}
