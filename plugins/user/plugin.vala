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

public class User.Addin : ReadySet.StepAddin {

    static Addin instance;

    public override string plugin_name { get { return "user"; } }

    protected override string? resource_base_path {
        get {
            return "/org/altlinux/ReadySet/Plugin/User/";
        }
    }

    construct {
        instance = this;
    }

    public async override ReadySet.BasePage[] build_pages () {
        return {
            new User.PageUsername (),
            new User.PagePassword (),
            new User.PageRootPassword ()
        };
    }

    public async override void apply (ReadySet.ProgressData progres_data) throws ReadySet.ApplyError {
        try {
            var user = yield Act.UserManager.get_default ().create_user_async (
                context.get_string ("user.username"),
                context.get_string ("user.fullname"),
                Act.UserAccountType.ADMINISTRATOR,
                null
            );

            if (user.uses_homed ()) {
                if (context.get_string ("user.password") == "" && context.get_string ("user.password-hash") != "") {
                    warning ("Password hash set but plain version doesn't. It could leads to unexpected behaivor");
                }
                yield set_homed_password (context.get_string ("user.username"), context.get_string ("user.password"));
            } else {
                yield set_user_password (context.get_string ("user.password-hash"), (uint) user.get_uid ());
            }

            user.set_language (ReadySet.get_current_lang ());
            if (context.get_string ("user.avatar-file") != "") {
                set_user_icon_file (user, context.get_string ("user.avatar-file"));
            }

            if (context.get_boolean ("user.with-root")) {
                if (context.get_string ("user.root-password-hash") != "") {
                    yield set_user_password (context.get_string ("user.root-password-hash"), 0);
                } else {
                    yield set_user_password (context.get_string ("user.password-hash"), 0);
                }
            }

        } catch (Error e) {
            throw ReadySet.ApplyError.build_error (_("Error when creating a user"), e.message);
        }
    }

    public override void init_context () {
        context.data_changed.connect (on_data_changed);
    }

    void on_data_changed (Object obj, string key) {
        var context = (ReadySet.Context) obj;
        string pas;

        switch (key) {
            case "user.password":
                pas = context.get_string ("user.password");
                break;
            case "user.root-password":
                pas = context.get_string ("user.root-password");
                break;
            default:
                return;
        }

        context.set_string (
            key + "-hash",
            pas != "" ? UserC.hash_password (pas) : ""
        );
    }

    public override HashTable<string, ReadySet.ContextVarInfo> get_context_vars () {
        var vars = base.get_context_vars ();

        //  Settings
        vars["avatar-file"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRING);
        vars["with-root"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.BOOLEAN);
        vars["enforce-password-quality"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.BOOLEAN);
        vars["passwd-conf-path"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRING);
        vars["avatar-directories"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRV);

        //  Storage
        vars["username"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRING);
        vars["fullname"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRING);

        vars["password"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRING);
        vars["password-hash"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRING);
        vars["root-password"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRING);
        vars["root-password-hash"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRING);

        return vars;
    }

    internal static Addin get_instance () {
        return instance;
    }
}

public void peas_register_types (TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type (typeof (ReadySet.StepAddin), typeof (User.Addin));
}
