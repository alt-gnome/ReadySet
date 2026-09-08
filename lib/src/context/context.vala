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

/**
 * Value type stored in context. {@link ReadySet.ContextType.OBJECT}
 * allows to store only {@link ReadySet.ContextObject}.
 *
 * @see ReadySet.Context
 */
public enum ReadySet.ContextType {
    /**
     * A UTF-8 string represented by {@link GLib.Type.STRING}.
     */
    STRING,
    /**
     * A boolean represented by {@link GLib.Type.BOOLEAN}.
     */
    BOOLEAN,
    /**
     * A null-terminated string array.
     */
    STRV,
    /**
     * A 64-bit signed integer represented by {@link GLib.Type.INT64}.
     */
    INT,
    /**
     * A double-precision floating-point number.
     */
    DOUBLE,
    /**
     * A subclass of {@link ReadySet.ContextObject}.
     */
    OBJECT;

    internal static ContextType from_gtype (Type t) {
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
        } else if (t.is_a (typeof (ContextObject))) {
            return OBJECT;
        } else {
            error ("Unknown type: %s", t.name ());
        }
    }

    internal Type to_gtype () {
        switch (this) {
            case STRING:
                return Type.STRING;
            case BOOLEAN:
                return Type.BOOLEAN;
            case STRV:
                return typeof (string[]);
            case INT:
                return Type.INT64;
            case DOUBLE:
                return Type.DOUBLE;
            case OBJECT:
                return typeof (ContextObject);
            default:
                assert_not_reached ();
        }
    }

    internal string to_string () {
        return to_gtype ().name ();
    }
}

internal partial class ReadySet.ValueObject : Object {

    Value _value;
    public Value real_value {
        owned get {
            var new_val = Value (_value.type ());
            if (getter_func != null) {
                getter_func ().copy (ref new_val);
            } else {
                _value.copy (ref new_val);
            }
            return new_val;
        }
        set {
            if (locked) {
                warning ("Cannot set value of locked variable");
                return;
            }

            if (setter_func != null) {
                setter_func (value);
            } else {
                if (value_type == OBJECT) {
                    _value.set_object (value.get_object ());
                } else {
                    value.copy (ref _value);
                }
            }
        }
    }

    public bool locked { get; private set; }

    public Value? default_value { get; construct; }

    public bool setting { get; set; default = false; }

    unowned ContextGetterFunc? getter_func = null;
    unowned ContextSetterFunc? setter_func = null;

    public ContextType value_type { get; construct; }

    public Type object_type { get; construct; }

    public ValueObject (ContextVarInfo info) {
        Object (
            value_type: info.value_type,
            default_value: info.default_value,
            object_type: info.nested_object_type,
            setting: info.setting
        );
    }

    construct {
        if (value_type == STRING && default_value == null) {
            default_value = "";
        }

        Type gtype;
        if (value_type == OBJECT) {
            gtype = object_type;
        } else {
            gtype = value_type.to_gtype ();
        }

        _value = Value (gtype);
        reset ();
    }

    public void reset () {
        if (default_value == null) {
            return;
        }

        if (value_type == OBJECT) {
            real_value = ((ContextObject) default_value.get_object ()).copy ();
        } else {
            real_value = default_value;
        }
    }
}

/**
 * Information about context value. Needs for registration and used in
 * {@link ReadySet.ExtensionBase.get_context_vars}.
 *
 * @see ReadySet.Context
 */
public class ReadySet.ContextVarInfo : Object {

    /**
     * Type of value stored in the context variable.
     */
    public ContextType value_type { get; construct; }

    /**
     * Default value. Needs for resettings value via {@link Context.reset}.
     */
    public Value? default_value { get; construct; }

    /**
     * Whether this variable is a setting. Settings could be set only with
     * config/cli options.
     */
    public bool setting { get; set; default = false; }

    /**
     * Func that will be used as get function.
     */
    public unowned ContextGetterFunc? getter_func = null;

    /**
     * Func that will be used as set function.
     */
    public unowned ContextSetterFunc? setter_func = null;

    /**
     * Concrete {@link ReadySet.ContextObject} type stored by an object
     * variable.
     *
     * This is {@link GLib.Type.NONE} for non-object variables.
     */
    public Type nested_object_type { get; construct; }

