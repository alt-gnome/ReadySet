/*
 * Copyright (C) 2025 Vladimir Romanov <rirusha@altlinux.org>
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

public class ReadySet.Context : Object {

    public signal void reload_window ();

    public signal void data_changed (string key, Value new_value);

    Gee.HashMap<string, Value?> data = new Gee.HashMap<string, Value?> ();

    public string[] get_keys () {
        return data.keys.to_array ();
    }

    public bool has_data (string key) {
        return data.has_key (key);
    }

    public new void set_data (string key, Value value) {
        data[key] = value;
        data_changed (key, value);
    }

    public void set_string (string key, string value) {
        set_data (key, value);
    }

    public void set_boolean (string key, bool value) {
        set_data (key, value ? "true" : "false");
    }

    public new Value? get_data (string key) {
        if (!has_data (key)) {
            return null;
        }
        return data[key];
    }

    public string? get_string (string key) {
        if (!has_data (key)) {
            return null;
        }
        var val = data[key];
        if (val.holds (GLib.Type.STRING)) {
            return val.get_string ();
        } else {
            return null;
        }
    }

    public bool get_boolean (string key) {
        if (!has_data (key)) {
            return false;
        }

        var str = get_string (key);
        if (str == null) {
            return false;
        }

        return str == "true";
    }
}
