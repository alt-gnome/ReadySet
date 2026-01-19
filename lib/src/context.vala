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

public enum ReadySet.ContextType {
    STRING,
    BOOLEAN,
    STRV,
    INT,
    DOUBLE;

    public static ContextType from_gtype (Type t) {
        if (t == Type.STRING) {
            return STRING;
        } else if (t == Type.BOOLEAN) {
            return BOOLEAN;
        } else if (t == typeof (string[])) {
            return STRV;
        } else if (t == Type.INT || t == Type.INT64) {
            return INT;
        } else if (t == Type.DOUBLE) {
            return DOUBLE;
        } else {
            error ("Unknown type: %s", t.name ());
        }
    }

    public Type to_gtype () {
        switch (this) {
            case STRING:
                return Type.STRING;
            case BOOLEAN:
                return Type.BOOLEAN;
            case STRV:
                return typeof (string[]);
            case INT:
                return Type.INT;
            case DOUBLE:
                return Type.DOUBLE;
            default:
                assert_not_reached ();
        }
    }

    public string to_string () {
        return to_gtype ().name ();
    }
}

protected class ReadySet.ValueObject : Object {

    Value _value;
    public Value real_value {
        owned get {
            var new_val = Value (value_type.to_gtype ());
            if (getter_func != null) {
                getter_func (ref _value).copy (ref new_val);
            } else {
                _value.copy (ref new_val);
            }
            return new_val;
        }
        set {
            if (setter_func != null) {
                setter_func (ref _value, value);
            } else {
                value.copy (ref _value);
            }
        }
    }

    unowned ContextGetterFunc? getter_func = null;
    unowned ContextSetterFunc? setter_func = null;

    public ContextType value_type { get; construct; }

    public ValueObject (ContextType value_type) {
        Object (
            value_type: value_type
        );
    }

    public void set_getter (ContextGetterFunc func) {
        getter_func = func;
    }

    public void set_setter (ContextSetterFunc func) {
        setter_func = func;
    }

    construct {
        _value = Value (value_type.to_gtype ());
        if (value_type == STRING) {
            _value.set_string ("");
        }
    }
}

public class ReadySet.ContextVarInfo : Object {

    public ContextType value_type { get; construct; }

    public unowned ContextGetterFunc? getter_func = null;

    public unowned ContextSetterFunc? setter_func = null;

    public ContextVarInfo (ContextType value_type) {
        Object (
            value_type: value_type
        );
    }
}

public class ReadySet.Context : Object {

    public bool idle { get; construct; default = true; }

    public signal void reload_window ();

    public signal void data_changed (string key);

    HashTable<string, ValueObject> data = new HashTable<string, ValueObject> (str_hash, str_equal);

    public Context (bool idle) {
        Object (
            idle: idle
        );
    }

    public unowned Binding? bind_context_to_property (
        string source_key,
        Object target,
        string target_property,
        BindingFlags flags = DEFAULT
    ) {
        check_bind (source_key, target, target_property, flags);

        //  Invert functions exists because of GObject don't store INVERT_BOOLEAN flag
        //  when at least one of properties not boolean (or if transform function used).
        //  So we just use another transform functions.
        if ((BindingFlags.INVERT_BOOLEAN & flags) != 0) {
            return data[source_key].bind_property (
                "real-value",
                target,
                target_property,
                flags,
                transform_ctx_to_prop_invert,
                transform_prop_to_ctx_invert
            );
        } else {
            return data[source_key].bind_property (
                "real-value",
                target,
                target_property,
                flags,
                transform_ctx_to_prop,
                transform_prop_to_ctx
            );
        }
    }

    public unowned Binding? bind_property_to_context (
        Object source,
        string source_property,
        string target_key,
        BindingFlags flags = DEFAULT
    ) {
        check_bind (target_key, source, source_property, flags);

        //  Invert functions exists because of GObject don't store INVERT_BOOLEAN flag
        //  when at least one of properties not boolean (or if transform function used).
        //  So we just use another transform functions.
        if ((BindingFlags.INVERT_BOOLEAN & flags) != 0) {
            return source.bind_property (
                source_property,
                data[target_key],
                "real-value",
                flags,
                transform_prop_to_ctx_invert,
                transform_ctx_to_prop_invert
            );
        } else {
            return source.bind_property (
                source_property,
                data[target_key],
                "real-value",
                flags,
                transform_prop_to_ctx,
                transform_ctx_to_prop
            );
        }
    }

    bool check_bind (
        string context_key,
        Object obj,
        string property,
        BindingFlags flags = DEFAULT
    ) {
        var prop = obj.get_class ().find_property (property);
        if (prop == null) {
            warning ("Property %s not found in %s", property, obj.get_type ().name ());
            return false;
        }

        check_key (context_key, ContextType.from_gtype (prop.value_type));

        if (
            ((BindingFlags.INVERT_BOOLEAN & flags) != 0)
            && (prop.value_type != Type.BOOLEAN || data[context_key].value_type != ContextType.BOOLEAN)
        ) {
            warning ("Property or context key %s is not a boolean", context_key);
            return false;
        }

        return true;
    }

    bool transform_ctx_to_prop (Binding binding, Value from_value, ref Value to_value) {
        return ((Value*) from_value.get_boxed ()).transform (ref to_value);
    }

