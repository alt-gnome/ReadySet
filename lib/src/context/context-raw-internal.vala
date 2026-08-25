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

public partial class ReadySet.Context {

    internal HashTable<string, string> get_raw_string () {
        var raw_data = new HashTable<string, string> (str_hash, str_equal);

        foreach (var key in get_keys ()) {
            string str;
            switch (data[key].value_type) {
                case ContextType.STRING:
                    str = get_string (key);
                    break;
                case ContextType.STRV:
                    str = string.joinv (",", get_strv (key));
                    break;
                case ContextType.INT:
                    str = get_int (key).to_string ();
                    break;
                case ContextType.DOUBLE:
                    str = get_double (key).to_string ();
                    break;
                case ContextType.BOOLEAN:
                    str = get_boolean (key).to_string ();
                    break;
                case ContextType.OBJECT:
                    str = get_object (key).string_format;
                    break;
                default:
                    assert_not_reached ();
            }
            raw_data[key] = str;
        }

        return raw_data;
    }

    internal void set_raw (string key, string value) {
        if (!has_key (key)) {
            return;
        }

        var temp_kf = new KeyFile ();
        temp_kf.set_list_separator (',');

        const string INTERNAL_GROUP = "raw-group";

        temp_kf.set_value (INTERNAL_GROUP, key, value);
        try {
            load_from_keyfile (temp_kf, INTERNAL_GROUP);
        } catch (Error e) {
            warning ("Error setting row value for key %s: %s", key, e.message);
        }
    }
}
