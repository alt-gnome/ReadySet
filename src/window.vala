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

[GtkTemplate (ui = "/org/altlinux/ReadySet/ui/window.ui")]
public sealed class ReadySet.Window: Adw.ApplicationWindow {

    [GtkChild]
    unowned Gtk.Stack stack;

    const ActionEntry[] ACTION_ENTRIES = {
        { "preferences", on_preferences_action },
        { "about", on_about_action },
    };

    public Window (ReadySet.Application app) {
        Object (application: app);
    }

    construct {
        add_action_entries (ACTION_ENTRIES, this);

        map.connect (window_initially_shown);

        if (Config.IS_DEVEL) {
            add_css_class ("devel");
        }
    }

    void window_initially_shown () {
        reload_window ();
        map.disconnect (window_initially_shown);
    }

    protected override bool close_request () {
        if (Config.IS_DEVEL) {
            return base.close_request ();
        }

        return true;
    }

    public void reload_window () {
        stack.visible_child_name = "load";
        build_content.begin ();
    }

    async void build_content () {
        var c = stack.get_child_by_name ("main");

        if (c != null) {
            stack.remove (c);
        }

        yield Application.get_default ().init_pages ();
        stack.add_named (new WindowContent (Application.get_default ().options_handler.simple), "main");

        stack.visible_child_name = "main";
    }

    void on_preferences_action () {
        message ("Hello, stranger…");
    }

    void on_about_action () {
        build_about ().present (this);
    }
}
