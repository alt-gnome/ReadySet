/*
 * Copyright (C) 2024-2026 Vladimir Romanov <rirusha@altlinux.org>
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

[GtkTemplate (ui = "/org/altlinux/ReadySet/ui/installer-end-page.ui")]
public sealed class ReadySet.InstallerEndPage : Adw.Bin {

    [GtkChild]
    unowned Gtk.Stack stack;
    [GtkChild]
    unowned Adw.StatusPage error_status_page;
    [GtkChild]
    unowned Adw.StatusPage apply_status_page;
    [GtkChild]
    unowned Gtk.ProgressBar progress_bar;
    [GtkChild]
    unowned Adw.StatusPage status_page;
    [GtkChild]
    unowned Gtk.Button finish_button;

    ProgressData progress_data = new ProgressData ();

    construct {
        var name = Environment.get_os_info (OsInfoKey.NAME);

        if (name != null) {
            //  Translators: %s here is os distribution name: ALT, Fedora, Ubuntu
            finish_button.label = _("_Start Using %s").printf (name);
            //  Translators: %s here is os distribution name: ALT, Fedora, Ubuntu
            status_page.description = _("%s is ready to be used.").printf (name);
        } else {
            finish_button.label = _("_Start Using the System");
            status_page.description = _("System is ready to be used.");
        }
    }

    public async void start_action () {
        var app = Application.get_default ();
        var context = app.context;

        stack.visible_child_name = "applying";

        progress_data.bind_property ("message", apply_status_page, "description");
        progress_data.bind_property ("value", progress_bar, "fraction");

        progress_data.notify["value"].connect (update_progress_visibility);
        update_progress_visibility ();

        Gee.ArrayList<StepAddin> steps_addins_arr = new Gee.ArrayList<StepAddin> ();

        for (int i = 0; i < app.model.get_n_items_unfiltered (); i++) {
            var page_info = (PageInfo) app.model.get_item_unfiltered (i);

            //  can_be_applyed also null checl
            if (!page_info.can_be_applyed ()) {
                continue;
            }

            if (!(page_info.plugin in steps_addins_arr) && page_info.plugin_info.module_name != "welcome") {
                steps_addins_arr.add (page_info.plugin);
            }
        }

        if (context.sandbox) {
            progress_data.message = _("Installing system…");

            Timeout.add_seconds (1, () => {
                progress_data.value += 0.2;

                if (progress_data.value >= 1.0) {
                    Idle.add (start_action.callback);
                    return false;
                }

                return true;
            });
            yield;

            stack.visible_child_name = "ready";

        } else {
            try {
                yield app.installer_plugin.install (progress_data);

                try {
                    var raw_context = context.get_raw_string ();
                    var env = new Gee.ArrayList<string> ();

                    foreach (var key in raw_context.get_keys ()) {
                        env.add ("%s=%s".printf (context_key_to_env_key (key), raw_context[key]));
                    }

                    string hooks_type = "post";
                    string hooks_target = "installer";

                    foreach (var name in yield get_ready_set_proxy ().get_all_hooks (hooks_type, hooks_target)) {
                        yield get_ready_set_proxy ().exec_hook (hooks_type, hooks_target, name, env.to_array ());
                    }
                } catch (Error e) {
                    warning ("Error on executing post hooks: %s", e.message);
                }

                stack.visible_child_name = "ready";

            } catch (ApplyError e) {
                var apply_error_data = apply_error_to_data (e);

                error_status_page.title = apply_error_data.message;
                error_status_page.description = _("Error message: %s").printf (apply_error_data.description);

                stack.visible_child_name = "error";

            }
        }
    }

    [GtkCallback]
    void on_finish () {
        Application.get_default ().quit ();
    }

    void update_progress_visibility () {
        progress_bar.visible = 1.0 > progress_data.value > 0;
    }
}
