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

    int clamp_hour (int hour, bool is_am_pm = false) {
        return clamp_value (hour, 0, is_am_pm ? 12 : 24);
    }

    int clamp_minute (int minute) {
        return clamp_value (minute, 0, 60);
    }

    string get_utc_offset_string (string identifier) {
        var current_timezone = Environment.get_variable ("TZ");
        Environment.set_variable ("TZ", identifier, true);

        var offset = (new DateTime.now_local ()).get_utc_offset () / 1000 / 1000;
        var timezone = new TimeZone.offset ((int32) offset);

        if (current_timezone != null && current_timezone != "")
            Environment.set_variable ("TZ", current_timezone, true);
        else
            Environment.unset_variable ("TZ");

        var parts = timezone.get_identifier ().split (":");

        return "UTC" + parts[0] + ":" + parts[1];
    }

    async DateAndTime.Timedate1 get_timedate_proxy () throws Error {
        var con = yield Bus.get (BusType.SYSTEM);

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
