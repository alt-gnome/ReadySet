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

public class User.Addin : ReadySet.Addin {

    static Addin instance;

    public override bool accessible { get; set; }

    protected override string? resource_base_path {
        get {
            return "/org/altlinux/ReadySet/Plugin/User/";
        }
    }

    construct {
        instance = this;
    }

    public override ReadySet.BaseBarePage[] build_pages () {
        bool with_root = context.get_boolean ("user-with-root");
        return {
            new User.PageUsername (),
            new User.PagePassword () { with_root_password = with_root }
        };
    }

    public async void apply (ReadySet.ProgressData progres_data) throws ReadySet.ApplyError {
        try {
            var user = yield Act.UserManager.get_default ().create_user_async (
                context.get_string ("user-username"),
                context.get_string ("user-fullname"),
                Act.UserAccountType.ADMINISTRATOR,
                null
            );

            user.set_automatic_login (context.get_boolean ("user-autologin"));
            user.set_password (context.get_string ("user-password"), "");
            if (context.has_key ("language-locale")) {
                user.set_language (context.get_string ("language-locale"));
            }
            if (context.get_string ("user-avatar-file") != "") {
                user.set_icon_file (context.get_string ("user-avatar-file"));
            }

            if (context.get_string ("user-root-password") != "") {
                set_root_password (context.get_string ("user-root-password"));
            } else {
                set_root_password (context.get_string ("user-password"));
            }

        } catch (Error e) {
            throw ReadySet.ApplyError.build_error (_("Error when creating a user"), e.message);
        }
    }

    public override HashTable<string, ReadySet.ContextVarInfo> get_context_vars () {
        var vars = base.get_context_vars ();

        //  Settings
        vars["user-avatar-file"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRING);
        vars["user-with-root"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.BOOLEAN);
        vars["no-password-security"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.BOOLEAN);
        vars["passwd-conf-path"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRING);
        vars["user-avatar-directories"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRV);
        vars["hide-autologin"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.BOOLEAN);
        vars["user-enabled"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.BOOLEAN);
        vars["user-enabled"].initial_value = true;

        //  Storage
        vars["user-username"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRING);
        vars["user-fullname"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRING);
        vars["user-password"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRING);
        vars["user-root-password"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRING);
        vars["user-autologin"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.BOOLEAN);
        return vars;
    }

    internal static Addin get_instance () {
        return instance;
    }

    public override void init_once () {
        base.init_once ();

        context.bind_context_to_property (
            "user-enabled",
            this,
            "accessible",
            SYNC_CREATE
        );
    }
}

public void peas_register_types (TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type (typeof (ReadySet.Addin), typeof (User.Addin));
}
