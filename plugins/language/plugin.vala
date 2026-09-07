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

public class Language.Addin : ReadySet.StepAddin, ReadySet.Welcome {

    static Addin instance;

    public string current_locale {
        owned get {
            return context.get_string ("language.locale");
        }
        set {
            context.set_string ("language.locale", value);
        }
    }

    public Value get_current_locale_func () {
        return ReadySet.get_current_lang ();
    }

    public void set_current_locale_func (Value new_value) {
        ReadySet.set_current_lang (new_value.get_string ());
    }

    protected override string? resource_base_path {
        get {
            return "/org/altlinux/ReadySet/Plugin/Language/";
        }
    }

    static construct {
        typeof (SelectTitle).ensure ();
        typeof (Info).ensure ();
        typeof (Box).ensure ();
        typeof (Row).ensure ();
    }

    construct {
        instance = this;
    }

    public override HashTable<string, ReadySet.ContextVarInfo> get_context_vars () {
        var vars = base.get_context_vars ();

        vars["locale"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRING) {
            getter_func = get_current_locale_func,
            setter_func = set_current_locale_func,
        };

        return vars;
    }

    public async override ReadySet.BasePage[] build_pages () {
        return {
            new Language.Page ()
        };
    }

    internal static Addin get_instance () {
        return instance;
    }

    public override void init_context () {
        if (!context.sandbox && context.mode == INITIAL_SETUP) {
            try {
                enabled = new Polkit.Permission.sync ("org.freedesktop.locale1.set-locale", null, null).allowed &&
                    context.get_boolean ("steps.language.enabled");
            } catch (Error e) {
                error (e.message);
            }
        }
    }

    public async override void apply (ReadySet.ProgressData progress_data) throws ReadySet.ApplyError {
        try {
            var proxy = yield get_locale_proxy ();

            yield proxy.set_locale ({ @"LANG=$(Addin.get_instance ().current_locale)" }, true);
        } catch (Error e) {
            throw ReadySet.ApplyError.build_error (_("Error when setting language"), e.message);
        }
    }
}

public void peas_register_types (TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type (typeof (ReadySet.StepAddin), typeof (Language.Addin));
}
