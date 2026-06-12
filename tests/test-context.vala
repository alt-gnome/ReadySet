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

private class TestContextObject : ReadySet.ContextObject {
    public string data { get; set; }

    public override string string_format {
        owned get { return data; }
        set { data = value; }
    }

    public override ReadySet.ContextObject copy () {
        var new_obj = new TestContextObject ();
        new_obj.data = this.data;
        return new_obj;
    }

    public TestContextObject (string data = "") {
        this.data = data;
    }
}

private class TestBindableObject : Object {
    public string bound_string { get; set; default = ""; }
    public bool bound_boolean { get; set; default = false; }
    public int bound_int { get; set; default = 0; }
}

const string KEY_STRING = "test-string";
const string KEY_BOOLEAN = "test-boolean";
const string KEY_INT = "test-int";
const string KEY_DOUBLE = "test-double";
const string KEY_STRV = "test-strv";
const string KEY_OBJECT = "test-object";

const string DEFAULT_STRING = "default";
const bool DEFAULT_BOOLEAN = false;
const int64 DEFAULT_INT = 42;
const double DEFAULT_DOUBLE = 3.14;
const string DEFAULT_OBJECT_DATA = "obj-default";

const int EXPECTED_KEYS_COUNT = 6;

ReadySet.Context create_test_context () {
    var ctx = new ReadySet.Context (true);

    var vars = new HashTable<string, ReadySet.ContextVarInfo> (str_hash, str_equal);
    vars.insert (KEY_STRING, new ReadySet.ContextVarInfo (ReadySet.ContextType.STRING, DEFAULT_STRING));
    vars.insert (KEY_BOOLEAN, new ReadySet.ContextVarInfo (ReadySet.ContextType.BOOLEAN, DEFAULT_BOOLEAN));
    vars.insert (KEY_INT, new ReadySet.ContextVarInfo (ReadySet.ContextType.INT, DEFAULT_INT));
    vars.insert (KEY_DOUBLE, new ReadySet.ContextVarInfo (ReadySet.ContextType.DOUBLE, DEFAULT_DOUBLE));
    vars.insert (KEY_STRV, new ReadySet.ContextVarInfo (ReadySet.ContextType.STRV, new string[] { "a", "b" }));

    var default_obj = new TestContextObject (DEFAULT_OBJECT_DATA);
    vars.insert (KEY_OBJECT, new ReadySet.ContextVarInfo.object (typeof (TestContextObject), default_obj));

    ctx.register_vars (vars);
    return ctx;
}

void test_has_key () {
    var ctx = create_test_context ();
    if (!ctx.has_key (KEY_STRING)) {
        Test.fail_printf ("Expected key '%s' to exist", KEY_STRING);
    }
    if (!ctx.has_key (KEY_BOOLEAN)) {
        Test.fail_printf ("Expected key '%s' to exist", KEY_BOOLEAN);
    }
    if (!ctx.has_key (KEY_INT)) {
        Test.fail_printf ("Expected key '%s' to exist", KEY_INT);
    }
    if (!ctx.has_key (KEY_DOUBLE)) {
        Test.fail_printf ("Expected key '%s' to exist", KEY_DOUBLE);
    }
    if (!ctx.has_key (KEY_STRV)) {
        Test.fail_printf ("Expected key '%s' to exist", KEY_STRV);
    }
    if (!ctx.has_key (KEY_OBJECT)) {
        Test.fail_printf ("Expected key '%s' to exist", KEY_OBJECT);
    }
    if (ctx.has_key ("nonexistent")) {
        Test.fail_printf ("Expected key 'nonexistent' to not exist");
    }
}

void test_get_keys () {
    var ctx = create_test_context ();
    var keys = ctx.get_keys ();
    if (keys.length != EXPECTED_KEYS_COUNT) {
        Test.fail_printf ("Expected %d keys, got %d", EXPECTED_KEYS_COUNT, keys.length);
    }
}

