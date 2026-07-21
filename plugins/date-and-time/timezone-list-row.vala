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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/DateAndTime/ui/timezone-list-row.ui")]
public class DateAndTime.TimezoneListRow : Gtk.Box {
    [GtkChild]
    public unowned Gtk.ListBox listbox;

    public string title { get; set; }
    public string subtitle { get; set; }
    public string suffix_label { get; set; }

    public string timezone_abbreviation { get; set; }

    TimezoneListItem _item;
    public TimezoneListItem item {
        get { return _item; }
        set {
            _item = value;
            if (value == null) {
                return;
            }

            title = value.region;
            subtitle = @"$(value.city) <b>$(value.country)</b>";
            suffix_label = get_utc_offset_string (value.identifier);
        }
    }
}

public class DateAndTime.TimezoneListItem : Object {
    public string country_codes { get; private set; }
    public string country { get; private set; }

    public string identifier { get; private set; }

    public string region { get; private set; }
    public string city { get; private set; }

    public TimeZone timezone { get; private set; }
    public int32 utc_offset { get; private set; }

    public string metainfo { get; private set; default = ""; }

    // entry: "<country_code>[,country_code]* <region>/<city>"
    public TimezoneListItem (string entry) {
        var parts = entry.split (" ", 2);
        if (parts.length < 2) {
            error ("Invalid timezone entry: %s", entry);
        }

        country_codes = parts[0];
        country = Gnome.Languages.get_country_from_code (country_codes.split (",")[0], null);

        identifier = parts[1];

        region = dgettext ("ready-set-date-and-time-timezones", identifier).replace ("_", " ");

        var region_parts = region.split ("/");
        city = region_parts[region_parts.length - 1];

        try {
            timezone = new TimeZone.identifier (identifier);

            var dt = new DateTime.now (timezone);
            utc_offset = (int32) (dt.get_utc_offset () / TimeSpan.MINUTE);
        } catch (Error e) {
            timezone = new TimeZone.utc ();
            utc_offset = 0;
        }

        metainfo = @"$(country_codes.replace (",", " ")) $identifier $region $country";
    }
}
