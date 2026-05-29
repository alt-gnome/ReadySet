/*
 * Copyright (C) 2026 David Sultaniiazov <x1z53@alt-gnome.ru>
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

public class LicenseAgreement.Addin : ReadySet.StepAddin {

    static Addin instance;

    protected override string? resource_base_path {
        get {
            return "/org/altlinux/ReadySet/Plugin/LicenseAgreement/";
        }
    }

    construct {
        instance = this;
    }

    public async override ReadySet.BasePage[] build_pages () {
        return {
            new LicenseAgreement.Page (),
        };
    }

    internal static Addin get_instance () {
        return instance;
    }

    public override HashTable<string, ReadySet.ContextVarInfo> get_context_vars () {
        var vars = base.get_context_vars ();
        vars["license-agreement-file-path"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRING);
        vars["license-agreement-language-fallback"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRING);
        return vars;
    }
}

public void peas_register_types (TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type (typeof (ReadySet.StepAddin), typeof (LicenseAgreement.Addin));
}
