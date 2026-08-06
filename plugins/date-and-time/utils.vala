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

namespace DateAndTime {
    int clamp_value (int value, int min, int max) {
        var delta = max - min;

        while (value < min) {
            value += delta;
        }
        while (value >= max) {
            value -= delta;
        }

        return value;
    }

    string get_utc_offset_string (string identifier) {
        try {
            var tz = new TimeZone.identifier (identifier);
            var dt = new DateTime.now (tz);
            var offset_minutes = (int32) (dt.get_utc_offset () / TimeSpan.MINUTE);

            var hours = offset_minutes / 60;
            var minutes = offset_minutes.abs () % 60;
            var sign = hours >= 0 ? "+" : "";

            return @"UTC$(sign)$(hours):%02d".printf (minutes);
        } catch (Error e) {
            return "UTC";
        }
    }

    string get_default_timezone (string lang) {
        // Original list
        // https://git.altlinux.org/gears/a/alterator-datetime.git?a=blob_plain;f=alterator-datetime/etc/defaultzones

        switch (lang) {
            case "BY":
                return "Europe/Minsk";
            case "GB":
                return "Europe/London";
            case "RU":
                return "Europe/Moscow";
            case "UA":
                return "Europe/Kiev";
            case "US":
                return "America/New_York";
            case "ES":
                return "Europe/Madrid";
            case "BR":
                return "America/Sao_Paulo";
            case "AR":
                return "America/Argentina/Buenos_Aires";
            case "CL":
                return "America/Santiago";
            case "VE":
                return "America/Caracas";
            case "UZ":
                return "Asia/Tashkent";
            case "POSIX":
            default:
                return "Europe/London";
        }
    }

    public string? get_locale_country (string full_locale) {
        if (full_locale == "") {
            return null;
        }

        var locale = full_locale.split (".")[0].split ("@")[0].split ("_");

        if (locale.length >= 2) {
            return locale[1];
        }

        return null;
    }

    DateAndTime.Timedate1 get_timedate_proxy () throws Error {
        var con = Bus.get_sync (BusType.SYSTEM);

        if (con == null) {
            error ("Failed to connect to bus");
        }

        return con.get_proxy_sync<DateAndTime.Timedate1> (
            "org.freedesktop.timedate1",
            "/org/freedesktop/timedate1",
            DBusProxyFlags.NONE
        );
    }
}

[DBus (name = "org.freedesktop.timedate1")]
public interface DateAndTime.Timedate1 : Object {
    public abstract string timezone { owned get; }
    [DBus (name = "LocalRTC")]
    public abstract bool local_rtc { owned get; }
    [DBus (name = "CanNTP")]
    public abstract bool can_ntp { owned get; }
    [DBus (name = "NTP")]
    public abstract bool ntp { owned get; }
    [DBus (name = "NTPSynchronized")]
    public abstract bool ntp_synchronized { owned get; }
    [DBus (name = "TimeUSec")]
    public abstract uint64 time_usec { owned get; }
    [DBus (name = "RTCTimeUSec")]
    public abstract uint64 rtc_time_usec { owned get; }

    public abstract async void set_time (
        int64 usec_utc,
        bool relative = false,
        bool interactive = true
    ) throws Error;

    public abstract async void set_timezone (
        string timezone,
        bool interactive = true
    ) throws Error;

    [DBus (name = "SetLocalRTC")]
    public abstract async void set_local_rtc (
        bool local_rtc,
        bool fix_system,
        bool interactive = true
    ) throws Error;

    [DBus (name = "SetNTP")]
    public abstract async void set_ntp (
       bool use_ntp,
       bool interactive = true
    ) throws Error;

    public abstract async void list_timezones (
      out string[] timezones
    ) throws Error;
}
