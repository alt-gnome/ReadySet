/* Copyright (C) 2024-2025 Vladimir Romanov <rirusha@altlinux.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#if HAVE_IBUS
namespace ReadySet {
    public string? engine_get_display_name (IBus.EngineDesc engine_desc) {
        string name = engine_desc.get_longname ();
        string language_code = engine_desc.get_language ();
        string language = IBus.get_language_name (language_code);
        string textdomain = engine_desc.get_textdomain ();

        if (textdomain != "" && name != "")
            name = dgettext (textdomain, name);

        return "%s (%s)".printf (language, name);
    }
}
#endif
