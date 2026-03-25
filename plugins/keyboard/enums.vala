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

namespace Keyboard {

    public enum AdditionalLayoutSwitch {
        NONE,
        ALT_SHIFT,
        CTRL_SHIFT,
        CAPS;

        public static AdditionalLayoutSwitch from_string (string ls) {
            switch (ls) {
                case "grp:alt_shift_toggle":
                    return ALT_SHIFT;
                case "grp:ctrl_shift_toggle":
                    return CTRL_SHIFT;
                case "grp:caps_toggle":
                    return CAPS;
                default:
                    return NONE;
            }
        }

        public string to_string () {
            switch (this) {
                case ALT_SHIFT:
                    return "grp:alt_shift_toggle";
                case CTRL_SHIFT:
                    return "grp:ctrl_shift_toggle";
                case CAPS:
                    return "grp:caps_toggle";
                default:
                    assert_not_reached ();
            }
        }

        public string[] to_buttons () {
            switch (this) {
                case NONE:
                    return {};
                case ALT_SHIFT:
                    return { "Alt", "Shift" };
                case CTRL_SHIFT:
                    return { "Ctrl", "Shift" };
                case CAPS:
                    return { "Caps Lock" };
                default:
                    assert_not_reached ();
            }
        }

        public string get_description () {
            if (this == NONE) {
                return _("None");
            }
            return get_xkb_info ().description_for_option ("grp", to_string ());
        }
    }
}
