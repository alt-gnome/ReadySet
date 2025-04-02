/*
 * Copyright (C) 2025 Vladimir Vaskov <rirusha@altlinux.org>
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

[GtkTemplate (ui = "/space/rirusha/ReadySet/ui/window-content.ui")]
public sealed class ReadySet.WindowContent : Adw.BreakpointBin {

    [GtkChild]
    unowned Adw.OverlaySplitView split_view;
    [GtkChild]
    unowned StepsMainPage steps_main_page;

    construct {
        var settings = new Settings (Config.APP_ID);

        settings.bind ("show-steps", split_view, "show-sidebar", SettingsBindFlags.DEFAULT);

        foreach (string step_id in ReadySet.Application.get_default ().all_steps) {
            steps_main_page.add_page (build_page_by_step_id (step_id));
        }
        steps_main_page.add_page (build_page_by_step_id ("end"));
    }

    [GtkCallback]
    void close_sidebar () {
        split_view.show_sidebar = false;
    }
}
