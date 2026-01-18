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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Language/ui/page.ui")]
public sealed class Language.Page : ReadySet.BasePage {

    static double saved_scroll_position = 0.0;

    construct {
        root_scrolled_window.vadjustment.value_changed.connect (() => {
            saved_scroll_position = root_scrolled_window.vadjustment.value;
        });

        Idle.add_once (() => {
            root_scrolled_window.vadjustment.value = saved_scroll_position;
        });
    }

    public override bool allowed () {
        try {
            return new Polkit.Permission.sync ("org.freedesktop.locale1.set-locale", null, null).allowed;
        } catch (Error e) {
            error (e.message);
        }
    }

    public override async void apply () throws ReadySet.ApplyError {
        try {
            var proxy = yield get_locale_proxy ();

            yield proxy.set_locale ({ @"LANG=$(Addin.get_instance ().current_locale)" }, true);
        } catch (Error e) {
            throw ReadySet.ApplyError.build_error (_("Error when setting language"), e.message);
        }
    }
}
