/*
 * Copyright (C) 2025 Vladimir Romanov <rirusha@altlinux.org>
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

[GtkTemplate (ui = "/org/altlinux/ReadySet/ui/window-content.ui")]
public sealed class ReadySet.WindowContent : Adw.BreakpointBin {

    [GtkChild]
    unowned Adw.OverlaySplitView split_view;
    [GtkChild]
    unowned StepsMainPage steps_main_page;

    static string[] saved_all_steps = {};

    construct {
        GLib.Application.get_default ().bind_property (
            "show-steps",
            split_view,
            "show-sidebar",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE
        );

        if (saved_all_steps.length == 0) {
            saved_all_steps = get_all_steps ();
        }

        var app = (ReadySet.Application) GLib.Application.get_default ();
        app.callback_pages.clear ();

        foreach (string step_id in saved_all_steps) {
            var page = build_page_by_step_id (step_id);
            if (page.allowed ()) {
                steps_main_page.add_page (page);
                app.callback_pages.add (page);
            }
        }
    }

    [GtkCallback]
    void close_sidebar () {
        split_view.show_sidebar = false;
    }
}
