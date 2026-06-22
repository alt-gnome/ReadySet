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

[GtkTemplate (ui = "/org/altlinux/ReadySet/ui/existing-user-end-page.ui")]
public sealed class ReadySet.ExistingUserEndPage : Adw.Bin {

    [GtkCallback]
    void on_complete () {
        var app = Application.get_default ();

        if (!app.context.sandbox) {
            Gee.ArrayList<StepAddin> steps_addins_arr = new Gee.ArrayList<StepAddin> ();

            for (int i = 0; i < app.model.get_n_items (); i++) {
                var page_info = (PageInfo) app.model.get_item (i);

                if (!(page_info.plugin in steps_addins_arr) &&
                    page_info.plugin.enabled && page_info.plugin_info.module_name != "welcome") {
                    steps_addins_arr.add (page_info.plugin);
                }
            }

            var rs_settings = new Settings ("org.altlinux.ReadySet");
            string[] passed_plugins = rs_settings.get_strv ("performed-steps");

            foreach (var step_addin in steps_addins_arr) {
                passed_plugins += step_addin.plugin_info.module_name;
            }

            rs_settings.set_strv ("performed-steps", passed_plugins);
        }

        app.quit ();
    }
}
