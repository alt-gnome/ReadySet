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

public class LicenseAgreement.Addin : ReadySet.StepAddin, ReadySet.ExistingUser {

    static Addin instance;

    public string passed_hash { get; set; }
    public string new_hash { get; set; default = ""; }

    protected override string? resource_base_path {
        get {
            return "/org/altlinux/ReadySet/Plugin/LicenseAgreement/";
        }
    }

    construct {
        instance = this;
    }

    public override ReadySet.ExistingUserStatus get_existing_user () {
        if (new_hash != passed_hash) {
            return YES;
        } else {
            return IF_NOT_PASSED;
        }
    }

    public override void init () {
        if (context.get_string ("license-agreement.file-path") == "") {
            return;
        }

        Settings la_settings = new Settings ("org.altlinux.ReadySet.license-agreement");
        passed_hash = la_settings.get_string ("passed-license-hash");

        var text = get_raw_license_text (context.get_string ("license-agreement.file-path"), true);

        // Fallback have to be always present
        assert (text != null && text != "");

        new_hash = Checksum.compute_for_string (SHA512, text);
    }

    public async override ReadySet.BasePage[] build_pages () {
        if (context.get_boolean ("license-agreement.installer")) {
            return {};
        }
        return {
            new LicenseAgreement.Page (),
        };
    }

    internal static Addin get_instance () {
        return instance;
    }

    public override HashTable<string, ReadySet.ContextVarInfo> get_context_vars () {
        var vars = base.get_context_vars ();
        vars["file-path"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRING) { setting = true };
        vars["language-fallback"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRING, "C") { setting = true };
        vars["installer"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.BOOLEAN) { setting = true };
        return vars;
    }

    public async override void apply (ReadySet.ProgressData progres_data) throws ReadySet.ApplyError {
        if (context.sandbox) {
            return;
        }

        Settings la_settings = new Settings ("org.altlinux.ReadySet.license-agreement");
        la_settings.set_string ("passed-license-hash", new_hash);
    }
}

public void peas_register_types (TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type (typeof (ReadySet.StepAddin), typeof (LicenseAgreement.Addin));
}
