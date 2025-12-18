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

    public override bool allowed () {
        try {
            return new Polkit.Permission.sync ("org.freedesktop.locale1.set-keyboard", null, null).allowed;
        } catch (Error e) {
            error (e.message);
        }
    }

    public override async void apply () throws ReadySet.ApplyError {
        var proxy = get_locale_proxy ();

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

        try {
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
