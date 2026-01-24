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

    ProgressData progress_data = new ProgressData ();

    public async void start_action () {
        stack.visible_child_name = "applying";
        var context = ReadySet.Application.get_default ().context;
        context.locked = true;

        progress_data.bind_property ("message", apply_status_page, "description");
        progress_data.bind_property ("value", progress_bar, "fraction");

        progress_data.notify["value"].connect (update_progress_visibility);
        update_progress_visibility ();

        var app = (ReadySet.Application) GLib.Application.get_default ();

        Gee.ArrayList<Applyable> applyable_arr = new Gee.ArrayList<Applyable> ();

        for (int i = 0; i < app.model.get_n_items (); i++) {
            var page_info = (PageInfo) app.model.get_item (i);

            if (!page_info.apply_plugin) {
                continue;
            }

            if (!(page_info.plugin in applyable_arr)) {
                applyable_arr.add (page_info.plugin);
            }
            applyable_arr.add (page_info.page);
        }

        if (context.idle) {
            Timeout.add_seconds (1, () => {
                progress_data.value += 0.2;
                progress_data.message = _("Doing some stuff…");

                if (progress_data.value >= 1.0) {
                    Idle.add (start_action.callback);
                    return false;
                }

                return true;
            });
            yield;

        } else {
            try {
                foreach (var applyable in applyable_arr) {
                    progress_data.value = 0.0;

                    yield applyable.apply (progress_data);

                    progress_data.value = 1.0;
                }

                var raw_context = context.get_raw_string ();
                var env = new Gee.ArrayList<string> ();

                foreach (var key in raw_context.get_keys ()) {
                    env.add ("%s=\"%s\"".printf (context_key_to_env_key (key), raw_context[key]));
                }

                get_ready_set_proxy ().exec_post_hooks (env.to_array ());

            } catch (ApplyError e) {
                var apply_error_data = ApplyError.to_data (e);

                error_status_page.title = apply_error_data.message;
                error_status_page.description = _("Error message: %s").printf (apply_error_data.description);

                stack.visible_child_name = "error";
                is_ready = false;
            } catch (Error e) {
                error_status_page.title = _("Error while execute post hooks");
                error_status_page.description = _("Error message: %s").printf (e.message);

                stack.visible_child_name = "error";
                is_ready = false;
            }
        }

        stack.visible_child_name = "ready";
        is_ready = true;
    }

    void update_progress_visibility () {
        progress_bar.visible = 1.0 > progress_data.value > 0;
    }
}
