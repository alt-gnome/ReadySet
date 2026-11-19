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

[GtkTemplate (ui = "/org/altlinux/ReadySet/ui/initial-setup-end-page.ui")]
public sealed class ReadySet.InitialSetupEndPage : EndPage {

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

    InitialSetupProgressData progress_data = new InitialSetupProgressData ();

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

    public override async void start_action () {
        stack.visible_child_name = "applying";

        progress_data.bind_property ("description", apply_status_page, "description", SYNC_CREATE);
        progress_data.bind_property ("value", progress_bar, "fraction", SYNC_CREATE);
        progress_data.bind_property ("pulse-step", progress_bar, "pulse-step", SYNC_CREATE);
        progress_data.pulse.connect (on_pulse);

        progress_data.bind_property ("visibility", progress_bar, "visible", SYNC_CREATE);

        try {
            if (sandbox) {
                progress_data.description = _("Applying changes…");

                yield fake_initial_setup (progress_data);

                stack.visible_child_name = "ready";
            } else {
                yield finalizer.run (progress_data);
                stack.visible_child_name = "ready";
            }

        } catch (ApplyError e) {
            var error_data = apply_error_to_data (e);
            error_status_page.title = error_data.message;
            error_status_page.description = _("Error message: %s").printf (error_data.description);
            stack.visible_child_name = "error";
        }
    }

    void on_pulse () {
        progress_bar.pulse ();
    }

    async void fake_initial_setup (InitialSetupProgressData progress_data) throws ApplyError {
        progress_data.pulse_step = 0.6;

        for (uint i = 0; i < 5; i++) {
            progress_data.description = "Doing stuff %u with pulse".printf (i);
            yield wait_async (1);
            progress_data.pulse ();
        }

        double val = 0;
        for (uint i = 0; i < 5; i++) {
            progress_data.description = "Doing stuff %u".printf (i);
            progress_data.value = val;
            yield wait_async (1);
            val += 0.2;
        }

        yield wait_async (1);
    }
}
