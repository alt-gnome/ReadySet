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

    public enum LayoutMode {
        VERTICAL,
        HORIZONTAL,
        BIG,
        SMALL;

        internal static LayoutMode from_string (string str) {
            unowned EnumClass enum_class = (EnumClass) typeof (LayoutMode).class_peek ();
            var enum_value = enum_class.get_value_by_nick (str);
            if (enum_value == null) {
                error ("Unsupported unum value: %s", str);
            }
            return (LayoutMode) enum_value.value;
        }
    }

    public enum Mode {
        INITIAL_SETUP,
        INSTALLER,
        TOUR;

        public static Mode from_string (string str) {
            switch (str) {
                case "initial-setup":
                    return INITIAL_SETUP;
                case "installer":
                    return INSTALLER;
                case "tour":
                    return TOUR;
                default:
                    error ("Unrecognized mode string");
            }
        }

        public string to_string () {
            switch (this) {
                case INITIAL_SETUP:
                    return "initial-setup";
                case INSTALLER:
                    return "installer";
                case TOUR:
                    return "tour";
                default:
                    assert_not_reached ();
            }
        }
    }

    /**
     * Data that handles {@link StepAddin.apply} error data.
     *
     * @see ApplyError
     */
    public class ApplyErrorData : Serialize.DataObject {

        /**
         * Error message. Will be used as title on error page.
         */
        public string message { get; set; }

        /**
         * Error description. Will be used as body on error page.
         */
        public string description { get; set; }

        public ApplyErrorData (string message, string descriprtion) {
            this.message = message;
            this.description = description;
        }
    }

    public sealed class ProgressData : Object {

        //  Value from 0.0 to 1.0
        public double value { get; set; default = 0.0; }

        public string message { get; set; }
    }

    /**
     * Can hold either json string or something else, so you should use
     * {@link ApplyError.to_data} to get real data as {@link ApplyErrorData}.
     *
     * Also you can build both with
     * {{{
     *   throw new ApplyError.BASE ("Message");
     * }}}
     * and
     * {{{
     *   throw ApplyError.build_error ("Title", "Body");
     * }}}
     *
     * If you creating error manually, "Something went wrong" will be
     * used as title.
     */
    public errordomain ApplyError {

        /**
         * Base error.
         */
        BASE,

        /**
         * Should be thrown when not enough permission.
         */
        NO_PERMISSION;

        /**
         * Build error from message and description. Returns error with
         * json serialized {@link ApplyErrorData} in message.
         *
         * @see ApplyErrorData
         */
        public static ApplyError build_error (string message, string description) {
            return new ApplyError.BASE (new ApplyErrorData (message, description).to_json ());
        }

        internal static ApplyErrorData to_data (ApplyError error) {
            try {
                return Serialize.JsonWorker.simple_from_json<ApplyErrorData> (error.message);
            } catch (Serialize.Error e) {
                //  It's not json string, just return message
                return new ApplyErrorData (_("Something went wrong"), error.message);
            }
        }
    }

    /**
     * Function that uses as getter in {@link Context} value.
     */
    public delegate Value ContextGetterFunc (ref Value this_value);

    /**
     * Function that uses as setter in {@link Context} value.
     */
    public delegate void ContextSetterFunc (ref Value this_value, Value new_value);

    /**
     * Runs `pkexec` with SHELL fixing.
     */
    public async void pkexec (owned string[] cmd, string? user = null, Cancellable? cancellable = null) throws Error {
        var launcher = new SubprocessLauncher (NONE);
        var argv = new Gee.ArrayList<string>.wrap ({ "pkexec" });

        if (user != null) {
            argv.add_all_array ({ "--user", user });
        }

        argv.add_all_array (cmd);

        //  pkexec won't let us run the program if $SHELL isn't in /etc/shells,
        //  so remove it from the environment.
        launcher.unsetenv ("SHELL");
        var process = launcher.spawnv (argv.to_array ().copy ());

        yield process.wait_check_async (cancellable);
    }

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
