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
public sealed class ReadySet.EndPage : BaseBarePage {

    [GtkChild]
    unowned Gtk.Stack stack;
    [GtkChild]
    unowned Adw.StatusPage error_status_page;
    [GtkChild]
    unowned Adw.StatusPage apply_status_page;
    [GtkChild]
    unowned Gtk.ProgressBar progress_bar;

    public string loading_status { get; set; }

    ProgressData progress_data = new ProgressData ();

    public async void start_action () {
        stack.visible_child_name = "applying";
        var context = ReadySet.Application.get_default ().context;

        progress_data.bind_property ("message", apply_status_page, "description");
        progress_data.bind_property ("value", progress_bar, "fraction");

        progress_data.notify["value"].connect (update_progress_visibility);
        update_progress_visibility ();

        try {
            var app = (ReadySet.Application) GLib.Application.get_default ();
            foreach (var callback_page in app.loaded_pages) {
                if (callback_page.get_data<string> (STEP_ID_LABEL) in app.options_handler.steps_no_apply) {
                    continue;
                }

                if (context.idle) {
                    Timeout.add_seconds_once (1, () => {
                        progress_data.value += 0.1;
                        progress_data.message = _("Doing some stuff…");
                        Idle.add (start_action.callback);
                    });
                    yield;

                } else {
                    yield callback_page.apply (progress_data);
                }
            }

            foreach (var callback_addin in app.loaded_addins) {
                if (callback_addin.get_data<string> (STEP_ID_LABEL) in app.options_handler.steps_no_apply) {
                    continue;
                }

                if (context.idle) {
                    Timeout.add_seconds_once (1, () => {
                        Idle.add (start_action.callback);
                    });
                    yield;

                } else {
                    loading_status = callback_addin.start_apply_message;
                    yield callback_addin.apply ();
                }
            }

            stack.visible_child_name = "ready";
            is_ready = true;

        } catch (ApplyError error) {
            var apply_error_data = ApplyError.to_data (error);

            error_status_page.title = apply_error_data.message;
            error_status_page.description = _("Error message: %s").printf (apply_error_data.description);

            icon_name = "dialog-error-symbolic";
            stack.visible_child_name = "error";
            is_ready = false;
        }
    }

    void update_progress_visibility () {
        progress_bar.visible = 1.0 > progress_data.value > 0;
    }
}
