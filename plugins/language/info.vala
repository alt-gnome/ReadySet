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

public sealed class Language.Info : Gtk.Box {

    ReadySet.StatusPage icon = new ReadySet.StatusPage () {
        icon_name = "language-symbolic"
    };

    Language.SelectTitle desc = new Language.SelectTitle ();

    static construct {
        set_css_name ("langinfo");
    }

    construct {
        notify["css-classes"].connect (css_classes_changed);

        orientation = VERTICAL;
        spacing = 36;
        append (icon);
        append (desc);
    }

    void css_classes_changed () {
        if (has_css_class ("compact")) {
            icon.add_css_class ("compact");
            desc.add_css_class ("compact");
        } else {
            icon.remove_css_class ("compact");
            desc.remove_css_class ("compact");
        }
    }
}