void test_get_value_type () {
    var ctx = create_test_context ();
    if (ctx.get_value_type (KEY_STRING) != ReadySet.ContextType.STRING) {
        Test.fail_printf ("Expected %s type to be STRING", KEY_STRING);
    }
    if (ctx.get_value_type (KEY_BOOLEAN) != ReadySet.ContextType.BOOLEAN) {
        Test.fail_printf ("Expected %s type to be BOOLEAN", KEY_BOOLEAN);
    }
    if (ctx.get_value_type (KEY_INT) != ReadySet.ContextType.INT) {
        Test.fail_printf ("Expected %s type to be INT", KEY_INT);
    }
    if (ctx.get_value_type (KEY_DOUBLE) != ReadySet.ContextType.DOUBLE) {
        Test.fail_printf ("Expected %s type to be DOUBLE", KEY_DOUBLE);
    }
    if (ctx.get_value_type (KEY_STRV) != ReadySet.ContextType.STRV) {
        Test.fail_printf ("Expected %s type to be STRV", KEY_STRV);
    }
    if (ctx.get_value_type (KEY_OBJECT) != ReadySet.ContextType.OBJECT) {
        Test.fail_printf ("Expected %s type to be OBJECT", KEY_OBJECT);
    }
}

void test_string_default () {
    var ctx = create_test_context ();
    var val = ctx.get_string (KEY_STRING);
    if (val != DEFAULT_STRING) {
        Test.fail_printf ("Expected '%s', got '%s'", DEFAULT_STRING, val);
    }
}

void test_string_set_get () {
    var ctx = create_test_context ();
    ctx.set_string (KEY_STRING, "hello");
    var val = ctx.get_string (KEY_STRING);
    if (val != "hello") {
        Test.fail_printf ("Expected 'hello', got '%s'", val);
    }
}

void test_boolean_default () {
    var ctx = create_test_context ();
    if (ctx.get_boolean (KEY_BOOLEAN) != DEFAULT_BOOLEAN) {
        Test.fail_printf ("Expected false, got true");
    }
}

void test_boolean_set_get () {
    var ctx = create_test_context ();
    ctx.set_boolean (KEY_BOOLEAN, true);
    if (ctx.get_boolean (KEY_BOOLEAN) != true) {
        Test.fail_printf ("Expected true, got false");
    }
}

void test_int_default () {
    var ctx = create_test_context ();
    var val = ctx.get_int (KEY_INT);
    if (val != DEFAULT_INT) {
        Test.fail_printf ("Expected %lld, got %lld", DEFAULT_INT, val);
    }
}

void test_int_set_get () {
    var ctx = create_test_context ();
    ctx.set_int (KEY_INT, 100);
    var val = ctx.get_int (KEY_INT);
    if (val != 100) {
        Test.fail_printf ("Expected 100, got %lld", val);
    }
}

void test_double_default () {
    var ctx = create_test_context ();
    var val = ctx.get_double (KEY_DOUBLE);
    if (val != DEFAULT_DOUBLE) {
        Test.fail_printf ("Expected %f, got %f", DEFAULT_DOUBLE, val);
    }
}

void test_double_set_get () {
    var ctx = create_test_context ();
    ctx.set_double (KEY_DOUBLE, 2.718);
    var val = ctx.get_double (KEY_DOUBLE);
    if (val != 2.718) {
        Test.fail_printf ("Expected 2.718, got %f", val);
    }
}

void test_strv_default () {
    var ctx = create_test_context ();
    var val = ctx.get_strv (KEY_STRV);
    if (val.length != 2) {
        Test.fail_printf ("Expected strv length 2, got %d", val.length);
    }
    if (val[0] != "a") {
        Test.fail_printf ("Expected strv[0] to be 'a', got '%s'", val[0]);
    }
    if (val[1] != "b") {
        Test.fail_printf ("Expected strv[1] to be 'b', got '%s'", val[1]);
    }
}

