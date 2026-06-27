/*
 * Copyright (C) 2024-2026 Vladimir Romanov <rirusha@altlinux.org>
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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Keyboard/ui/input-sources-dialog.ui")]
public sealed class Keyboard.InputSourcesDialog : Adw.Dialog {

    [GtkChild]
    unowned Gtk.ListView view;
    [GtkChild]
    unowned Gtk.ToggleButton search_button;
    [GtkChild]
    unowned Gtk.SearchEntry search_entry;
    [GtkChild]
    unowned Gtk.Stack title_stack;

    bool _show_more = false;
    public bool show_more {
        get {
            return _show_more;
        }
        set {
            _show_more = value;
            extra_filter.changed (Gtk.FilterChange.DIFFERENT);
        }
    }

    Gtk.NoSelection model;

    Gtk.Filter current_filter;
    Gtk.Filter search_filter;
    Gtk.Filter extra_filter;

    construct {
        search_entry.changed.connect (search_query_changed);
        search_button.notify["active"].connect (search_mode_changed);

        current_filter = new Gtk.CustomFilter (current_match_func);
        search_filter = new Gtk.CustomFilter (search_match_func);
        extra_filter = new Gtk.CustomFilter (extra_match_func);

        Addin.get_instance ().context.data_changed.connect (on_context_data_changed);
        update ();

        var filter = new Gtk.EveryFilter ();
        var filter_model = new Gtk.FilterListModel (
            Addin.get_instance ().is_manager.sources_model,
            build_filter ()
        );
        model = new Gtk.NoSelection (filter_model);

        view.model = model;

        closed.connect (on_close);
    }

    void on_close () {
        show_more = false;
    }

    void search_query_changed () {
        search_filter.changed (Gtk.FilterChange.DIFFERENT);
    }

    void search_mode_changed () {
        if (search_button.active) {
            title_stack.visible_child_name = "search";
            search_entry.grab_focus ();
        } else {
            title_stack.visible_child_name = "main";
        }
    }

    void on_context_data_changed (string key) {
        if (key == "keyboard.input-sources") {
            update ();
        }
    }

    bool current_match_func (Object el) {
        var info = (InputInfo) el;

        return !(info in get_current_inputs ());
    }

    bool search_match_func (Object el) {
        var info = (InputInfo) el;

        var name = Addin.get_instance ().is_manager.get_humanity_name (info);

        if (name == null) {
            return false;
        }

        var search_query = search_entry.text;
        if (search_query == null && search_query == "") {
            return true;
        }

        return search_query.match_string (name, true);
    }

    bool extra_match_func (Object el) {
        var info = (InputInfo) el;

        return show_more || !info.is_extra;
    }

    Gtk.Filter build_filter () {
        var filter = new Gtk.EveryFilter ();

        filter.append (current_filter);
        filter.append (search_filter);
        filter.append (extra_filter);

        return filter;
    }

    void update () {
        current_filter.changed (Gtk.FilterChange.DIFFERENT);
    }

    [GtkCallback]
    void on_listview_activate (uint position) {
        var info = (InputInfo?) model.get_object (position);

        if (info == null) {
            return;
        }

        var inputs = get_current_inputs ();

        inputs.add (info);

        set_current_inputs (inputs);
        close ();
    }

    [GtkCallback]
    void on_buttonrow_activated () {
        show_more = true;
    }
}
