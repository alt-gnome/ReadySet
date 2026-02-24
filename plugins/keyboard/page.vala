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
    unowned InputChooser input_chooser;

    construct {
        input_chooser.changed.connect ((inputs) => {
            is_ready = inputs.length > 0;
        });

        var input_sources_val = Addin.get_instance ().context.get_strv ("keyboard-input-sources");
        if (input_sources_val.length > 0) {
            var input_sources = new Gee.HashSet<InputInfo> (InputInfo.hash, InputInfo.equal);
            foreach (var input in input_sources_val) {
                input_sources.add (new InputInfo.from_format (input));
            }
            set_current_inputs (input_sources);
        }
    }

    public async override void apply (ReadySet.ProgressData progress_data) throws ReadySet.ApplyError {
        try {
            var proxy = yield get_locale_proxy ();

            var current_inputs_info = get_current_inputs ();
            var inputs = current_inputs_info.to_array ();

            var layouts = new Gee.ArrayList<string> ();
            var variants = new Gee.ArrayList<string> ();

            foreach (var input in inputs) {
                var lv = input.id.split ("+");

                string layout;
                string variant;
                if (lv.length > 1) {
                    layout = lv[0];
                    variant = lv[1];
                } else {
                    layout = lv[0];
                    variant = "";
                }

                layouts.add (layout);
                variants.add (variant);
            }

            yield proxy.set_x_11_keyboard (string.joinv (
                ",",
                layouts.to_array ()),
                "",
                string.joinv (",", variants.to_array ()),
                "",
                true,
                true
            );
        } catch (Error e) {
            throw ReadySet.ApplyError.build_error (_("Error when setting keyboard layout"), e.message);
        }
    }
}
