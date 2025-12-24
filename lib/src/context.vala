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

    public bool idle { get; construct; default = true; }

    public signal void reload_window ();

    public signal void data_changed (string key);

    KeyFile data = new KeyFile ();

    const string GN = "MAIN";

    public Context (bool idle) {
        Object (
            idle: idle
        );
    }

    construct {
        data.set_list_separator (',');
    }

    public void load_from_keyfile (KeyFile keyfile, string group_name) throws Error {
        foreach (var key in keyfile.get_keys (group_name)) {
            set_raw (key, keyfile.get_value (group_name, key));
        }
    }

    public string[] get_keys () {
        try {
            return data.get_keys (GN);
        } catch (Error e) {
            return {};
        }
    }

    public bool has_key (string key) {
        try {
            return data.has_key (GN, key);
        } catch (Error e) {
            return false;
        }
    }

    public void set_raw (string key, owned string value) {
        data.set_value (GN, key, value);
        data_changed (key);
    }

    public string? get_raw (string key) {
        try {
            return data.get_value (GN, key);
        } catch (Error e) {
            return null;
        }
    }

    public void set_string (string key, owned string value) {
        data.set_string (GN, key, value);
        data_changed (key);
    }

    public string? get_string (string key) {
        try {
            return data.get_string (GN, key);
        } catch (Error e) {
            return null;
        }
    }

    public void set_boolean (string key, bool value) {
        data.set_boolean (GN, key, value);
        data_changed (key);
    }

    public bool get_boolean (string key) {
        try {
            return data.get_boolean (GN, key);
        } catch (Error e) {
            return false;
        }
    }

    public void set_strv (string key, owned string[] value) {
        data.set_string_list (GN, key, value);
        data_changed (key);
    }

    public string[]? get_strv (string key) {
        try {
            return data.get_string_list (GN, key);
        } catch (Error e) {
            return null;
        }
    }

    public void set_int (string key, int value) {
        data.set_int64 (GN, key, value);
        data_changed (key);
    }

    public int64 get_int (string key) {
        try {
            return data.get_int64 (GN, key);
        } catch (Error e) {
            return 0;
        }
    }

    public void set_double (string key, double value) {
        data.set_double (GN, key, value);
        data_changed (key);
    }

    public double get_double (string key) {
        try {
            return data.get_double (GN, key);
        } catch (Error e) {
            return 0.0;
        }
    }
}
