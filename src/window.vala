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
    unowned Adw.NavigationView nav_view;

    const ActionEntry[] ACTION_ENTRIES = {
        { "preferences", on_preferences_action },
        { "about", on_about_action },
    };

    public Window (ReadySet.Application app) {
        Object (application: app);
    }

    static construct {
        typeof (WelcomePage).ensure ();
        typeof (LanguagesBox).ensure ();
        typeof (BasePage).ensure ();
    }

    construct {
        BasePage.root_view = nav_view;

        var settings = new Settings (Config.APP_ID);

        add_action_entries (ACTION_ENTRIES, this);

        settings.bind ("window-width", this, "default-width", SettingsBindFlags.DEFAULT);
        settings.bind ("window-height", this, "default-height", SettingsBindFlags.DEFAULT);
        settings.bind ("window-maximized", this, "maximized", SettingsBindFlags.DEFAULT);
    }

    void on_preferences_action () {
        message ("Hello, stranger…");
    }

    void on_about_action () {
        build_about ().present (this);
    }
}