    /**
     * Creates metadata for a non-object context variable.
     *
     * Use `object` constructor for
     * {@link ReadySet.ContextType.OBJECT}. When supplied, `default_value`
     * must have the GLib type represented by `value_type`.
     *
     * @param value_type the type of the context variable
     * @param default_value the value restored by {@link Context.reset}, or
     * `null` when the variable has no explicit default
     */
    public ContextVarInfo (ContextType value_type, Value? default_value = null) {
        if (value_type == OBJECT) {
            error ("Use `object' constructor instead of this");
        }

        Object (
            value_type: value_type,
            default_value: default_value,
            nested_object_type: Type.NONE
        );
    }

    /**
     * Creates metadata for an object context variable.
     *
     * `nested_object_type` must be a concrete
     * {@link ReadySet.ContextObject} type. When supplied, `default_value`
     * must contain an object of exactly that type.
     *
     * @param nested_object_type the concrete object type stored by the
     * variable
     * @param default_value the value restored by {@link Context.reset}, or
     * `null` when the variable has no default
     */
    public ContextVarInfo.object (Type nested_object_type, Value? default_value = null) {
        Object (
            value_type: ContextType.OBJECT,
            default_value: default_value,
            nested_object_type: nested_object_type
        );
    }

    construct {
        if (default_value != null) {
            if (value_type == ContextType.OBJECT) {
                assert (nested_object_type == default_value.get_object ().get_type ());
            } else {
                assert (value_type == ContextType.from_gtype (default_value.type ()));
            }
        }
    }
}

/**
 * Shared state used for communication between plugins and the application.
 *
 * Extensions declare variables through
 * {@link ReadySet.ExtensionBase.get_context_vars}. Consumers can then access
 * registered values by key or bind them to GObject properties.
 */
public partial class ReadySet.Context : Object {

    /**
     * Whether the application is running in sandbox mode.
     *
     * Plugins must avoid modifying the host system when this is `true` and
     * should avoid host system-bus calls. This allows the application to run
     * safely in test environments such as container.
     */
    public bool sandbox { get; construct; default = true; }

    /**
     * Current application mode.
     *
     * Plugins can use this value to adapt their behavior to initial setup,
     * installation, or existing-user sessions.
     */
    public Mode mode { get; private set; }

    /**
     * Emitted after the value identified by `key` changes.
     *
     * @param key the key of the changed context variable
     */
    public signal void data_changed (string key);

    Gee.HashMap<string, ValueObject> data = new Gee.HashMap<string, ValueObject> ();

    internal Context (bool sandbox) {
        Object (
            sandbox: sandbox
        );
    }

    /**
     * Binds a context value to a GObject property.
     *
     * `source_key` must identify a registered variable compatible with the
     * target property. {@link GLib.BindingFlags.INVERT_BOOLEAN} can only be
     * used when both values are boolean. Other binding flags have the same
     * meaning as in {@link GLib.Object.bind_property}.
     *
     * @param source_key the registered context key
     * @param target the object that owns the target property
     * @param target_property the target property name
     * @param flags flags controlling the binding
     * @return the newly created binding
     */
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

    /**
     * Binds a GObject property to a context value.
     *
     * `target_key` must identify a registered variable compatible with the
     * source property. {@link GLib.BindingFlags.INVERT_BOOLEAN} can only be
     * used when both values are boolean. Other binding flags have the same
     * meaning as in {@link GLib.Object.bind_property}.
     *
     * @param source the object that owns the source property
     * @param source_property the source property name
     * @param target_key the registered context key
     * @param flags flags controlling the binding
     * @return the newly created binding
     */
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

    /**
     * Returns all registered context keys.
     *
     * @return a newly allocated array of keys
     */
    public string[] get_keys () {
        return data.keys.to_array ();
    }

    /**
     * Checks whether a key is registered.
     *
     * @param key the context key to look up
     * @return `true` when the key is registered
     */
    public bool has_key (string key) {
        return data.has_key (key);
    }

    /**
     * Returns the value type of a registered key.
     *
     * Passing an unknown key causes a fatal error.
     *
     * @param key a registered context key
     * @return the key's value type
     */
    public ContextType get_value_type (string key) {
        if (check_key (key)) {
            return data[key].value_type;
        } else {
            error ("Key %s not found in context", key);
        }
    }

    /**
     * Sets a registered context value.
     *
     * The value must match the key's declared type. Object values must have
     * exactly the concrete type declared by
     * {@link ReadySet.ContextVarInfo.nested_object_type}.
     *
     * @param key a registered context key
     * @param value the new value
     */
    public void set_value (string key, owned Value value) {
        bool res;
        if (data[key].value_type == OBJECT) {
            res = data[key].object_type == value.get_object ().get_type ();
        } else {
            res = check_key (key, ContextType.from_gtype (value.type ()));
        }

        if (res) {
            data[key].real_value = value;
        }
    }

