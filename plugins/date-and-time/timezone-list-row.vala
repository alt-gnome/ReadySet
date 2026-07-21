[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/DateAndTime/ui/timezone-list-row.ui")]
public class DateAndTime.TimezoneListRow : Gtk.Box {
    [GtkChild]
    public Gtk.ListBox listbox;

    public string title { get; set; }
    public string subtitle { get; set; }
    public string suffix_label { get; set; }

    TimezoneListItem _item;
    public TimezoneListItem item {
        get { return _item; }
        set {
            _item = value;
            if (value == null) {
                return;
            }

            title = value.region;
            subtitle = @"<b>$(value.country)</b> / $(value.city)";
            suffix_label = get_utc_offset_string (value.utc_offset);
        }
    }
}

public class DateAndTime.TimezoneListItem : Object {
    public TimeZone timezone { get; set; }

    string _region;
    public string region {
        get { return _region; }
        set {
            _region = value;
            update_metainfo ();
        }
    }
    string _country;
    public string country {
        get { return _country; }
        set {
            _country = value;
            update_metainfo ();
        }
    }
    string _city;
    public string city {
        get { return _city; }
        set {
            _city = value;
            update_metainfo ();
        }
    }
    public int32 utc_offset { get; set; }

    public string metainfo { get; private set; default = ""; }

    void update_metainfo () {
        if (region != null && country != null && city != null) {
            metainfo = @"$region $country $city";
        }
    }
}