    bool transform_prop_to_ctx (Binding binding, Value from_value, ref Value to_value) {
        var new_val = Value (from_value.type ());
        from_value.copy (ref new_val);
        to_value.set_boxed (&new_val);
        return true;
    }

    bool transform_ctx_to_prop_invert (Binding binding, Value from_value, ref Value to_value) {
        to_value.set_boolean (!((Value*) from_value.get_boxed ()).get_boolean ());
        return true;
    }

    bool transform_prop_to_ctx_invert (Binding binding, Value from_value, ref Value to_value) {
        var new_val = Value (Type.BOOLEAN);
        new_val.set_boolean (!from_value.get_boolean ());
        to_value.set_boxed (&new_val);
        return true;
    }

    public void set_raw (string key, string value) {
        if (!check_key (key)) {
            return;
        }

        var temp_kf = new KeyFile ();
        temp_kf.set_list_separator (',');

        const string INTERNAL_KEY = "raw-key";
        const string INTERNAL_GROUP = "raw-group";

        temp_kf.set_value (INTERNAL_GROUP, INTERNAL_KEY, value);
        try {
            set_value (key, kf_value_to_value (
                temp_kf,
                INTERNAL_GROUP,
                INTERNAL_KEY,
                data[key].value_type.to_gtype ()
            ));
        } catch (Error e) {
            warning ("Error setting row value for key %s: %s", key, e.message);
        }
    }

    public HashTable<string, Value?> get_raw_context () {
        var raw_data = new HashTable<string, Value?> (str_hash, str_equal);
        data.foreach ((key, value) => {
            var val = Value (value.value_type.to_gtype ());
            var rv = value.real_value;
            rv.copy (ref val);
            raw_data[key] = val;
        });
        return raw_data;
    }

    public void register_vars (HashTable<string, ContextVarInfo> vars) {
        vars.foreach ((key, info) => {
            if (data.contains (key)) {
                warning ("Key %s already exists in context, it will be overwriting", key);
            }
            debug ("Registering key %s with type %s", key, info.value_type.to_string ());
            data[key] = new ValueObject (info.value_type);
            if (info.getter_func != null) {
                data[key].set_getter (info.getter_func);
            }
            if (info.setter_func != null) {
                data[key].set_setter (info.setter_func);
            }
            data[key].notify["real-value"].connect (() => {
                data_changed (key);
            });
        });
    }

    public void load_from_keyfile (KeyFile keyfile, string group_name) throws Error {
        foreach (var key in keyfile.get_keys (group_name)) {
            if (!data.contains (key)) {
                warning ("Key %s not found in context, it will be ignored", key);
                continue;
            }

            set_value (key, kf_value_to_value (
                keyfile,
                group_name,
                key,
                data[key].value_type.to_gtype ()
            ));
        }
    }

    bool check_key (string key, ContextType? value_type = null) {
        if (!has_key (key)) {
            warning ("Key %s not found in context", key);
            return false;
        }

        if (value_type != null) {
            if (!(data[key].value_type == value_type)) {
                warning (
                    "Type of context var %s with key %s and desired type %s don't match",
                    data[key].value_type.to_string (),
                    key,
                    value_type.to_string ()
                );
                return false;
            }
        }

        return true;
    }

    public string[] get_keys () {
        return data.get_keys_as_array ();
    }

    public bool has_key (string key) {
        return data.contains (key);
    }

    public ContextType get_value_type (string key) {
        if (check_key (key)) {
            return data[key].value_type;
        } else {
            error ("Key %s not found in context", key);
        }
    }

    public void set_value (string key, owned Value value) {
        if (check_key (key, ContextType.from_gtype (value.type ()))) {
            data[key].real_value = value;
        }
    }

    public Value? get_value (string key) {
        if (check_key (key)) {
            return data[key].real_value;
        } else {
            return null;
        }
    }

    public void set_string (string key, owned string value) {
        set_value (key, value);
    }

    public string? get_string (string key) {
        if (check_key (key, STRING)) {
            return data[key].real_value.dup_string ();
        } else {
            return null;
        }
    }

    public void set_boolean (string key, bool value) {
        set_value (key, value);
    }

    public bool get_boolean (string key) {
        if (check_key (key, BOOLEAN)) {
            return data[key].real_value.get_boolean ();
        } else {
            return false;
        }
    }

    public void set_strv (string key, owned string[] value) {
        set_value (key, value);
    }

    public string[] get_strv (string key) {
        if (check_key (key, STRV)) {
            //  I don't know how boxed types works, but wuthout this hack
            //  get_strv returns empty array
            var god_protect_our_souls = Uuid.string_random ();
            return string.joinv (god_protect_our_souls, (string[]) data[key].real_value.get_boxed ()).split (god_protect_our_souls);
        } else {
            return {};
        }
    }

    public void set_int (string key, int64 value) {
        set_value (key, value);
    }

    public int64 get_int (string key) {
        if (check_key (key, INT)) {
            return data[key].real_value.get_int64 ();
        } else {
            return 0;
        }
    }

    public void set_double (string key, double value) {
        set_value (key, value);
    }

    public double get_double (string key) {
        if (check_key (key, DOUBLE)) {
            return data[key].real_value.get_double ();
        } else {
            return 0;
        }
    }
}
