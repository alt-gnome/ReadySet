/* Copyright (C) 2024-2025 Vladimir Romanov <rirusha@altlinux.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Keyboard/ui/input-chooser.ui")]
public sealed class Keyboard.InputChooser : Gtk.Box {

    [GtkChild]
    unowned Gtk.SearchEntry filter_entry;
    [GtkChild]
    unowned Gtk.ListBox input_list;
    [GtkChild]
    unowned Gtk.ListBox current_input_list;

    const string INPUT_SOURCE_TYPE_XKB = "xkb";
    const string INPUT_SOURCE_TYPE_IBUS = "ibus";

    const string[] MAIN_SOURCES = { "ara", "cn", "gb", "us", "fr", "de", "jp", "ru", "es" };

    public bool show_more { get; private set; }

    public signal void changed (InputInfo[] inputs);

    Gee.HashMap<InputInfo, InputRow> input_rows;
    Gnome.XkbInfo xkb_info;

#if HAVE_IBUS
    IBus.Bus ibus;
    Gee.HashMap<string, IBus.EngineDesc> ibus_engines;
    Cancellable ibus_cancellable;
#endif

    construct {
        xkb_info = new Gnome.XkbInfo ();

#if HAVE_IBUS
        IBus.init ();

        if (ibus != null) {
            ibus = new IBus.Bus.async ();

            if (ibus.is_connected ()) {
                fetch_ibus_engines ();
            } else {
                ibus.connected.connect (fetch_ibus_engines);
            }

            maybe_start_ibus ();
        }
#endif

        input_rows = new Gee.HashMap<InputInfo, InputRow> (InputInfo.hash, InputInfo.equal);

        current_input_list.set_sort_func (sort_inputs);
        input_list.set_sort_func (sort_inputs);
        input_list.set_filter_func (input_visible);

        get_locale_infos ();
#if HAVE_IBUS
        get_ibus_locale_infos ();
#endif

        filter_entry.changed.connect (() => {
            input_list.invalidate_filter ();
        });

        Addin.get_instance ().context.data_changed.connect ((key) => {
            if (key == "input-sources") {
                update_current ();
            }
        });
        update_current ();

        Idle.add_once (() => {
            filter_entry.can_focus = true;
        });
    }

    void update_current () {
        current_input_list.remove_all ();
        current_input_list.set_placeholder (new Gtk.Label (_("No input sources selected")) {
            height_request = 48,
            css_classes = { "error" }
        });
        foreach (var info in get_current_inputs ()) {
            current_input_list.append (new InputRow (info, get_row_name (info)) { is_selected = true });
        }

        sync_all_checkmarks (true);

        input_list.invalidate_sort ();
        input_list.invalidate_filter ();
    }

    public bool get_layout (string type, string id, out string layout, out string variant) {
        layout = "";
        variant = "";

        if (type == "xkb") {
            xkb_info.get_layout_info (id, null, null, out layout, out variant);
            return true;
        }

#if HAVE_IBUS
        if (type == "ibus") {
            IBus.EngineDesc? engine_desc = null;

            if (ibus_engines != null) {
                if (ibus_engines.has_key (id)) {
                    engine_desc = ibus_engines[id];
                }
            }

            if (engine_desc == null) {
                return false;
            }

            layout = engine_desc.get_layout ();
            variant = "";
            return true;
        }
#endif

        return false;
    }

    string get_row_name (InputInfo input_info) {
        if (input_info.type_ == INPUT_SOURCE_TYPE_XKB) {
            string display_name;
            xkb_info.get_layout_info (input_info.id, out display_name, null, null, null);
            return display_name;
#if HAVE_IBUS
        } else if (input_info.type_ == INPUT_SOURCE_TYPE_IBUS) {
            if (ibus_engines != null) {
                if (ibus_engines.has_key (input_info.id)) {
                    return ibus_engines[input_info.id].get_longname ();
                }
            }

            return input_info.id;
#endif
        }

        return "ERROR";
    }

    void sync_all_checkmarks (bool initial = false) {
        var current_inputs_info = get_current_inputs ();
        bool invalidate = false;

        foreach (var entry in input_rows) {
            var row_input_info = entry.key;
            var row = entry.value;
            bool is_selected = row_input_info in current_inputs_info;

            row.is_selected = is_selected;

            if (row.is_extra && is_selected) {
                debug (
                    "Marking selected layout %s (%s:%s) as non-extra",
                    row.name,
                    row_input_info.type_,
                    row_input_info.id
                );

                if (initial) {
                    row.is_extra = false;
                }
                invalidate = true;
            }
        }

        if (invalidate) {
            input_list.invalidate_sort ();
            input_list.invalidate_filter ();
        }
    }

    [GtkCallback]
    void row_activated (Gtk.ListBox list_box, Gtk.ListBoxRow row) {
        if (row == null) {
            return;
        }

        var current_inputs_info = get_current_inputs ();

        var input_row = (InputRow) row;
        input_row.is_selected = !input_row.is_selected;

        if (input_row.is_selected) {
            current_inputs_info.add (input_row.input_info);
        } else {
            current_inputs_info.remove (input_row.input_info);
        }

        set_current_inputs (current_inputs_info);
        changed (current_inputs_info.to_array ());

        sync_all_checkmarks ();

        update_input_list_visible ();
    }

    int sort_inputs (Gtk.ListBoxRow a, Gtk.ListBoxRow b) {
        var la = (InputRow) a;
        var lb = (InputRow) b;

        if (la == null) {
            return 1;
        }

        if (lb == null) {
            return -1;
        }

        if (la.is_extra && !lb.is_extra) {
            return 1;
        }

        if (!la.is_extra && lb.is_extra) {
            return -1;
        }

        return strcmp (la.name, lb.name);
    }

    void update_input_list_visible () {
        //  Update input_list widget visibility to hide it when no search bar and no more
        //  input sources provided
        input_list.visible = (MAIN_SOURCES.length != get_current_inputs ().size) || show_more;
    }

    bool input_visible (Gtk.ListBoxRow row) {
        var input_row = (InputRow) row;

        if (!show_more && input_row.is_extra) {
            return false;
        }

        foreach (var input_info in get_current_inputs ()) {
            if (!show_more && input_row.input_info.format == input_info.format) {
                return false;
            }
        }

        var search_query = filter_entry.text;
        if (search_query == null && search_query == "") {
            return false;
        }

        return search_query.match_string (input_row.title, true);
    }

    void get_locale_infos () {
        string type = null;
        string id = null;
        string lang = null;
        string country = null;

        var current_inputs_info = get_current_inputs ();

        if (Gnome.Languages.get_input_source_from_locale (get_current_language (), out type, out id)) {
            if (current_inputs_info.size == 0) {
                current_inputs_info.add (new InputInfo (type, id));
                set_current_inputs (current_inputs_info);
            }

            add_row_to_list (type, id, false);
        }

        if (!Gnome.Languages.parse_locale (get_current_language (), out lang, out country, null, null)) {
            return;
        }

        foreach (var mid in MAIN_SOURCES) {
            add_row_to_list (INPUT_SOURCE_TYPE_XKB, mid, false);
        }

        var list = xkb_info.get_layouts_for_language (lang);
        add_rows_to_list (list, INPUT_SOURCE_TYPE_XKB, id, true);

        if (country != null) {
            list = xkb_info.get_layouts_for_country (country);
            add_rows_to_list (list, INPUT_SOURCE_TYPE_XKB, id, true);
        }

        list = xkb_info.get_all_layouts ();
        add_rows_to_list (list, INPUT_SOURCE_TYPE_XKB, id, true);

        input_list.invalidate_sort ();
        input_list.invalidate_filter ();
    }

    void add_row_to_list (string type, string id, bool is_extra) {
        var tmp = new List<weak string> ();
        tmp.append (id);
        add_rows_to_list (tmp, type, null, is_extra);
    }

    void add_rows_to_list (List<weak string> list, string type, string? default_id, bool is_extra) {
        foreach (var id in list) {
            if (id == default_id) {
                continue;
            }

            var input_info = new InputInfo (type, id);
            var widget = new InputRow (input_info, get_row_name (input_info), is_extra);
            if (!input_rows.has_key (input_info)) {
                input_rows.set (input_info, widget);
                input_list.append (widget);
            }
        }
    }

#if HAVE_IBUS
    void update_ibus_active_sources () {
        bool invalidate = false;

        foreach (var entry in input_rows) {
            var row_input_info = entry.key;
            var row = entry.value;

            if (row_input_info.type_ != INPUT_SOURCE_TYPE_IBUS) {
                continue;
            }

            if (!ibus_engines.has_key (row_input_info.id)) {
                continue;
            }

            var engine_desc = ibus_engines[row_input_info.id];
            if (engine_desc != null) {
                row.title = engine_desc.get_longname ();
                invalidate = true;
            }
        }

        if (invalidate) {
            input_list.invalidate_sort ();
            input_list.invalidate_filter ();
        }
    }

    void get_ibus_locale_infos () {
        if (ibus_engines == null) {
            return;
        }

        foreach (var entry in ibus_engines) {
            add_row_to_list (INPUT_SOURCE_TYPE_IBUS, entry.key, true);
        }
    }

    void fetch_ibus_engines () {
        ibus_cancellable = new Cancellable ();

        ibus.list_engines_async.begin (-1, ibus_cancellable, (obj, res) => {
            var list = new List<IBus.EngineDesc> ();

            try {
                list = ((IBus.Bus) obj).list_engines_async_finish (res);

            } catch (Error e) {
                warning ("Couldn't finish IBus request: %s", e.message);
                return;
            }

            ibus_cancellable = null;

            ibus_engines = new Gee.HashMap<string, IBus.EngineDesc> ();

            foreach (var engine_desc in list) {
                var engine_id = engine_desc.get_name ();
                if (!engine_id.has_prefix ("xkb:")) {
                    ibus_engines[engine_id] = engine_desc;
                }
            }

            update_ibus_active_sources ();
            get_ibus_locale_infos ();

            sync_all_checkmarks ();
        });

        ibus.connected.disconnect (fetch_ibus_engines);
    }

    void maybe_start_ibus () {
        /* IBus doesn't export API in the session bus. The only thing
         * we have there is a well known name which we can use as a
         * sure-fire way to activate it.
         */
        Bus.unwatch_name (Bus.watch_name (BusType.SESSION, IBus.SERVICE_IBUS, BusNameWatcherFlags.AUTO_START));
    }
#endif

    public void clear_filter () {
        filter_entry.text = "";
    }

    [GtkCallback]
    void show_more_clicked () {
        input_list.set_placeholder (new Gtk.Label (_("Nothing found")) {
            height_request = 48
        });

        filter_entry.grab_focus ();

        show_more = true;
        input_list.invalidate_filter ();

        update_input_list_visible ();
    }
}
