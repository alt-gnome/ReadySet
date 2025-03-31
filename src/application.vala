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

public sealed class ReadySet.Application: Adw.Application {

    public LanguagePageState lang_page_state { get; set; default = { false, 0.0, "" }; }

    const ActionEntry[] ACTION_ENTRIES = {
        { "quit", quit },
    };

    public Application () {
        Object (
            application_id: Config.APP_ID_DYN,
            resource_base_path: "/space/rirusha/ReadySet/"
        );
    }

    static construct {
        typeof (BasePage).ensure ();
        typeof (BasePageDesc).ensure ();
        typeof (StepsMainPage).ensure ();
        typeof (StepsSidebar).ensure ();
        typeof (StepRow).ensure ();
        typeof (CarouselPageTitles).ensure ();
        typeof (LangSelectTitle).ensure ();
    }

    construct {
        add_action_entries (ACTION_ENTRIES, this);
        set_accels_for_action ("app.quit", { "<primary>q" });
    }

    public void reload_window (LanguagePageState page_state) {
        this.lang_page_state = page_state;
        (active_window as ReadySet.Window)?.reload_window ();
    }

    public override void activate () {
        base.activate ();

        if (active_window == null) {
            var win = new Window (this);

            win.present ();

        } else {
            active_window.present ();
        }
    }
}
