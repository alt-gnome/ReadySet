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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Keyboard/ui/preview-dialog.ui")]
public sealed class Keyboard.PreviewDialog : Adw.Dialog {

    [GtkChild]
    unowned Gtk.Button tecla_button;

    public InputInfo input_info {get; construct; }

    InputSources current_inputs;

    public PreviewDialog (InputInfo input_info) {
        Object (input_info: input_info);
    }

    ~PreviewDialog () {
        set_user_inputs (current_inputs.to_array ());
    }

    construct {
        current_inputs = get_current_inputs ();
        set_user_inputs ({input_info});
        update_tecla_button_visible ();
    }

    void update_tecla_button_visible () {
        tecla_button.visible = get_preview_path () != null &&
            input_info.type_ == InputSourcesManager.INPUT_SOURCE_TYPE_XKB;
    }

    string? get_preview_path () {
        return Environment.find_program_in_path (Addin.get_instance ().context.get_string ("keyboard-preview-bin"));
    }

    [GtkCallback]
    async void on_preview_clicked () {
        var preview_path = get_preview_path ();
        assert (preview_path != null);

        string arg = input_info.layout;
        if (input_info.variant != null) {
            arg += @"+$(input_info.variant)";
        }

        try {
            var sp = new Subprocess.newv ({ preview_path, arg }, NONE);
            yield sp.wait_check_async ();
        } catch (Error e) {
            warning (e.message);
        }
    }
}