void test_strv_set_get () {
    var ctx = create_test_context ();
    ctx.set_strv (KEY_STRV, { "x", "y", "z" });
    var val = ctx.get_strv (KEY_STRV);
    if (val.length != 3) {
        Test.fail_printf ("Expected strv length 3, got %d", val.length);
    }
    if (val[0] != "x") {
        Test.fail_printf ("Expected strv[0] to be 'x', got '%s'", val[0]);
    }
    if (val[1] != "y") {
        Test.fail_printf ("Expected strv[1] to be 'y', got '%s'", val[1]);
    }
    if (val[2] != "z") {
        Test.fail_printf ("Expected strv[2] to be 'z', got '%s'", val[2]);
    }
}

void test_object_default () {
    var ctx = create_test_context ();
    var obj = ctx.get_object (KEY_OBJECT);
    if (obj == null) {
        Test.fail_printf ("Expected object to not be null");
    }
    if (((TestContextObject) obj).data != DEFAULT_OBJECT_DATA) {
        Test.fail_printf ("Expected object data to be '%s', got '%s'", DEFAULT_OBJECT_DATA, ((TestContextObject) obj).data);
    }
}

void test_object_set_get () {
    var ctx = create_test_context ();
    var new_obj = new TestContextObject ("new-data");
    ctx.set_object (KEY_OBJECT, new_obj);
    var obj = ctx.get_object (KEY_OBJECT);
    if (obj == null) {
        Test.fail_printf ("Expected object to not be null");
    }
    if (((TestContextObject) obj).data != "new-data") {
        Test.fail_printf ("Expected object data to be 'new-data', got '%s'", ((TestContextObject) obj).data);
    }
}

void test_reset_string () {
    var ctx = create_test_context ();
    ctx.set_string (KEY_STRING, "modified");
    if (ctx.get_string (KEY_STRING) != "modified") {
        Test.fail_printf ("Expected 'modified', got '%s'", ctx.get_string (KEY_STRING));
    }
    ctx.reset (KEY_STRING);
    if (ctx.get_string (KEY_STRING) != DEFAULT_STRING) {
        Test.fail_printf ("Expected '%s' after reset, got '%s'", DEFAULT_STRING, ctx.get_string (KEY_STRING));
    }
}

void test_reset_boolean () {
    var ctx = create_test_context ();
    ctx.set_boolean (KEY_BOOLEAN, true);
    if (ctx.get_boolean (KEY_BOOLEAN) != true) {
        Test.fail_printf ("Expected true, got false");
    }
    ctx.reset (KEY_BOOLEAN);
    if (ctx.get_boolean (KEY_BOOLEAN) != DEFAULT_BOOLEAN) {
        Test.fail_printf ("Expected false after reset, got true");
    }
}

void test_reset_int () {
    var ctx = create_test_context ();
    ctx.set_int (KEY_INT, 999);
    if (ctx.get_int (KEY_INT) != 999) {
        Test.fail_printf ("Expected 999, got %lld", ctx.get_int (KEY_INT));
    }
    ctx.reset (KEY_INT);
    if (ctx.get_int (KEY_INT) != DEFAULT_INT) {
        Test.fail_printf ("Expected %lld after reset, got %lld", DEFAULT_INT, ctx.get_int (KEY_INT));
    }
}

void test_reset_double () {
    var ctx = create_test_context ();
    ctx.set_double (KEY_DOUBLE, 0.0);
    if (ctx.get_double (KEY_DOUBLE) != 0.0) {
        Test.fail_printf ("Expected 0.0, got %f", ctx.get_double (KEY_DOUBLE));
    }
    ctx.reset (KEY_DOUBLE);
    if (ctx.get_double (KEY_DOUBLE) != DEFAULT_DOUBLE) {
        Test.fail_printf ("Expected %f after reset, got %f", DEFAULT_DOUBLE, ctx.get_double (KEY_DOUBLE));
    }
}

void test_sandbox_property () {
    var ctx_sandbox = new ReadySet.Context (true);
    if (ctx_sandbox.sandbox != true) {
        Test.fail_printf ("Expected sandbox to be true");
    }

    var ctx_no_sandbox = new ReadySet.Context (false);
    if (ctx_no_sandbox.sandbox != false) {
        Test.fail_printf ("Expected sandbox to be false");
    }
}

