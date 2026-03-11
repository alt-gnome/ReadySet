/* Copyright (C) 2025 Vladimir Romanov <rirusha@altlinux.org>
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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Keyboard/ui/page.ui")]
public sealed class Keyboard.Page : ReadySet.BasePage {

    [GtkChild]
    unowned Adw.Banner select_at_least_one_banner;

    construct {
        Addin.get_instance ().context.data_changed.connect (on_context_data_changed);
    }

    async void on_context_data_changed (string key) {
        if (key == "keyboard-input-sources") {
            bool has_latin_is = false;
            foreach (var i in get_current_inputs ().to_array ()) {
                if (i.is_latin) {
                    has_latin_is = true;
                    break;
                }
            }
            is_ready = has_latin_is;
            select_at_least_one_banner.revealed = !has_latin_is;
        }
    }
}
