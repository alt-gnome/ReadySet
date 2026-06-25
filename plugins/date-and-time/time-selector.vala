[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/DateAndTime/ui/time-selector.ui")]
public class DateAndTime.TimeSelector : Adw.PreferencesDialog {
    [GtkChild]
    unowned DateAndTime.CarouselSelector selector;

    public int hour { get; set; }
    public int minute { get; set; }

    public signal void apply ();

    public Serialize.Array<Gtk.Adjustment> adjustments {
        get; set;
        default = new Serialize.Array<Gtk.Adjustment> ();
    }

    construct {
        var date = new DateTime.now_local ();
        hour = date.get_hour ();
        minute = date.get_minute ();

        var hour_adjustment = new Gtk.Adjustment (hour, 0, 23, 0, 0, 0);
        bind_property ("hour", hour_adjustment, "value", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        adjustments.add (hour_adjustment);

        var minute_adjustment = new Gtk.Adjustment (minute, 0, 59, 0, 0, 0);
        bind_property ("minute", minute_adjustment, "value", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        adjustments.add (minute_adjustment);

        selector.adjustments = adjustments;
        selector.refill_models ();
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
