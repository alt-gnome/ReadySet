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

public class Keyboard.Addin : ReadySet.Addin {

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

    public override ReadySet.BaseBarePage[] build_pages () {
        return { new Keyboard.Page () };
    }

    internal static Addin get_instance () {
        return instance;
    }

    public override void init_once () {
        if (!context.idle) {
            try {
                accessible = new Polkit.Permission.sync ("org.freedesktop.locale1.set-keyboard", null, null).allowed;
            } catch (Error e) {
                error (e.message);
            }
        }
    }

    public override HashTable<string, ReadySet.ContextVarInfo> get_context_vars () {
        var vars = base.get_context_vars ();
        vars["keyboard-input-sources"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRV);
        return vars;
    }
}

public void peas_register_types (TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type (typeof (ReadySet.Addin), typeof (Keyboard.Addin));
}
