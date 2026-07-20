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

    public HashTable<string, string> get_raw_string () {
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

    public void set_raw (string key, string value) {
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

    public void register_vars (string module_name, HashTable<string, ContextVarInfo> vars) {
        vars.foreach ((key, info) => {
            var module_key = "%s.%s".printf (module_name, key);

            if (data.has_key (module_key)) {
                warning ("Key %s already exists in context, it will be overwriting", module_key);
            }
            debug ("Registering key %s with type %s", module_key, info.value_type.to_string ());
            data[module_key] = new ValueObject (info);
            data[module_key].data_key = module_key;
            if (info.getter_func != null) {
                data[module_key].set_getter (info.getter_func);
            }
            if (info.setter_func != null) {
                data[module_key].set_setter (info.setter_func);
            }
            data[module_key].notify["real-value"].connect ((caller, param) => {
                data_changed (((ValueObject) caller).data_key);
            });
        });
    }

    public void load_from_keyfile (KeyFile keyfile, string group_name) throws Error {
        if (!keyfile.has_group (group_name)) {
            debug ("Keyfile doesn't have group '%s'", group_name);
            return;
        }

        foreach (var key in keyfile.get_keys (group_name)) {
            if (!data.has_key (key)) {
                warning ("Key %s not found in context, it will be ignored", key);
                continue;
            }

            Value val;

            if (data[key].value_type == OBJECT) {
                val = Object.new (
                    data[key].object_type,
                    "string-format", keyfile.get_string (group_name, key) ?? ""
                );

            } else {
                val = kf_value_to_value (
                    keyfile,
                    group_name,
                    key,
                    data[key].value_type.to_gtype ()
                );
            }

            set_value (key, val);
        }
    }
}

namespace ReadySet {
    internal Value kf_value_to_value (KeyFile keyfile, string group_name, string key, Type value_type) throws Error {
        if (value_type == Type.BOOLEAN) {
            return keyfile.get_boolean (group_name, key);
        } else if (value_type == Type.STRING) {
            return keyfile.get_string (group_name, key);
        } else if (value_type == typeof (string[])) {
            return keyfile.get_string_list (group_name, key);
        } else if (value_type == Type.INT || value_type == Type.INT64) {
            return keyfile.get_int64 (group_name, key);
        } else if (value_type == Type.DOUBLE) {
            return keyfile.get_double (group_name, key);
        } else {
            error ("Unknown keyfile desired type %s for key %s", value_type.name (), key);
        }
    }
}
