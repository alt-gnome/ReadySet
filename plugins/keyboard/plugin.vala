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

public class Keyboard.Addin : ReadySet.StepAddin {

    static Addin instance;

    bool _accessible;
    public override bool accessible {
        get {
            return _accessible;
        }
        protected set {
            _accessible = value;
        }
    }

    protected override string? resource_base_path {
        get {
            return "/org/altlinux/ReadySet/Plugin/Keyboard/";
        }
    }

    static construct {
        typeof (InputChooser).ensure ();
    }

    construct {
        instance = this;
    }

    public async override ReadySet.BaseBarePage[] build_pages () {
        return { new Keyboard.Page () };
    }

    internal static Addin get_instance () {
        return instance;
    }

    public async override void init_once () {
        if (!context.sandbox && context.mode == INITIAL_SETUP) {
            try {
                accessible = (yield new Polkit.Permission ("org.freedesktop.locale1.set-keyboard", null, null)).allowed;
            } catch (Error e) {
                error (e.message);
            }
        }
    }

    public override HashTable<string, ReadySet.ContextVarInfo> get_context_vars () {
        var vars = base.get_context_vars ();
        vars["keyboard-input-sources"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.OBJECT, get_default ());
        return vars;
    }

    ReadySet.ContextObject get_default () {
        var inputs = new InputSources ();

        var settings = new Settings ("org.gnome.desktop.input-sources");
        var variant = settings.get_value ("sources");

        var iterator = variant.iterator ();

        Variant? item;
        while ((item = iterator.next_value ()) != null) {
            string input_type, input_id;

            item.get ("(ss)", out input_type, out input_id);
            inputs.add (new InputInfo (input_type, input_id));
        }

        if (inputs.size == 0) {
            inputs.add_many (get_system_inputs ());
        }

        return inputs;
    }

    public async override void apply (ReadySet.ProgressData progress_data) throws ReadySet.ApplyError {
        try {
            var proxy = get_locale_proxy ();

            var inputs = get_current_inputs ();

            var layouts = new Gee.ArrayList<string> ();
            var variants = new Gee.ArrayList<string> ();

            foreach (var input in inputs.to_array ()) {
                layouts.add (input.layout);
                variants.add (input.variant ?? "");
            }

            yield proxy.set_x_11_keyboard (string.joinv (
                ",",
                layouts.to_array ()),
                "",
                string.joinv (",", variants.to_array ()),
                "",
                true,
                true
            );
        } catch (Error e) {
            throw ReadySet.ApplyError.build_error (_("Error when setting keyboard layout"), e.message);
        }
    }
}

public void peas_register_types (TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type (typeof (ReadySet.StepAddin), typeof (Keyboard.Addin));
}
