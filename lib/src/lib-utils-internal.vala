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

namespace ReadySet {

    internal void init_lib_css () {
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/org/altlinux/ReadySet/Lib/style.css");
        Gtk.StyleContext.add_provider_for_display (
            Gdk.Display.get_default (),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_THEME
        );
    }

    internal LayoutMode layout_mode_from_string (string str) {
        unowned EnumClass enum_class = (EnumClass) typeof (LayoutMode).class_peek ();
        var enum_value = enum_class.get_value_by_nick (str);
        if (enum_value == null) {
            error ("Unsupported enum value: %s", str);
        }
        return (LayoutMode) enum_value.value;
    }

    internal ApplyErrorData apply_error_to_data (ApplyError error) {
        try {
            return Serialize.JsonWorker.simple_from_json<ApplyErrorData> (error.message);
        } catch (Serialize.Error e) {
            //  It's not json string, just return message
            return new ApplyErrorData (_("Something went wrong"), error.message);
        }
    }
}
