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

namespace Software {

    public void switch_source (string id, bool enabled) {
        var all_enabled = Addin.get_instance ().context.get_strv ("software.enabled-sources");

        if (enabled) {
            if (!(id in all_enabled)) {
                all_enabled += id;
            }
        } else {
            string[] new_enabled = {};
            foreach (string s in all_enabled) {
                if (s != id) {
                    new_enabled += s;
                }
            }
            all_enabled = new_enabled;
        }

        Addin.get_instance ().context.set_strv ("software.enabled-sources", all_enabled);
    }
}
