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
public interface Keyboard.Locale1 : Object {
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

    public string layout { get; construct; }

    public string? variant { get; construct; }

    public string type_ { get; construct; }

    public string format { get; construct; }

    public bool is_latin { get; construct; }

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

    construct {
        var parts = id.split ("+", 2);
        layout = parts[0];
        if (parts.length == 2) {
            variant = parts[1];
        }

        if (type_ == "xkb") {
            is_latin = xkb_has_latin (layout, variant);
        }
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
        if (context.has_key ("language-locale")) {
            return context.get_string ("language-locale");
        }

        return "C";
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

            if (input_sources.size == 0) {
                input_sources.add_all_array (get_system_inputs ());
            }

            if (input_sources.size != 0) {
                set_current_inputs (input_sources);
            }

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

        if (!context.intact) {
            VariantBuilder builder = new VariantBuilder (new VariantType ("a(ss)"));

            foreach (var info in inputs) {
                builder.add ("(ss)", info.type_, info.id);
            }

            var settings = new Settings ("org.gnome.desktop.input-sources");
            settings.set_value ("sources", builder.end ());
        }

        context.set_strv ("keyboard-input-sources", inputs_val.data);
    }

    Keyboard.Locale1 get_locale_proxy () throws Error {
        var con = Bus.get_sync (BusType.SYSTEM);

        if (con == null) {
            error ("Failed to connect to bus");
        }

        return con.get_proxy_sync<Keyboard.Locale1> (
            "org.freedesktop.locale1",
            "/org/freedesktop/locale1",
            DBusProxyFlags.NONE
        );
    }

    InputInfo[] get_system_inputs () {
        try {
            var proxy = get_locale_proxy ();

            var raw_layouts = proxy.x_11_layout;
            var raw_variants = proxy.x_11_variant;

            string[] layouts;
            string[] variants;

            if (raw_layouts == "") {
                layouts = { "us" };
            } else {
                layouts = raw_layouts.split (",");
            }
            if (raw_variants == "") {
                variants = { "" };
            } else {
                variants = raw_variants.split (",");
            }

            if (layouts.length != variants.length) {
                return {};
            }

            InputInfo[] inputs = new InputInfo[layouts.length];

            for (int i = 0; i < layouts.length; i++) {
                if (variants[i] == "") {
                    inputs[i] = new InputInfo ("xkb", layouts[i]);
                } else {
                    inputs[i] = new InputInfo ("xkb", @"$(layouts[i])+$(variants[i])");
                }
            }

            return inputs;

        } catch (Error e) {
            return {};
        }
    }

    Xkb.Context? context;

    Xkb.Context? get_context () {
        if (context == null) {
            context = new Xkb.Context (Xkb.ContextFlags.NO_FLAGS);
        }

        return context;
    }

    public bool xkb_has_latin (string layout, string? variant = null) {
        if (layout == "custom") {
            return false;
        }

        var ctx = get_context ();
        if (ctx == null) {
            return false;
        }

        Xkb.RulesNames names = {
            rules: "evdev",
            model: "pc105",
            layout: layout,
            variant: variant,
            options: null
        };

        var keymap = Xkb.Keymap.new_from_names (ctx, names, Xkb.KeymapCompileFlags.NO_FLAGS);
        if (keymap == null) {
            return false;
        }

        var state = new Xkb.State (keymap);
        if (state == null) {
            return false;
        }

        bool found_latin = false;
        for (uint keycode = 8; keycode <= 255; keycode++) {
            Xkb.Keysym ks = state.key_get_one_sym ((Xkb.Keycode) keycode);

            // Check if keysym is latin character
            // a-z = 0x0061-0x007A, A-Z = 0x0041-0x005A
            if ((ks >= 0x0061 && ks <= 0x007A) || (ks >= 0x0041 && ks <= 0x005A)) {
                found_latin = true;
                break;
            }
        }

        return found_latin;
    }
}
