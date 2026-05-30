[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/DateAndTime/ui/date-and-time-selector.ui")]
public class DateAndTime.DateAndTimeSelector : Adw.PreferencesDialog {
    [GtkChild]
    unowned DateAndTime.InfinityCarousel hour_carousel;
    [GtkChild]
    unowned DateAndTime.InfinityCarousel minute_carousel;
    [GtkChild]
    unowned Gtk.Stack stack;
    [GtkChild]
    unowned Gtk.Text time_text;
    [GtkChild]
    unowned Gtk.EventControllerKey event_controller_key;

    public int hour { get; set; }
    public int minute { get; set; }

    public int day { get; set; }
    public uint month { get; set; }
    public int year { get; set; }

    public int day_limit { get; set; }

    public DateTime date = new DateTime.now_local ();

    Gtk.StringList hour_model = new Gtk.StringList (null);
    Gtk.StringList minute_model = new Gtk.StringList (null);

    const int SEPARATOR_INDEX = 2;
    public const int TEXT_MAX_LENGTH = 5;

    public bool is_am_pm { get; set; }

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

        refill_models ();

        int year, month, day;
        date.get_ymd (out year, out month, out day);

        this.year = year;
        this.month = month - 1;
        this.day = day;

        var text_attributes = new Pango.AttrList (); 

        text_attributes.insert(new Pango.AttrSize (Pango.SCALE * 32));
        text_attributes.insert(Pango.attr_weight_new (Pango.Weight.LIGHT));
        text_attributes.insert(new Pango.AttrFontFeatures ("tnum"));

        time_text.set_attributes (text_attributes);
    }

    public void refill_models () {
        while (hour_model.n_items != 0) {
            hour_model.remove (0);
        }

        for (int i = hour; i < 24 + hour; ++i) {
            hour_model.append ("%02d".printf (clamp_hour (i)));
        }

        while (minute_model.n_items != 0) {
            minute_model.remove (0);
        }

        for (int i = minute; i < 60 + minute; ++i) {
            minute_model.append ("%02d".printf (clamp_minute (i)));
        }

        hour_carousel.bind_model (hour_model, build_carousel_item);
        minute_carousel.bind_model (minute_model, build_carousel_item);
    }

    public Gtk.Widget build_carousel_item (Object object) {
        var item = (Gtk.StringObject) object;
        var widget = new Gtk.Label (item.string);
        widget.add_css_class ("title-1");
        return widget;
    }

    [GtkCallback]
    public void on_gesture_click_pressed () {
        update_time ();
        stack.set_visible_child_name ("entry");
    }

    [GtkCallback]
    public void on_apply_button_clicked () {
        refill_models ();
        stack.set_visible_child_name ("selector");
    }

    [GtkCallback]
    public void on_delete_from_cursor (Gtk.Text widget, Gtk.DeleteType delete_type, int _) {
        Signal.stop_emission_by_name (widget, "delete-from-cursor");
    }

    [GtkCallback]
    public void on_backspace (Gtk.Text widget) {
        Signal.stop_emission_by_name (widget, "backspace");
    }

    [GtkCallback]
    public void on_cut_clipboard (Gtk.Text widget) {
        Signal.stop_emission_by_name (widget, "cut-clipboard");
    }

    [GtkCallback]
    public void on_move_cursor (Gtk.MovementStep step, int count, bool extend) {
        var current_pos = time_text.get_position ();

        if (step == Gtk.MovementStep.LOGICAL_POSITIONS || step == Gtk.MovementStep.VISUAL_POSITIONS) {
            if (current_pos + count == SEPARATOR_INDEX) {
                count > 0 ? count++ : count--;
            } else if (current_pos + count < 0) {
                current_pos = TEXT_MAX_LENGTH - 1;
                count = 0;
            } else if (current_pos + count == TEXT_MAX_LENGTH) {
                current_pos = 0;
                count = 0;
            }
        }

        SignalHandler.block_by_func (time_text, (void*) on_move_cursor, this);
        time_text.set_position (current_pos + count);
        SignalHandler.unblock_by_func (time_text, (void*) on_move_cursor, this);

        Signal.stop_emission_by_name (time_text, "move-cursor");
    }

    [GtkCallback]
    public void on_month_changed () {
        update_day_limit ();
    }

    [GtkCallback]
    public void on_year_changed () {
        update_day_limit ();
    }

    void update_time () {
        time_text.set_text ("%02d:%02d".printf (hour, minute));
    }

    int clamp_hour (int hour) {
        return clamp_value (hour, 0, is_am_pm ? 12 : 24);
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

    [GtkCallback]
    public bool on_key_pressed (uint keyval, uint keycode = 0, Gdk.ModifierType state = 0) {
        bool increment = keyval == Gdk.Key.Up || keyval == Gdk.Key.KP_Up;
        bool decrement = keyval == Gdk.Key.Down || keyval == Gdk.Key.KP_Down ;

        if (!increment && !decrement) {
            return Gdk.EVENT_PROPAGATE;
        }

        var position = time_text.get_position ();

        if (position > SEPARATOR_INDEX) {
            if (increment) {
                minute++;
            } else if (decrement) {
                minute--;
            }

            minute = clamp_minute (minute);
        } else {
            if (increment) {
                hour++;
            } else if (decrement) {
                hour--;
            }

            hour = clamp_hour (hour);
        }

        update_time ();
        time_text.set_position (position);

        return Gdk.EVENT_STOP;
    }

    [GtkCallback]
    public void on_hour_changed (int distance) {
        hour = clamp_hour (hour - distance);
    }

    [GtkCallback]
    public void on_minute_changed (int distance) {
        minute = clamp_minute (minute - distance);
    }
}