    /**
     * Gets a copy of a registered context value.
     *
     * @param key the context key to read
     * @return the value, or `null` when the key is unknown
     */
    public Value? get_value (string key) {
        if (check_key (key)) {
            return data[key].real_value;
        } else {
            return null;
        }
    }

    /**
     * Sets an object context value.
     *
     * The object's concrete type must match the type registered for `key`.
     *
     * @param key a registered object key
     * @param value the new object value
     */
    public void set_object (string key, owned ContextObject value) {
        set_value (key, value);
    }

    /**
     * Creates and sets an object value from its string representation.
     *
     * The concrete object type registered for `key` must provide a
     * `string-format` property.
     *
     * @param key a registered object key
     * @param value the object's string representation
     */
    public void set_object_string (string key, owned string value) {
        if (check_key (key)) {
            set_object (key, (ContextObject) Object.new (
                data[key].object_type,
                "string-format", value ?? ""
            ));
        }
    }

    /**
     * Gets an object context value.
     *
     * @param key the object key to read
     * @return the stored object, or `null` if the key is unknown or has a
     * different type
     */
    public ContextObject? get_object (string key) {
        if (check_key (key, OBJECT)) {
            return (ContextObject?) data[key].real_value.get_object ();
        } else {
            return null;
        }
    }

    /**
     * Sets a string context value.
     *
     * @param key a registered string key
     * @param value the new value
     */
    public void set_string (string key, owned string value) {
        set_value (key, value);
    }

    /**
     * Gets a string context value.
     *
     * @param key the string key to read
     * @return a copy of the string, or `null` if the key is unknown or has a
     * different type
     */
    public string? get_string (string key) {
        if (check_key (key, STRING)) {
            return data[key].real_value.dup_string ();
        } else {
            return null;
        }
    }

    /**
     * Sets a boolean context value.
     *
     * @param key a registered boolean key
     * @param value the new value
     */
    public void set_boolean (string key, bool value) {
        set_value (key, value);
    }

    /**
     * Gets a boolean context value.
     *
     * @param key the boolean key to read
     * @return the value, or `false` if the key is unknown or has a different
     * type
     */
    public bool get_boolean (string key) {
        if (check_key (key, BOOLEAN)) {
            return data[key].real_value.get_boolean ();
        } else {
            return false;
        }
    }

    /**
     * Sets a string-array context value.
     *
     * @param key a registered string-array key
     * @param value the new array
     */
    public void set_strv (string key, owned string[] value) {
        set_value (key, value);
    }

    /**
     * Gets a string-array context value.
     *
     * @param key the string-array key to read
     * @return a copy of the array, or an empty array if the key is unknown,
     * has a different type, or contains no array
     */
    public string[] get_strv (string key) {
        if (check_key (key, STRV)) {
            var arr = ReadySetC.safe_copy ((string[]) data[key].real_value.get_boxed ());
            if (arr != null) {
                return arr;
            }
        }

        return {};
    }

    /**
     * Sets a int64 context value.
     *
     * @param key a registered integer key
     * @param value the new value
     */
    public void set_int (string key, int64 value) {
        set_value (key, value);
    }

    /**
     * Gets a int64 context value.
     *
     * @param key the integer key to read
     * @return the value, or `0` if the key is unknown or has a different type
     */
    public int64 get_int (string key) {
        if (check_key (key, INT)) {
            return data[key].real_value.get_int64 ();
        } else {
            return 0;
        }
    }

    /**
     * Sets a double context value.
     *
     * @param key a registered double key
     * @param value the new value
     */
    public void set_double (string key, double value) {
        set_value (key, value);
    }

    /**
     * Gets a double context value.
     *
     * @param key the double key to read
     * @return the value, or `0.0` if the key is unknown or has a different
     * type
     */
    public double get_double (string key) {
        if (check_key (key, DOUBLE)) {
            return data[key].real_value.get_double ();
        } else {
            return 0;
        }
    }

    /**
     * Restores a context value to its registered default.
     *
     * Nothing changes if the key is unknown or has no default value. Object
     * defaults are copied with {@link ReadySet.ContextObject.copy}.
     *
     * @param key the context key to reset
     */
    public void reset (string key) {
        if (check_key (key)) {
            data[key].reset ();
        }
    }
}
