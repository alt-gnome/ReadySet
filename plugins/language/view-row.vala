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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Language/ui/view-row.ui")]
public sealed class Language.ViewRow : Gtk.Box {

    LocaleData _locale_data;
    public LocaleData locale_data {
        get {
            return _locale_data;
        }
        construct set {
            _locale_data = value;
            if (_locale_data != null) {
                title = _locale_data.country_loc;
                subtitle = _locale_data.country_cur;
            }
        }
    }

    public string title { get; set; }

    public string subtitle { get; set; }
}
