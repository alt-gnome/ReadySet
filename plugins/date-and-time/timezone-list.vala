[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/DateAndTime/ui/timezone-list.ui")]
public class DateAndTime.TimezoneList : Adw.Dialog {
    public ListStore model { get; set; default = new ListStore (typeof (TimezoneListItem)); }

    Gee.ArrayList<TimezoneListItem> timezones = new Gee.ArrayList<TimezoneListItem> ();
    Gee.ArrayList<string> timezone_metainfos = new Gee.ArrayList<string> ();

    public TimezoneListItem selected_item { get; set; }

    public TimezoneList () {
        var world = GWeather.Location.get_world ();

        collect_timezones (world);

        var sorted = new Gee.ArrayList<TimezoneListItem> ();
        foreach (var item in timezones) {
            sorted.add (item);
        }

        sorted.sort ((_a, _b) => {
            var a = _a.utc_offset;
            var b = _b.utc_offset;

            if (a > b) return Gtk.Ordering.LARGER;
            if (a < b) return Gtk.Ordering.SMALLER;
            return Gtk.Ordering.EQUAL;
        });

        foreach (var item in sorted) {
            model.append (item);
        }
    }

    void collect_timezones (GWeather.Location loc) {
        weak TimeZone? timezone = loc.get_timezone ();
        if (timezone != null) {
            var region = timezone.get_identifier ();
            var country = loc.get_country_name ();
            var city = loc.get_city_name ();
            var utc_offset = timezone.get_offset (0);

            if (region != null && city != null && country != null) {
                var hours = 12 * 60 * 60;

                var item = new TimezoneListItem () {
                    timezone = timezone,
                    region = region.split ("/")[0],
                    country = country,
                    city = city,
                    utc_offset = clamp_value (utc_offset, -hours, hours),
                };

                if (!(item.metainfo in timezone_metainfos)) {
                    timezones.add (item);
                    timezone_metainfos.add (item.metainfo);
                }
            }
        }

        GWeather.Location location = null;
        while ((location = loc.next_child (location)) != null) {
            collect_timezones (location);
        }
    }
}
