/*
 * Copyright (C) 2026 Vladimir Romanov <rirusha@altlinux.org>
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

public class Software.Addin : ReadySet.StepAddin, ReadySet.ApplyAfter {

    static Addin instance;

    protected override string? resource_base_path {
        get {
            return "/org/altlinux/ReadySet/Plugin/Software/";
        }
    }

    construct {
        instance = this;
    }

    public async override ReadySet.BasePage[] build_pages () {
        return {
            new Software.Page (context.get_boolean ("software.single-button")),
        };
    }

    internal static Addin get_instance () {
        return instance;
    }

    public string[] get_apply_after () {
        return { "user" };
    }

    public override void init_context () {
        var sources_dir = Path.build_filename (
            Config.READYSET_DATADIR,
            Addin.get_instance ().plugin_info.module_name,
            "sources.d"
        );
        enabled = get_sources (sources_dir).size > 0;
    }

    public override HashTable<string, ReadySet.ContextVarInfo> get_context_vars () {
        var vars = base.get_context_vars ();
        vars["enabled-sources"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRV);
        vars["single-button"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.BOOLEAN, false) { setting = true };
        return vars;
    }

    public async override void apply (ReadySet.ProgressData progres_data) throws ReadySet.ApplyError {
        foreach (var s in get_sources ()) {
            if (s.id in context.get_strv ("software.enabled-sources")) {
                try {
                    yield s.apply ();
                } catch (Error e) {
                    throw ReadySet.ApplyError.build_error (
                        _("Failed to add a software source"),
                        e.message
                    );
                }
            }
        }
    }
}

public void peas_register_types (TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type (typeof (ReadySet.StepAddin), typeof (Software.Addin));
}
