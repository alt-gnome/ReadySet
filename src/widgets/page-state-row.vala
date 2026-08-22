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

internal sealed class ReadySet.PageStateRow : Adw.ActionRow {

    public bool is_ready {
        get {
            return !has_css_class ("error");
        }
        set {
            if (value) {
                remove_css_class ("error");
            } else {
                add_css_class ("error");
            }
        }
    }

    public PageInfo info { get; construct; }

    public bool is_nested { get; construct; }

    public PageStateRow (PageInfo info) {
        Object (
            info: info,
            is_nested: false
        );
    }

    PageStateRow.nested (PageInfo info) {
        Object (
            info: info,
            is_nested: true
        );
    }

    construct {
        add_css_class ("property");

        title = info.title_header;

        if (!is_nested) {
            if (info.page is HasWidgetRepr) {
                var box = new Gtk.Box (VERTICAL, 12);

                box.append (new PageStateRow.nested (info));
                box.append (((HasWidgetRepr) info.page).get_widget_repr ());

                box.margin_bottom = box.margin_start = box.margin_end = 12;

                child = box;

            } else if (info.page is HasStringRepr) {
                subtitle = ((HasStringRepr) info.page).get_string_repr ();
            } else {
                assert_not_reached ();
            }
        }

        add_prefix (new Gtk.Image.from_icon_name (info.title_icon_name));
        add_suffix (new Gtk.Image.from_icon_name ("go-next-symbolic"));

        info.bind_property ("is-ready", this, "is-ready", SYNC_CREATE);
    }
}
