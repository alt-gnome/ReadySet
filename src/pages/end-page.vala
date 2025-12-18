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

[GtkTemplate (ui = "/org/altlinux/ReadySet/ui/end-page.ui")]
public sealed class ReadySet.EndPage : BasePage {

    [GtkChild]
    unowned Gtk.Stack stack;

    public string error_title { get; set; }

    public string error_description { get; set; }

    public string loading_status { get; set; }

    construct {
        start_loading ();
    }

    public async void start_action () {
        stack.visible_child_name = "load";

        try {
            var app = (ReadySet.Application) GLib.Application.get_default ();
            foreach (var callback_page in app.callback_pages) {
                if (app.idle) {
                    Timeout.add_seconds_once (1, () => {
                        Idle.add (start_action.callback);
                    });
                    yield;

                } else {
                    loading_status = callback_page.start_apply_message;
                    yield callback_page.apply ();
                }
            }

            foreach (var callback_addin in app.callback_addins) {
                if (app.idle) {
                    Timeout.add_seconds_once (1, () => {
                        Idle.add (start_action.callback);
                    });
                    yield;

                } else {
                    loading_status = callback_addin.start_apply_message;
                    yield callback_addin.apply ();
                }
            }

            stop_loading ();
            stack.visible_child_name = "ready";
            is_ready = true;

        } catch (ApplyError error) {
            var apply_error_data = ApplyError.to_data (error);

            error_title = apply_error_data.message;
            error_description = apply_error_data.description;

            error_description = _("Error message: %s").printf (error_description);

            stop_loading ();
            icon_name = "dialog-error-symbolic";
            stack.visible_child_name = "error";
            is_ready = false;
        }
    }

    public override async void apply () throws ApplyError {
        return;
    }
}
