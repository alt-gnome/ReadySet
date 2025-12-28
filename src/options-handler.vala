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

public sealed class ReadySet.OptionsHandler : Object {

    const string APP_GROUP_NAME = "Application";
    const string CTX_GROUP_NAME = "Context";

    internal const string OPT_CONF_FILE = "conf-file";

    KeyFile conf_keyfile;
    const char SEP = ',';

    File standard_conf_file = File.new_build_filename (Config.SYSCONFDIR, Config.NAME, "config");

    internal const OptionEntry[] OPTION_ENTRIES = {
        { "version", 'v', 0, OptionArg.NONE, null, N_("Print version information and exit"), null },
        { "steps", 's', 0, OptionArg.STRING, null, N_("Steps. E.g: `steps=language,keyboard`"), "STEPS" },
        { "context", 'c', 0, OptionArg.STRING_ARRAY, null, N_("Context vars"), "CONTEXT" },
        { OPT_CONF_FILE, 'C', 0, OptionArg.FILENAME, null, N_("App config file"), "CONF-FILE" },
        { "idle", 'i', 0, OptionArg.NONE, null, N_("Idle run without doing anything"), null },
        { "fullscreen", 'F', 0, OptionArg.NONE, null, N_("Run window in fullscreen"), null },
        { null }
    };

    public bool version { get; set; }

    public string[] steps { get; set; }

    public string[] context { get; set; }

    public string conf_file { get; set; }

    public bool idle { get; set; }

    public bool fullscreen { get; set; }

    public OptionsHandler.from_options (VariantDict options) {
        conf_keyfile = new KeyFile ();
        conf_keyfile.set_list_separator (SEP);

        try {
            if (options.contains (OPT_CONF_FILE)) {
                var config_filename = options.lookup_value (OPT_CONF_FILE, null).get_bytestring ();
                conf_keyfile.load_from_file (config_filename, KeyFileFlags.NONE);
            } else if (standard_conf_file.query_exists ()) {
                conf_keyfile.load_from_file (standard_conf_file.get_path (), KeyFileFlags.NONE);
            }

            foreach (var prop in this.get_class ().list_properties ()) {
                //  Set from config
                if (kf_has_key (conf_keyfile, APP_GROUP_NAME, prop.name)) {
                    this.set_property (
                        prop.name,
                        kf_value_to_value (conf_keyfile, APP_GROUP_NAME, prop.name, prop.value_type)
                    );
                }

                //  Set from options
                var opt = options.lookup_value (prop.name, null);

                if (opt != null) {
                    this.set_property (
                        prop.name,
                        opt_to_value (opt, prop.value_type)
                    );
                }
            }

        } catch (Error e) {
            error ("Error in working with config file: %s", e.message);
        }
    }

    public Context build_context () {
        Context ctx;
        if (conf_file != null) {
            ctx = new Context (idle);
            try {
                ctx.load_from_keyfile (conf_keyfile, CTX_GROUP_NAME);
            } catch (Error e) {
                error ("Error in working with config file: %s", e.message);
            }
        } else {
            ctx = new Context (idle);
        }

        foreach (var context_var in context) {
            var context_var_parts = context_var.split ("=", 2);
            if (context_var_parts.length == 2) {
                ctx.set_raw (context_var_parts[0], context_var_parts[1]);
            } else {
                error ("Invalid context var: %s", context_var);
            }
        }

        return ctx;
    }

    //  KeyFile value must be present
    Value kf_value_to_value (KeyFile keyfile, string group_name, string key, Type value_type) throws Error {
        if (value_type == Type.BOOLEAN) {
            return keyfile.get_boolean (group_name, key);
        } else if (value_type == Type.STRING) {
            return keyfile.get_string (group_name, key);
        } else if (value_type == typeof (string[])) {
            return keyfile.get_string_list (group_name, key);
        } else {
            error ("Unknown keyfile desired type: %s", value_type.name ());
        }
    }

    Value opt_to_value (Variant opt, Type value_type) {
        if (value_type == Type.BOOLEAN) {
            return true;

        } else if (value_type == Type.STRING) {
            if (opt.get_type ().dup_string () == VariantType.STRING.dup_string ()) {
                return opt.get_string ();
            } else if (opt.get_type ().dup_string () == VariantType.BYTESTRING.dup_string ()) {
                return opt.get_bytestring ();
            } else {
                error ("Unknown opt type. Desired: %s; Present %s", value_type.name (), opt.get_type ().dup_string ());
            }

        } else if (value_type == typeof (string[])) {
            if (opt.get_type ().dup_string () == VariantType.STRING_ARRAY.dup_string ()) {
                return opt.get_strv ();
            } else if (opt.get_type ().dup_string () == VariantType.STRING.dup_string ()) {
                return opt.get_string ().strip ().split (SEP.to_string ());
            } else {
                error ("Unknown opt type. Desired: %s; Present %s", value_type.name (), opt.get_type ().dup_string ());
            }

        } else {
            error ("Unknown keyfile desired type: %s", value_type.name ());
        }
    }

    bool kf_has_key (KeyFile keyfile, string group_name, string key) throws Error {
        if (keyfile.has_group (group_name)) {
            return keyfile.has_key (group_name, key);
        }
        return false;
    }
}
