/* Copyright 2024 rirusha
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

[GtkTemplate (ui = "/space/rirusha/ReadySet/ui/window.ui")]
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

        var settings = new Settings (Config.APP_ID);

        settings.bind ("window-width", this, "default-width", SettingsBindFlags.DEFAULT);
        settings.bind ("window-height", this, "default-height", SettingsBindFlags.DEFAULT);
        settings.bind ("window-maximized", this, "maximized", SettingsBindFlags.DEFAULT);

        build_content ();
    }

    public void reload_window () {
        stack.visible_child_name = "load";
        Timeout.add_once (300, build_content);
    }

    void build_content () {
        var c = stack.get_child_by_name ("main");

        if (c != null) {
            stack.remove (c);
        }

        stack.add_named (new WindowContent (), "main");

        stack.visible_child_name = "main";
    }

    void on_preferences_action () {
        message ("Hello, stranger…");
    }

    void on_about_action () {
        build_about ().present (this);
    }
}