void test_data_changed_signal () {
    var ctx = create_test_context ();
    string? changed_key = null;
    ctx.data_changed.connect ((key) => { changed_key = key; });

    ctx.set_string (KEY_STRING, "new-value");
    if (changed_key != KEY_STRING) {
        Test.fail_printf ("Expected changed_key to be '%s', got '%s'", KEY_STRING, changed_key);
    }

    ctx.set_boolean (KEY_BOOLEAN, true);
    if (changed_key != KEY_BOOLEAN) {
        Test.fail_printf ("Expected changed_key to be '%s', got '%s'", KEY_BOOLEAN, changed_key);
    }
}

void test_get_value () {
    var ctx = create_test_context ();
    var val = ctx.get_value (KEY_STRING);
    if (val == null) {
        Test.fail_printf ("Expected value to not be null");
    }
    if (val.get_string () != DEFAULT_STRING) {
        Test.fail_printf ("Expected '%s', got '%s'", DEFAULT_STRING, val.get_string ());
    }
}

void test_mode_property () {
    var ctx = create_test_context ();
    ctx.mode = ReadySet.Mode.INSTALLER;
    if (ctx.mode != ReadySet.Mode.INSTALLER) {
        Test.fail_printf ("Expected mode to be INSTALLER");
    }

    ctx.mode = ReadySet.Mode.EXISTING_USER;
    if (ctx.mode != ReadySet.Mode.EXISTING_USER) {
        Test.fail_printf ("Expected mode to be EXISTING_USER");
    }
}

void test_bind_context_to_property () {
    var ctx = create_test_context ();
    var obj = new TestBindableObject ();

    var binding = ctx.bind_context_to_property (KEY_STRING, obj, "bound-string");
    if (binding == null) {
        Test.fail_printf ("Expected binding to not be null");
    }

    ctx.set_string (KEY_STRING, "new-value");
    if (obj.bound_string != "new-value") {
        Test.fail_printf ("Expected bound_string to be 'new-value', got '%s'", obj.bound_string);
    }
}

void test_bind_context_to_property_bidirectional () {
    var ctx = create_test_context ();
    var obj = new TestBindableObject ();

    var binding = ctx.bind_context_to_property (KEY_STRING, obj, "bound-string", BindingFlags.BIDIRECTIONAL);
    if (binding == null) {
        Test.fail_printf ("Expected binding to not be null");
    }

    obj.bound_string = "from-object";
    if (ctx.get_string (KEY_STRING) != "from-object") {
        Test.fail_printf ("Expected %s to be 'from-object', got '%s'", KEY_STRING, ctx.get_string (KEY_STRING));
    }
}

void test_bind_context_to_property_invert () {
    var ctx = create_test_context ();
    var obj = new TestBindableObject ();

    var binding = ctx.bind_context_to_property (KEY_BOOLEAN, obj, "bound-boolean", BindingFlags.INVERT_BOOLEAN);
    if (binding == null) {
        Test.fail_printf ("Expected binding to not be null");
    }

    ctx.set_boolean (KEY_BOOLEAN, true);
    if (obj.bound_boolean != false) {
        Test.fail_printf ("Expected bound_boolean to be false, got true");
    }

    ctx.set_boolean (KEY_BOOLEAN, false);
    if (obj.bound_boolean != true) {
        Test.fail_printf ("Expected bound_boolean to be true, got false");
    }
}

void test_bind_property_to_context () {
    var ctx = create_test_context ();
    var obj = new TestBindableObject ();

    obj.bound_string = "initial";
    var binding = ctx.bind_property_to_context (obj, "bound-string", KEY_STRING);
    if (binding == null) {
        Test.fail_printf ("Expected binding to not be null");
    }

    obj.bound_string = "changed";
    if (ctx.get_string (KEY_STRING) != "changed") {
        Test.fail_printf ("Expected %s to be 'changed', got '%s'", KEY_STRING, ctx.get_string (KEY_STRING));
    }
}

