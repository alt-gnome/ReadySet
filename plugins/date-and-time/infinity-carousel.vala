[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/DateAndTime/ui/infinity-carousel.ui")]
public class DateAndTime.InfinityCarousel : Gtk.Box {
    [GtkChild]
    unowned Adw.Carousel carousel;
    [GtkChild]
    unowned Gtk.Button previous_button;
    [GtkChild]
    unowned Gtk.Button next_button;

    public int elements_count { get; set; }

    public ListModel? model { get; set; }
    weak Gtk.ListBoxCreateWidgetFunc? create_widget_func;

    int items_center;

    public signal void item_pressed ();

    public signal void page_changed (int distance);

    [GtkCallback]
    public void on_previous_button_clicked () {
        uint n_pages = carousel.get_n_pages ();
        if (n_pages == 0) return;

        uint current_page = (uint) (carousel.position + 0.5);

        if (current_page >= n_pages) {
            current_page = n_pages - 1;
        }

        uint target_page;
        if (current_page == 0) {
            target_page = 0;
        } else {
            target_page = current_page - 1;
        }

        carousel.scroll_to (carousel.get_nth_page (target_page), true);
    }

    [GtkCallback]
    public void on_next_button_clicked () {
        uint n_pages = carousel.get_n_pages ();
        if (n_pages == 0) return;

        uint current_page = (uint) (carousel.position + 0.5);

        uint target_page = current_page + ((int) (current_page + 1 != n_pages));
        carousel.scroll_to (carousel.get_nth_page (target_page), true);
    }

    void fill () {
        int items_count = (int) model.get_n_items ();
        items_center = items_count;

        for (int _ = 0; _ < 2; ++_) {
            for (int i = 0; i < items_center; ++i) {
                var item = model.get_item (i);
                var card = create_widget_func (item);
                carousel.append (card);
            }
        }

        carousel.scroll_to (carousel.get_nth_page (items_center), false);
    }

    void on_page_changed (uint index) {
        var distance = items_center - (int) index;

        if (distance > 0) {
            for (int counter = distance; counter != 0; --counter) {
                var item = carousel.get_nth_page (carousel.get_n_pages () - 1);
                carousel.remove (item);
                carousel.prepend (item);
            }
        }

        if (distance < 0) {
            for (int counter = -distance; counter != 0; --counter) {
                var item = carousel.get_nth_page (0);
                carousel.remove (item);
                carousel.append (item);
            }
        }

        page_changed (distance);
    }

    public void bind_model (ListModel? model, owned Gtk.ListBoxCreateWidgetFunc? create_widget_func) {
        if (this.model != null) {
            this.model = null;
        }

        clear ();
        this.model = model;
        this.create_widget_func = create_widget_func;

        if (model != null) {
            fill ();
        }
    }

    public void remove (Gtk.Widget widget) {
        carousel.remove (widget);
    }

    public void clear () {
        carousel.page_changed.disconnect (on_page_changed);

        if (carousel.get_n_pages () != 0)
            carousel.scroll_to (carousel.get_nth_page (0), false);

        while (carousel.get_n_pages () != 0) {
            var child = carousel.get_nth_page (0);
            carousel.remove (child);
        }

        carousel.page_changed.connect (on_page_changed);
    }

    [GtkCallback]
    public void on_items_pressed () {
        item_pressed ();
    }
}

