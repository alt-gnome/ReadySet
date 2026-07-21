[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/DateAndTime/ui/date-and-time-selector.ui")]
public class DateAndTime.DateAndTimeSelector : Adw.PreferencesDialog {
    [GtkChild]
    unowned DateAndTime.CarouselSelector selector;

    public int day { get; set; }
    public uint month { get; set; }
    public int year { get; set; }

    public int hour { get; set; }
    public int minute { get; set; }

    public int day_limit { get; set; }

    public DateTime date = new DateTime.now_local ();

    public signal void apply ();

    public Serialize.Array<Gtk.Adjustment> adjustments {
        get; set;
        default = new Serialize.Array<Gtk.Adjustment> ();
    }

    public Gtk.StringList months {
        get; set;
        default = new Gtk.StringList ({
            _("January"),
            _("February"),
            _("March"),
            _("April"),
            _("May"),
            _("June"),
            _("July"),
            _("August"),
            _("September"),
            _("October"),
            _("November"),
            _("December"),
        });
    }

    construct {
        int year, month, day;
        date.get_ymd (out year, out month, out day);

        this.year = year;
        this.month = month - 1;
        this.day = day;

        var hour_adjustment = new Gtk.Adjustment (0, 0, 24, 0, 0, 0);
        bind_property ("hour", hour_adjustment, "value", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        adjustments.add (hour_adjustment);

        var minute_adjustment = new Gtk.Adjustment (0, 0, 60, 0, 0, 0);
        bind_property ("minute", minute_adjustment, "value", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        adjustments.add (minute_adjustment);

        selector.adjustments = adjustments;
        selector.refill_models ();
    }

    [GtkCallback]
    public void on_month_changed () {
        update_day_limit ();
    }

    [GtkCallback]
    public void on_year_changed () {
        update_day_limit ();
    }

    void update_day_limit () {
        day_limit = get_month_day_count ();

        if (day > day_limit) {
            day = day_limit;
        }
    }

    int get_month_day_count () {
        if (month == 1) {
            var count = 28;

            if (year % 4 == 0) {
                ++count;
            }
            if (year % 100 == 0) {
                --count;
            }
            if (year % 400 == 0) {
                ++count;
            }

            return count;
        }

        if (month % 2 == 0) {
            return 31;
        }

        return 30;
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
