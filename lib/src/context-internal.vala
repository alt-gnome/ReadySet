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

public partial class ReadySet.Context {

    internal void register_vars (string module_name, HashTable<string, ContextVarInfo> vars) {
        vars.foreach ((key, info) => {
            var module_key = "%s.%s".printf (module_name, key);

            if (data.has_key (module_key)) {
                warning ("Key %s already exists in context, it will be overwriting", module_key);
            }
            debug ("Registering key %s with type %s", module_key, info.value_type.to_string ());
            data[module_key] = new ValueObject (info);
            data[module_key].data_key = module_key;

            if (info.getter_func != null || info.setter_func != null) {
                data[module_key].set_gsetters (info.getter_func, info.setter_func);
            }
            data[module_key].notify["real-value"].connect ((caller, param) => {
                data_changed (((ValueObject) caller).data_key);
            });
        });
    }
}

internal partial class ReadySet.ValueObject {

    public string data_key;

    public void set_gsetters (ContextGetterFunc getter_func, ContextSetterFunc setter_func) {
        assert (getter_func != null && setter_func != null);

        this.getter_func = getter_func;
        this.setter_func = setter_func;
    }
}