void test_bind_property_to_context_bidirectional () {
    var ctx = create_test_context ();
    var obj = new TestBindableObject ();

    obj.bound_string = "initial";
    var binding = ctx.bind_property_to_context (obj, "bound-string", KEY_STRING, BindingFlags.BIDIRECTIONAL);
    if (binding == null) {
        Test.fail_printf ("Expected binding to not be null");
    }

    ctx.set_string (KEY_STRING, "from-context");
    if (obj.bound_string != "from-context") {
        Test.fail_printf ("Expected bound_string to be 'from-context', got '%s'", obj.bound_string);
    }
}

void test_bind_property_to_context_invert () {
    var ctx = create_test_context ();
    var obj = new TestBindableObject ();

    obj.bound_boolean = true;
    var binding = ctx.bind_property_to_context (obj, "bound-boolean", KEY_BOOLEAN, BindingFlags.INVERT_BOOLEAN);
    if (binding == null) {
        Test.fail_printf ("Expected binding to not be null");
    }

    obj.bound_boolean = false;
    if (ctx.get_boolean (KEY_BOOLEAN) != true) {
        Test.fail_printf ("Expected %s to be true, got false", KEY_BOOLEAN);
    }
}

void test_set_raw_string () {
    var ctx = create_test_context ();
    ctx.set_raw (KEY_STRING, "raw-value");
    if (ctx.get_string (KEY_STRING) != "raw-value") {
        Test.fail_printf ("Expected 'raw-value', got '%s'", ctx.get_string (KEY_STRING));
    }
}

void test_set_raw_boolean () {
    var ctx = create_test_context ();
    ctx.set_raw (KEY_BOOLEAN, "true");
    if (ctx.get_boolean (KEY_BOOLEAN) != true) {
        Test.fail_printf ("Expected true, got false");
    }

    ctx.set_raw (KEY_BOOLEAN, "false");
    if (ctx.get_boolean (KEY_BOOLEAN) != false) {
        Test.fail_printf ("Expected false, got true");
    }
}

void test_set_raw_int () {
    var ctx = create_test_context ();
    ctx.set_raw (KEY_INT, "100");
    if (ctx.get_int (KEY_INT) != 100) {
        Test.fail_printf ("Expected 100, got %lld", ctx.get_int (KEY_INT));
    }
}

void test_set_raw_double () {
    var ctx = create_test_context ();
    ctx.set_raw (KEY_DOUBLE, "2.718");
    if (ctx.get_double (KEY_DOUBLE) != 2.718) {
        Test.fail_printf ("Expected 2.718, got %f", ctx.get_double (KEY_DOUBLE));
    }
}

void test_set_raw_strv () {
    var ctx = create_test_context ();
    ctx.set_raw (KEY_STRV, "x,y,z");
    var val = ctx.get_strv (KEY_STRV);
    if (val.length != 3) {
        Test.fail_printf ("Expected strv length 3, got %d", val.length);
    }
    if (val[0] != "x") {
        Test.fail_printf ("Expected strv[0] to be 'x', got '%s'", val[0]);
    }
    if (val[1] != "y") {
        Test.fail_printf ("Expected strv[1] to be 'y', got '%s'", val[1]);
    }
    if (val[2] != "z") {
        Test.fail_printf ("Expected strv[2] to be 'z', got '%s'", val[2]);
    }
}

void test_load_from_keyfile () {
    var ctx = create_test_context ();
    var kf = new KeyFile ();
    kf.set_string ("TestGroup", KEY_STRING, "from-keyfile");
    kf.set_boolean ("TestGroup", KEY_BOOLEAN, true);
    kf.set_int64 ("TestGroup", KEY_INT, 999);
    kf.set_double ("TestGroup", KEY_DOUBLE, 1.5);
    kf.set_string_list ("TestGroup", KEY_STRV, { "p", "q" });

    ctx.load_from_keyfile (kf, "TestGroup");

    if (ctx.get_string (KEY_STRING) != "from-keyfile") {
        Test.fail_printf ("Expected 'from-keyfile', got '%s'", ctx.get_string (KEY_STRING));
    }
    if (ctx.get_boolean (KEY_BOOLEAN) != true) {
        Test.fail_printf ("Expected true, got false");
    }
    if (ctx.get_int (KEY_INT) != 999) {
        Test.fail_printf ("Expected 999, got %lld", ctx.get_int (KEY_INT));
    }
    if (ctx.get_double (KEY_DOUBLE) != 1.5) {
        Test.fail_printf ("Expected 1.5, got %f", ctx.get_double (KEY_DOUBLE));
    }
    var strv = ctx.get_strv (KEY_STRV);
    if (strv.length != 2) {
        Test.fail_printf ("Expected strv length 2, got %d", strv.length);
    }
    if (strv[0] != "p") {
        Test.fail_printf ("Expected strv[0] to be 'p', got '%s'", strv[0]);
    }
    if (strv[1] != "q") {
        Test.fail_printf ("Expected strv[1] to be 'q', got '%s'", strv[1]);
    }
}

