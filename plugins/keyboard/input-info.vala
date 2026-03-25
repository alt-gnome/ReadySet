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

public class Keyboard.InputInfo : Object {

    public string id { get; construct; }

    public string layout { get; construct; }

    public string? variant { get; construct; }

    public string type_ { get; construct; }

    public string format { get; construct; }

    public bool is_latin { get; construct; }

    public InputInfo (string type, string id_) {
        Object (
            id: id_,
            type_: type,
            format: "%s::%s".printf (type, id_)
        );
    }

    public InputInfo.from_format (string format) {
        var parts = format.split ("::", 2);
        if (parts.length != 2) {
            error ("Invalid input sources format: `%s`", format);
        }
        Object (
            id: parts[1],
            type_: parts[0],
            format: format
        );
    }

    construct {
        var parts = id.split ("+", 2);
        layout = parts[0];
        if (parts.length == 2) {
            variant = parts[1];
        }

        if (type_ == "xkb") {
            is_latin = xkb_has_latin (layout, variant);
        }
    }

    public uint _hash () {
        return format.hash ();
    }

    public static uint hash (InputInfo a) {
        return a._hash ();
    }

    public static bool equal (InputInfo a, InputInfo b) {
        return strcmp (a.format, b.format) == 0;
    }
}
