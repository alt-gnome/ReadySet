/*
 * Copyright (C) 2025 Vladimir Romanov <rirusha@altlinux.org>
 * Copyright (C) 2026 Valery Zabrovsky <brow@altlinux.org>
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

namespace Network {

    bool validate_hostname (string hostname, out string? error) {
        if (hostname.has_prefix ("-")) {
            error = _("Leading hyphen is not allowed");
            return false;
        }

        unichar cur;
        int idx = 0;

        while (hostname.get_next_char (ref idx, out cur)) {
            if ((cur >= 0x80 || !cur.isalnum ()) && cur != '-') {
                error = _("Only Latin letters, digits and hyphens are allowed");
                return false;
            }
        }

        if (idx < 4) {
            error = _("Host name is too short");
            return false;
        }

        if (hostname[idx - 1] == '-') {
            error = _("Trailing hyphen is not allowed");
            return false;
        }

        error = null;
        return true;
    }
}
