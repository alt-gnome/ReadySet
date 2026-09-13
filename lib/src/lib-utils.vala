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

    /**
     * Policy returned by {@link ReadySet.ExistingUser.get_existing_user}.
     */
    public enum ExistingUserStatus {
        /** Show the step only when it is absent from `performed-steps`. */
        IF_NOT_PASSED,
        /** Always show the step in existing-user mode. */
        YES,
        /** Never show the step in existing-user mode. */
        NO;
    }

    /**
     * Status flags that post-act plugins can return.
     */
    [Flags]
    public enum PostActStatusFlags {
        /**
         * Application window should stay opened. (e.g. gdm needs it)
         */
        STAY_OPEN;
    }

    /**
     * Responsive layout state reported to {@link ReadySet.BasePage}.
     *
     * `VERTICAL` and `HORIZONTAL` describe the content arrangement, while
     * `BIG` and `SMALL` describe the available window size. Consumers should
     * handle the values relevant to the breakpoint they observe.
     */
    public enum LayoutMode {
        /** Widgets are arranged vertically. */
        VERTICAL,
        /** Widgets are arranged horizontally. */
        HORIZONTAL,
        /** The page has a large amount of available space. */
        BIG,
        /** The page has a limited amount of available space. */
        SMALL;
    }

    /**
     * Operating mode of the ReadySet application.
     */
    public enum Mode {
        /** Configure a newly created system or user session. */
        INITIAL_SETUP,
        /** Collect settings and install a system. */
        INSTALLER,
        /** Configure an existing user's current session. */
        EXISTING_USER;

        /**
         * Parses a mode identifier.
         *
         * Accepted values are `initial-setup`, `installer`, and
         * `existing-user`. Any other value causes a fatal error.
         *
         * @param str the mode identifier
         * @return the parsed mode
         */
        public static Mode from_string (string str) {
            switch (str) {
                case "initial-setup":
                    return INITIAL_SETUP;
                case "installer":
                    return INSTALLER;
                case "existing-user":
                    return EXISTING_USER;
                default:
                    error ("Unrecognized mode string");
            }
        }

        /**
         * Returns this mode's stable identifier.
         *
         * @return `initial-setup`, `installer`, or `existing-user`
         */
        public string to_string () {
            switch (this) {
                case INITIAL_SETUP:
                    return "initial-setup";
                case INSTALLER:
                    return "installer";
                case EXISTING_USER:
                    return "existing-user";
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

        /**
         * Creates structured error data.
         *
         * @param message the short error title
         * @param description the detailed error description
         */
        public ApplyErrorData (string message, string description) {
            this.message = message;
            this.description = description;
        }
    }

    /**
     * Mutable progress information for long-running apply and install
     * operations.
     *
     * A newly created instance starts with {@link ProgressData.value} set to
     * `0.0`. Implementations update the same instance while
     * {@link InstallerAddin.install} or {@link StepAddin.apply} is running.
     */
    public sealed class ProgressData : Object {

        /**
         * Calls {@link Gtk.ProgressBar.pulse} property.
         */
        public signal void pulse ();

        /**
         * Progress value from 0.0 to 1.0.
         */
        public double value { get; set; default = 0.0; }

        /**
         * Binds with {@link Gtk.ProgressBar.pulse_step} property.
         */
        public bool pulse_step { get; set; }

        /**
         * Message that will be presented as current log.
         */
        public string message { get; set; }
    }

    /**
     * Can hold either json string or something else.
     *
     * You can build both with
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
         * Builds an error containing serialized structured error data.
         *
         * The returned error has code {@link ApplyError.BASE}; its message is
         * the JSON representation of {@link ApplyErrorData}.
         *
         * @param message the short error title
         * @param description the detailed error description
         * @return a new structured apply error
         * @see ApplyErrorData
         */
        public static ApplyError build_error (string message, string description) {
            return new ApplyError.BASE (new ApplyErrorData (message, description).to_json ());
        }

    }

    /**
     * Reads the current value of an externally backed context variable.
     *
     * @return the current value
     * @see ReadySet.ContextVarInfo
     */
    public delegate Value ContextGetterFunc ();

    /**
     * Writes an externally backed context variable.
     *
     * @param new_value the value to store
     * @see ReadySet.ContextVarInfo
     */
    public delegate void ContextSetterFunc (Value new_value);

    string locale;

    /**
     * Returns the current locale identifier.
     *
     * On the first call, the function selects the first valid entry reported
     * by {@link GLib.Intl.get_language_names} and caches it. It returns `C`
     * when no valid locale can be found.
     *
     * @return the cached locale identifier
     */
    public string get_current_lang () {
        if (locale == null) {
            locale = "";
        }

        if (locale == "") {
            foreach (string lang in Intl.get_language_names ()) {
                if (locale_is_corrent (lang)) {
                    locale = lang;
                    break;
                }
            }
        }

        if (locale == "") {
            locale = "C";
        }

        return locale;
    }

    /**
     * Changes the process locale and requests a window reload.
     *
     * The locale is applied to all categories with
     * {@link GLib.Intl.setlocale}. If a default application exists, its
     * `reload-window` action is activated so the UI can reflect the change.
     *
     * @param new_lang the locale identifier to apply
     */
    public void set_current_lang (string new_lang) {
        locale = new_lang;
        Intl.setlocale (LocaleCategory.ALL, new_lang);

        var app = Application.get_default ();
        if (app != null) {
            app.activate_action ("reload-window", null);
        }
    }

    Regex locale_regex;
    bool locale_is_corrent (string locale) {
        if (locale_regex == null) {
            try {
                locale_regex = new Regex (
                    "^[A-Za-z][a-z]?[a-z]?(_[A-Z][A-Z])?(\\.[A-Za-z0-9][A-Za-z-0-9]*)?(@[a-z]*)?$"
                );
            } catch (Error e) {
                warning (e.message);
                return false;
            }
        }

        return locale_regex.match (locale);
    }

    /**
     * Check polkit access for org.altlinux.ReadySet.Plugins action.
     */
    public void polkit_check_plugin (BusName sender) throws DBusError {
        polkit_check (sender, "org.altlinux.ReadySet.Plugins");
    }

    /**
     * Check polkit acces for "action_id".
     */
    public void polkit_check (BusName sender, string action_id) throws DBusError {
        Polkit.AuthorizationResult result;

        try {
            var authority = Polkit.Authority.get_sync (null);
            var subject = new Polkit.SystemBusName (sender);
            result = authority.check_authorization_sync (
                subject,
                action_id,
                null,
                Polkit.CheckAuthorizationFlags.ALLOW_USER_INTERACTION,
                null
            );

        } catch (Error e) {
            throw new DBusError.ACCESS_DENIED ("Failed to check authorization: " + e.message);
        }

        if (!result.get_is_authorized ()) {
            throw new DBusError.ACCESS_DENIED ("Not authorized");
        }
    }
}
