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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Lib/ui/base/status-page.ui")]
public sealed class ReadySet.StatusPage : Adw.Bin {

    public Gdk.Paintable paintable { get; set; }

    public string icon_name { get; set; }

    public string title { get; set; }

    public string description { get; set; }
 
    static construct {
        set_css_name ("rsstatuspage");
    }

    [GtkCallback]
    bool has_image (string? icon_naname, Gdk.Paintable? paintable) {
        return paintable != null || (icon_name != null && icon_name != "");
    }

    [GtkCallback]
    bool string_is_not_empty (string? str) {
        return str != null && str != "";
    }
}
