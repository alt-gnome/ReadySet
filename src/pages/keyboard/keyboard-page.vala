/* Copyright 2025 Vladimir Vaskov <rirusha@altlinux.org>
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

[GtkTemplate (ui = "/space/rirusha/ReadySet/ui/keyboard-page.ui")]
public sealed class ReadySet.KeyboardPage : BasePage {

    [GtkChild]
    unowned InputChooser input_chooser;

    construct {
        input_chooser.changed.connect ((inputs) => {
            if (inputs.length > 0) {
                is_ready = true;
                show_banner = false;

            } else {
                is_ready = false;
                show_banner = true;
                banner_message = _("No input source selected");
            }

            if (is_ready) {
                apply_input_sources (inputs);
            }
        });
    }

    void apply_input_sources (InputInfo[] inputs) {
        VariantBuilder builer = new VariantBuilder (new VariantType ("a(ss)"));

        foreach (var info in inputs) {
            builer.add ("(ss)", info.type_, info.id);
        }

        var settings = new Settings ("org.gnome.desktop.input-sources");
        settings.set_value ("sources", builer.end ());
    }
}
