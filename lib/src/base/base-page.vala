/*
 * Copyright (C) 2026 Vladimir Romanov <rirusha@altlinux.org>
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

/**
 * Base class for all pages that will be build via
 * {@link ReadySet.StepAddin.build_pages}.
 *
 * It has data for showing up widgets:
 * * info
 * * top_widget
 * * bottom_widget
 * * content
 *
 * And data for showing up in indicators:
 * * title_icon_name
 * * title_header
 */
public class ReadySet.BasePage : Adw.BreakpointBin {

    /**
     * Widget that will be located on top in the vertical layout and in the
     * sidebar in the horizontal one.
     *
     * You shouldn't place any actionable widgets for better UX.
     */
    public Gtk.Widget info { get; set; }

    /**
     * Widget that will be shown at top of the page in any layout.
     */
    public Gtk.Widget top_widget { get; set; }

    /**
     * Widget that will be shown at bottom of the page in any layout.
     */
    public Gtk.Widget bottom_widget { get; set; }

    /**
     * Icon that will be shown at header or steps sidebar.
     */
    public string title_icon_name { get; set; default = "dialog-error-symbolic"; }

    /**
     * Title that will be shown at header or steps sidebar.
     */
    public string title_header { get; set; default = _("Unknown"); }

    /**
     * If `true`, user can go to next page, and he doesn't otherwise.
     * Better to show message with information, why user can't go next.
     */
    public bool is_ready { get; set; default = false; }

    /**
     * @see ReadySet.StepAddin
     */
    public virtual bool accessible { get; set; default = true; }

    /**
     * Current layout mode of page. Page can perform various tricks based
     * on the current layout.
     */
    public LayoutMode layout_mode { get; internal set; }

    /**
     * Show or hide "Go up" button in main application when scroll
     * go down far enough.
     *
     * If you don't need that behavior, override property and return `false`.
     */
    public virtual bool need_go_up_button { get { return true; } }

    /**
     * Main content widget. It is main active zone for user.
     */
    public Gtk.Widget content {
        get {
            return child;
        }
        set {
            child = value;
        }
    }

    internal ReadySet.BasePage.unknown () {
        Object (
            info: new StatusPage () {
                icon_name = "dialog-error-symbolic",
                title = _("Unknown page")
            },
            content: new StatusPage () {
                description = _("This page says that your distribution has made a mistake.")
            }
        );
    }

    construct {
        valign = CENTER;
    }
}
