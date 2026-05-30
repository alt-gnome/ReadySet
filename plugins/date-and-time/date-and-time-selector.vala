[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/DateAndTime/ui/date-and-time-selector.ui")]
public class DateAndTime.DateAndTimeSelector : Adw.PreferencesDialog {
    [GtkChild]
    unowned DateAndTime.InfinityCarousel hour_carousel;
    [GtkChild]
    unowned DateAndTime.InfinityCarousel minute_carousel;
    [GtkChild]
    unowned Gtk.Stack stack;
    [GtkChild]
    unowned Gtk.Text hour_text;
    [GtkChild]
    unowned Gtk.Text minute_text;

    public int hour { get; set; }
    public int minute { get; set; }

    public int day { get; set; }
    public uint month { get; set; }
    public int year { get; set; }

    public int day_limit { get; set; }

    public DateTime date = new DateTime.now_local ();

    Gtk.StringList hour_model = new Gtk.StringList (null);
    Gtk.StringList minute_model = new Gtk.StringList (null);

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

    public DateAndTimeSelector () {
        hour = date.get_hour ();
        minute = date.get_minute ();

        for (int i = 0; i < 24; ++i) {
            hour_model.append ("%02d".printf (i));
        }

        for (int i = 0; i < 60; ++i) {
            minute_model.append ("%02d".printf (i));
        }

        hour_carousel.bind_model (hour_model, build_carousel_item);
        minute_carousel.bind_model (minute_model, build_carousel_item);

        int year, month, day;
        date.get_ymd (out year, out month, out day);

        this.year = year;
        this.month = month - 1;
        this.day = day;

        var text_attributes = new Pango.AttrList (); 

        text_attributes.insert(new Pango.AttrSize (Pango.SCALE * 32));
        text_attributes.insert(Pango.attr_weight_new (Pango.Weight.LIGHT));
        text_attributes.insert(new Pango.AttrFontFeatures ("tnum"));

        hour_text.set_attributes (text_attributes);
        minute_text.set_attributes (text_attributes);
    }

    public Gtk.Widget build_carousel_item (Object object) {
        var item = (Gtk.StringObject) object;
        var widget = new Gtk.Label (item.string);
        widget.add_css_class ("title-1");
        return widget;
    }

    [GtkCallback]
    public void on_gesture_click_pressed () {
        stack.set_visible_child_name ("entry");
        update_hour ();
        update_minute ();
    }

    [GtkCallback]
    public void on_apply_button_clicked () {
        stack.set_visible_child_name ("selector");
    }

    [GtkCallback]
    public void on_hour_changed () {
        hour = int.parse (hour_text.get_text ()).clamp (0, 23);
        update_hour ();
    }

    [GtkCallback]
    public void on_hour_edited () {
        hour_text.insert_text.disconnect (on_hour_edited);
        update_hour ();
        hour_text.insert_text.connect (on_hour_edited);
    }

    [GtkCallback]
    public void on_minute_changed () {
        minute = int.parse (minute_text.get_text ()).clamp (0, 59);
        update_minute ();
    }

    [GtkCallback]
    public void on_minute_edited () {
        minute_text.insert_text.disconnect (on_minute_edited);
        update_minute ();
        minute_text.insert_text.connect (on_minute_edited);
    }

    [GtkCallback]
    public void on_month_changed () {
        update_day_limit ();
    }

    [GtkCallback]
    public void on_year_changed () {
        update_day_limit ();
    }

    void update_hour () {
        hour_text.set_text ("%02d".printf (hour));
    }

    void update_minute () {
        minute_text.set_text ("%02d".printf (minute));
    }

    int clamp_hour (int hour) {
        return clamp_value (hour, 0, 24);
    }

    int clamp_minute (int minute) {
        return clamp_value (minute, 0, 60);
    }

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
}
