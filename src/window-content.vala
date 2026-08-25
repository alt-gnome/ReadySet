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

[GtkTemplate (ui = "/org/altlinux/ReadySet/ui/window-content.ui")]
public sealed class ReadySet.WindowContent : Adw.BreakpointBin {

    [GtkChild]
    unowned Adw.OverlaySplitView split_view;
    [GtkChild]
    unowned Adw.NavigationPage main_page;

    public bool show_steps_sidebar { get; construct; }

    public PagesModel model { get; construct; }

    public EndPageFactory end_page_factory { get; construct; }

    public string? force_layout { get; construct; }

    public bool sandbox { get; construct; }

    public bool show_sidebar { get; set; }

    public WindowContent (
        bool show_steps_sidebar,
        PagesModel model,
        EndPageFactory end_page_factory,
        string? force_layout,
        bool sandbox
    ) {
        Object (
            show_steps_sidebar: show_steps_sidebar,
            model: model,
            end_page_factory: end_page_factory,
            force_layout: force_layout,
            sandbox: sandbox
        );
    }

    static construct {
        install_property_action ("wincon.show-sidebar", "show-sidebar");
    }

    construct {
        split_view.enable_show_gesture = show_steps_sidebar;
        action_set_enabled ("wincon.show-sidebar", show_steps_sidebar);

        main_page.child = new StepsMainPage (
            model,
            end_page_factory,
            force_layout,
            sandbox
        );
    }

    [GtkCallback]
    void close_sidebar () {
        split_view.show_sidebar = false;
    }
}