void test_load_from_keyfile_missing_group () {
    var ctx = create_test_context ();
    var kf = new KeyFile ();
    kf.set_string ("OtherGroup", KEY_STRING, "value");

    ctx.load_from_keyfile (kf, "TestGroup");
    if (ctx.get_string (KEY_STRING) != DEFAULT_STRING) {
        Test.fail_printf ("Expected '%s', got '%s'", DEFAULT_STRING, ctx.get_string (KEY_STRING));
    }
}

void test_load_from_keyfile_unknown_key () {
    var ctx = create_test_context ();
    var kf = new KeyFile ();
    kf.set_string ("TestGroup", KEY_STRING, "valid-value");

    ctx.load_from_keyfile (kf, "TestGroup");
    if (ctx.get_string (KEY_STRING) != "valid-value") {
        Test.fail_printf ("Expected 'valid-value', got '%s'", ctx.get_string (KEY_STRING));
    }
}

void test_get_raw_string () {
    var ctx = create_test_context ();
    ctx.set_string (KEY_STRING, "hello");
    ctx.set_boolean (KEY_BOOLEAN, true);
    ctx.set_int (KEY_INT, 42);
    ctx.set_double (KEY_DOUBLE, 3.14);
    ctx.set_strv (KEY_STRV, { "a", "b", "c" });

    var raw = ctx.get_raw_string ();
    if (raw.lookup (KEY_STRING) != "hello") {
        Test.fail_printf ("Expected 'hello', got '%s'", raw.lookup (KEY_STRING));
    }
    if (raw.lookup (KEY_BOOLEAN) != "true") {
        Test.fail_printf ("Expected 'true', got '%s'", raw.lookup (KEY_BOOLEAN));
    }
    if (raw.lookup (KEY_INT) != "42") {
        Test.fail_printf ("Expected '42', got '%s'", raw.lookup (KEY_INT));
    }
    if (raw.lookup (KEY_STRV) != "a,b,c") {
        Test.fail_printf ("Expected 'a,b,c', got '%s'", raw.lookup (KEY_STRV));
    }
    if (raw.lookup (KEY_DOUBLE) == null) {
        Test.fail_printf ("Expected %s to be present in raw string", KEY_DOUBLE);
    }
}

void test_context_var_info_creation () {
    var info_string = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRING, "default");
    assert (info_string.value_type == ReadySet.ContextType.STRING);
    assert (info_string.default_value.get_string () == "default");

    var info_bool = new ReadySet.ContextVarInfo (ReadySet.ContextType.BOOLEAN, true);
    assert (info_bool.value_type == ReadySet.ContextType.BOOLEAN);
    assert (info_bool.default_value.get_boolean () == true);

    var info_int = new ReadySet.ContextVarInfo (ReadySet.ContextType.INT, (int64) 42);
    assert (info_int.value_type == ReadySet.ContextType.INT);
    assert (info_int.default_value.get_int64 () == 42);
}

void test_context_object_copy () {
    var obj = new TestContextObject ("original");
    var copy = (TestContextObject) obj.copy ();

    assert (copy.data == "original");
    assert (copy != obj);

    copy.data = "modified";
    assert (obj.data == "original");
    assert (copy.data == "modified");
}

