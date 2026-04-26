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

public class ReadySet.BasePage : Adw.BreakpointBin {

    public Gtk.Widget info { get; set; }

    public Gtk.Widget top_widget { get; set; }

    public Gtk.Widget bottom_widget { get; set; }

    public string title_icon_name { get; set; default = "dialog-error-symbolic"; }

    public string title_header { get; set; default = _("Unknown"); }

    public bool is_ready { get; set; default = false; }

    public virtual bool accessible { get; set; default = true; }

    public virtual LayoutMode layout_mode { get; set; }

    public Gtk.Widget content {
        get {
            return child;
        }
        set {
            child = value;
        }
    }

    public ReadySet.BasePage.unknown () {
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
