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

[DBus (name = "org.freedesktop.locale1")]
public interface Locale1 : Object {
    public abstract string[] locale { owned get; }
    public abstract string v_console_toggle { owned get; }
    public abstract string v_console_keymap_toggle { owned get; }
    public abstract string x_11_layout { owned get; }
    public abstract string x_11_model { owned get; }
    public abstract string x_11_options { owned get; }
    public abstract string x_11_variant { owned get; }

    public abstract async void set_locale (
        string[] locale,
        bool interactive
    ) throws Error;

    public abstract async void set_v_console_keyboard (
        string keymap,
        string keymap_toggle,
        bool convert,
        bool interactive
    ) throws Error;

    public abstract async void set_x_11_keyboard (
        string layout,
        string model,
        string variant,
        string options,
        bool convert,
        bool interactive
    ) throws Error;
}

public class Keyboard.InputInfo : Object {

    public string id { get; construct; }

    public string type_ { get; construct; }

    public string format { get; construct; }

    public InputInfo (string type, string id_) {
        Object (
            id: id_,
            type_: type,
            format: "%s::%s".printf (type, id_)
        );
    }

    public uint _hash () {
        return format.hash ();
    }

    public static uint hash (InputInfo a) {
        return a._hash ();
    }

    public static bool equal (InputInfo a, InputInfo b) {
        return strcmp (a.format, b.format) == 0;
    }
}

namespace Keyboard {

    public string get_current_language () {
        var context = Addin.get_instance ().context;

        var locale = context.get_string ("locale");

        if (locale == null) {
            debug ("Languages: %s", string.joinv (", ", Intl.get_language_names ()));

            foreach (string lang in Intl.get_language_names ()) {
                if (Gnome.Languages.parse_locale (lang, null, null, null, null)) {
                    locale = lang;
                    break;
                }
            }

            if (locale == null) {
                locale = "C";
            }
        }

        return locale;
    }

    public Gee.HashSet<InputInfo> get_current_inputs () {
        var context = Addin.get_instance ().context;

        Gee.HashSet<InputInfo> input_sources;
        var inputs_val = context.get_data ("input-sources");

        if (inputs_val == null) {
            input_sources = new Gee.HashSet<InputInfo> (InputInfo.hash, InputInfo.equal);
            context.set_data ("input-sources", input_sources);
        } else {
            input_sources = (Gee.HashSet<InputInfo>) inputs_val.get_object ();
        }

        return input_sources;
    }

    public void set_current_inputs (Gee.HashSet<InputInfo> inputs) {
        var context = Addin.get_instance ().context;

        context.set_data ("input-sources", inputs);
    }

    Locale1 get_locale_proxy () {
        try {
            var con = Bus.get_sync (BusType.SYSTEM);

            if (con == null) {
                error ("Failed to connect to bus");
            }

            return con.get_proxy_sync<Locale1> (
                "org.freedesktop.locale1",
                "/org/freedesktop/locale1",
                DBusProxyFlags.NONE
            );
        } catch (Error e) {
            error (e.message);
        }
    }
}