void test_context_reset_object () {
    var ctx = create_test_context ();
    var new_obj = new TestContextObject ("modified");
    ctx.set_object (KEY_OBJECT, new_obj);
    if (((TestContextObject) ctx.get_object (KEY_OBJECT)).data != "modified") {
        Test.fail_printf ("Expected 'modified', got '%s'", ((TestContextObject) ctx.get_object (KEY_OBJECT)).data);
    }

    ctx.reset (KEY_OBJECT);
    if (((TestContextObject) ctx.get_object (KEY_OBJECT)).data != DEFAULT_OBJECT_DATA) {
        Test.fail_printf ("Expected '%s' after reset, got '%s'", DEFAULT_OBJECT_DATA, ((TestContextObject) ctx.get_object (KEY_OBJECT)).data);
    }
}

void test_context_multiple_data_changed_signals () {
    var ctx = create_test_context ();
    var changed_keys = new Gee.ArrayList<string> ();
    ctx.data_changed.connect ((key) => { changed_keys.add (key); });

    ctx.set_string (KEY_STRING, "value1");
    ctx.set_boolean (KEY_BOOLEAN, true);
    ctx.set_int (KEY_INT, 100);

    if (changed_keys.size != 3) {
        Test.fail_printf ("Expected 3 changed keys, got %d", changed_keys.size);
    }
    if (changed_keys[0] != KEY_STRING) {
        Test.fail_printf ("Expected first changed key to be '%s', got '%s'", KEY_STRING, changed_keys[0]);
    }
    if (changed_keys[1] != KEY_BOOLEAN) {
        Test.fail_printf ("Expected second changed key to be '%s', got '%s'", KEY_BOOLEAN, changed_keys[1]);
    }
    if (changed_keys[2] != KEY_INT) {
        Test.fail_printf ("Expected third changed key to be '%s', got '%s'", KEY_INT, changed_keys[2]);
    }
}

void test_context_strv_empty () {
    var ctx = create_test_context ();
    ctx.set_strv (KEY_STRV, {});
    var val = ctx.get_strv (KEY_STRV);
    if (val.length != 0) {
        Test.fail_printf ("Expected strv length 0, got %d", val.length);
    }
}

void test_context_strv_single_element () {
    var ctx = create_test_context ();
    ctx.set_strv (KEY_STRV, { "single" });
    var val = ctx.get_strv (KEY_STRV);
    if (val.length != 1) {
        Test.fail_printf ("Expected strv length 1, got %d", val.length);
    }
    if (val[0] != "single") {
        Test.fail_printf ("Expected strv[0] to be 'single', got '%s'", val[0]);
    }
}

void test_context_int_negative () {
    var ctx = create_test_context ();
    ctx.set_int (KEY_INT, -100);
    if (ctx.get_int (KEY_INT) != -100) {
        Test.fail_printf ("Expected -100, got %lld", ctx.get_int (KEY_INT));
    }
}

void test_context_int_zero () {
    var ctx = create_test_context ();
    ctx.set_int (KEY_INT, 0);
    if (ctx.get_int (KEY_INT) != 0) {
        Test.fail_printf ("Expected 0, got %lld", ctx.get_int (KEY_INT));
    }
}

void test_context_double_negative () {
    var ctx = create_test_context ();
    ctx.set_double (KEY_DOUBLE, -2.5);
    if (ctx.get_double (KEY_DOUBLE) != -2.5) {
        Test.fail_printf ("Expected -2.5, got %f", ctx.get_double (KEY_DOUBLE));
    }
}

void test_context_double_zero () {
    var ctx = create_test_context ();
    ctx.set_double (KEY_DOUBLE, 0.0);
    if (ctx.get_double (KEY_DOUBLE) != 0.0) {
        Test.fail_printf ("Expected 0.0, got %f", ctx.get_double (KEY_DOUBLE));
    }
}

void test_context_string_empty () {
    var ctx = create_test_context ();
    ctx.set_string (KEY_STRING, "");
    if (ctx.get_string (KEY_STRING) != "") {
        Test.fail_printf ("Expected empty string, got '%s'", ctx.get_string (KEY_STRING));
    }
}

