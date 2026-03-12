/* Copyright (C) 2024-2026 Vladimir Romanov <rirusha@altlinux.org>
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

[GtkTemplate (ui = "/org/altlinux/ReadySet/ui/window.ui")]
public sealed class ReadySet.Window: Adw.ApplicationWindow {

    [GtkChild]
    unowned Gtk.Stack stack;

    const string A_NAME = "a";
    const string B_NAME = "b";

    const ActionEntry[] ACTION_ENTRIES = {
        { "preferences", on_preferences_action },
        { "about", on_about_action },
    };

    Gtk.Widget? a_child {
        get {
            return stack.get_child_by_name (A_NAME);
        }
    }

    Gtk.Widget? b_child {
        get {
            return stack.get_child_by_name (B_NAME);
        }
    }

    string active;
    bool reloading = false;

    bool simple;

    public Window (ReadySet.Application app) {
        Object (application: app);
    }

    construct {
        add_action_entries (ACTION_ENTRIES, this);

        map.connect (window_initially_shown);

        simple = Application.get_default ().options_handler.simple;

        if (Config.IS_DEVEL) {
            add_css_class ("devel");
        }
    }

    void window_initially_shown () {
        reload_window ();
        map.disconnect (window_initially_shown);
    }

    protected override bool close_request () {
        if (Application.get_default ().can_close) {
            return base.close_request ();
        }

        return true;
    }

    public void reload_window () {
        if (reloading) {
            return;
        }

        reloading = true;
        Application.get_default ().init_pages.begin (set_window_content);
    }

    void set_window_content () {
        if (a_child == null) {
            active = A_NAME;
        } else if (b_child == null) {
            active = B_NAME;
        }

        stack.add_named (new WindowContent (simple), active);
        stack.set_visible_child_name (active);
        Timeout.add_once (stack.transition_duration, on_transition_ended);
    }

    void on_transition_ended () {
        Gtk.Widget? to_remove = null;

        if (active == A_NAME) {
            to_remove = b_child;
        } else if (active == B_NAME) {
            to_remove = a_child;
        }

        if (to_remove != null) {
            stack.remove (to_remove);
        }

        reloading = false;
    }

    void on_preferences_action () {
        message ("Hello, stranger…");
    }

    void on_about_action () {
        build_about ().present (this);
    }
}
