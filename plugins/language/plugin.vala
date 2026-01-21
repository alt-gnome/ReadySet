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

public class Language.Addin : ReadySet.Addin {

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

    public string current_locale {
        owned get {
            return context.get_string ("language-locale");
        }
        set {
            context.set_string ("language-locale", value);
        }
    }

    public Value get_current_locale_func (ref Value this_value) {
        var locale = this_value.get_string ();

        if (locale == "") {
            debug ("Languages: %s", string.joinv (", ", Intl.get_language_names ()));

            foreach (string lang in Intl.get_language_names ()) {
                if (Gnome.Languages.parse_locale (lang, null, null, null, null)) {
                    locale = lang;
                    break;
                }
            }

            if (locale == "") {
                locale = "C";
            }
        }

        this_value.set_string (locale);
        return locale;
    }

    public void set_current_locale_func (ref Value this_value, Value new_value) {
        var nv = new_value.get_string ();
        Intl.setlocale (LocaleCategory.ALL, nv);

        Addin.get_instance ().context.reload_window ();
        this_value.set_string (nv);
    }

    protected override string? resource_base_path {
        get {
            return "/org/altlinux/ReadySet/Plugin/Language/";
        }
    }

    static construct {
        typeof (SelectTitle).ensure ();
        typeof (Box).ensure ();
        typeof (Row).ensure ();
    }

    construct {
        instance = this;

        try {
            accessible = new Polkit.Permission.sync ("org.freedesktop.locale1.set-locale", null, null).allowed;
        } catch (Error e) {
            error (e.message);
        }
    }

    public override HashTable<string, ReadySet.ContextVarInfo> get_context_vars () {
        var vars = base.get_context_vars ();
        vars["language-locale"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRING);

        vars["language-locale"].getter_func = get_current_locale_func;
        vars["language-locale"].setter_func = set_current_locale_func;

        return vars;
    }

    public override ReadySet.BaseBarePage[] build_pages () {
        return { new Language.Page () };
    }

    internal static Addin get_instance () {
        return instance;
    }
}

public void peas_register_types (TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type (typeof (ReadySet.Addin), typeof (Language.Addin));
}