void test_context_string_unicode () {
    var ctx = create_test_context ();
    ctx.set_string (KEY_STRING, "Привет мир");
    if (ctx.get_string (KEY_STRING) != "Привет мир") {
        Test.fail_printf ("Expected 'Привет мир', got '%s'", ctx.get_string (KEY_STRING));
    }
}

public static int main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/context/has-key", test_has_key);
    Test.add_func ("/context/get-keys", test_get_keys);
    Test.add_func ("/context/get-value-type", test_get_value_type);

    Test.add_func ("/context/string/default", test_string_default);
    Test.add_func ("/context/string/set-get", test_string_set_get);
    Test.add_func ("/context/string/empty", test_context_string_empty);
    Test.add_func ("/context/string/unicode", test_context_string_unicode);

    Test.add_func ("/context/boolean/default", test_boolean_default);
    Test.add_func ("/context/boolean/set-get", test_boolean_set_get);

    Test.add_func ("/context/int/default", test_int_default);
    Test.add_func ("/context/int/set-get", test_int_set_get);
    Test.add_func ("/context/int/negative", test_context_int_negative);
    Test.add_func ("/context/int/zero", test_context_int_zero);

    Test.add_func ("/context/double/default", test_double_default);
    Test.add_func ("/context/double/set-get", test_double_set_get);
    Test.add_func ("/context/double/negative", test_context_double_negative);
    Test.add_func ("/context/double/zero", test_context_double_zero);

    Test.add_func ("/context/strv/default", test_strv_default);
    Test.add_func ("/context/strv/set-get", test_strv_set_get);
    Test.add_func ("/context/strv/empty", test_context_strv_empty);
    Test.add_func ("/context/strv/single-element", test_context_strv_single_element);

    Test.add_func ("/context/object/default", test_object_default);
    Test.add_func ("/context/object/set-get", test_object_set_get);
    Test.add_func ("/context/object/copy", test_context_object_copy);

    Test.add_func ("/context/reset/string", test_reset_string);
    Test.add_func ("/context/reset/boolean", test_reset_boolean);
    Test.add_func ("/context/reset/int", test_reset_int);
    Test.add_func ("/context/reset/double", test_reset_double);
    Test.add_func ("/context/reset/object", test_context_reset_object);

    Test.add_func ("/context/sandbox", test_sandbox_property);
    Test.add_func ("/context/data-changed-signal", test_data_changed_signal);
    Test.add_func ("/context/data-changed-multiple", test_context_multiple_data_changed_signals);
    Test.add_func ("/context/get-value", test_get_value);
    Test.add_func ("/context/mode", test_mode_property);

    Test.add_func ("/context/bind/to-property", test_bind_context_to_property);
    Test.add_func ("/context/bind/to-property/bidirectional", test_bind_context_to_property_bidirectional);
    Test.add_func ("/context/bind/to-property/invert", test_bind_context_to_property_invert);
    Test.add_func ("/context/bind/property-to-context", test_bind_property_to_context);
    Test.add_func ("/context/bind/property-to-context/bidirectional", test_bind_property_to_context_bidirectional);
    Test.add_func ("/context/bind/property-to-context/invert", test_bind_property_to_context_invert);

    Test.add_func ("/context/set-raw/string", test_set_raw_string);
    Test.add_func ("/context/set-raw/boolean", test_set_raw_boolean);
    Test.add_func ("/context/set-raw/int", test_set_raw_int);
    Test.add_func ("/context/set-raw/double", test_set_raw_double);
    Test.add_func ("/context/set-raw/strv", test_set_raw_strv);

    Test.add_func ("/context/load-from-keyfile", test_load_from_keyfile);
    Test.add_func ("/context/load-from-keyfile/missing-group", test_load_from_keyfile_missing_group);
    Test.add_func ("/context/load-from-keyfile/unknown-key", test_load_from_keyfile_unknown_key);

    Test.add_func ("/context/get-raw-string", test_get_raw_string);

    Test.add_func ("/context/var-info/creation", test_context_var_info_creation);

    return Test.run ();
}
