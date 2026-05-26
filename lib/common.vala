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

namespace ReadySet {

    internal Value kf_value_to_value (KeyFile keyfile, string group_name, string key, Type value_type) throws Error {
        if (value_type == Type.BOOLEAN) {
            return keyfile.get_boolean (group_name, key);
        } else if (value_type == Type.STRING) {
            return keyfile.get_string (group_name, key);
        } else if (value_type == typeof (string[])) {
            return keyfile.get_string_list (group_name, key);
        } else if (value_type == Type.INT || value_type == Type.INT64) {
            return keyfile.get_int64 (group_name, key);
        } else if (value_type == Type.DOUBLE) {
            return keyfile.get_double (group_name, key);
        } else {
            error ("Unknown keyfile desired type %s for key %s", value_type.name (), key);
        }
    }
}
