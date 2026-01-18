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

    public InputInfo.from_format (string format) {
        var parts = format.split ("::", 2);
        if (parts.length != 2) {
            error ("Invalid input sources format: `%s`", format);
        }
        Object (
            id: parts[1],
            type_: parts[0],
            format: format
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
        return Addin.get_instance ().context.get_string ("language-locale");
    }

    public Gee.HashSet<InputInfo> get_current_inputs () {
        var context = Addin.get_instance ().context;

        var input_sources = new Gee.HashSet<InputInfo> (InputInfo.hash, InputInfo.equal);
        var inputs_val = context.get_strv ("keyboard-input-sources");

        if (inputs_val.length == 0) {
            var settings = new Settings ("org.gnome.desktop.input-sources");
            var variant = settings.get_value ("sources");

            var iterator = variant.iterator ();

            Variant? item;
            while ((item = iterator.next_value ()) != null) {
                string input_type, input_id;

                item.get ("(ss)", out input_type, out input_id);
                input_sources.add (new InputInfo (input_type, input_id));
            }
            set_current_inputs (input_sources);

        } else {
            foreach (var input in inputs_val) {
                input_sources.add (new InputInfo.from_format (input));
            }
        }

        return input_sources;
    }

    public void set_current_inputs (Gee.HashSet<InputInfo> inputs) {
        var context = Addin.get_instance ().context;
        var inputs_val = new Array<string> ();

        foreach (var input in inputs) {
            inputs_val.append_val (input.format);
        }

        if (!context.idle) {
            VariantBuilder builder = new VariantBuilder (new VariantType ("a(ss)"));

            foreach (var info in inputs) {
                builder.add ("(ss)", info.type_, info.id);
            }

            var settings = new Settings ("org.gnome.desktop.input-sources");
            settings.set_value ("sources", builder.end ());
        }

        context.set_strv ("keyboard-input-sources", inputs_val.data);
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
