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
 * Base class for pages provided by step and installer plugins.
 *
 * Pages returned by {@link ReadySet.StepAddin.build_pages} and
 * {@link ReadySet.InstallerStep.build_page} use this class to expose their
 * content, auxiliary widgets, navigation state, and presentation metadata.
 */
public class ReadySet.BasePage : Adw.BreakpointBin {

    /**
     * Requests navigation to the next page.
     *
     * A page can emit this signal when an action inside its content should
     * behave like the application's continue button.
     */
    public signal void next ();

    /**
     * Widget that will be located on top in the vertical layout and in the
     * sidebar in the horizontal one.
     *
     * You shouldn't place any actionable widgets for better UX.
     */
    public Gtk.Widget? info { get; set; default = null; }

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
     * Show page or not.
     *
     * @see ReadySet.StepAddin
     */
    public virtual bool accessible { get; set; default = true; }

    /**
     * Current layout mode of page. Page can perform various tricks based
     * on the current layout.
     */
    public LayoutMode layout_mode { get; internal set; }

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

    /**
     * Handles an attempt to continue from this page.
     *
     * Override this method to validate or save the page state before
     * navigation. It is called when the application's continue button is
     * activated. If need to go next, emit {@link ReadySet.BasePage.next} signal.
     */
    public virtual void try_continue () {
        next ();
    }
}
