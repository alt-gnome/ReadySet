/* Copyright (C) 2024-2025 Vladimir Romanov <rirusha@altlinux.org>
 * Copyright (C) 2026 Valery Zabrovsky <brow@altlinux.org>
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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Network/ui/page.ui")]
public sealed class Network.Page : ReadySet.BasePage {

    [GtkChild]
    unowned Adw.EntryRow hostname_entry;
    [GtkChild]
    unowned Adw.PreferencesGroup simcard_group;
    [GtkChild]
    unowned Adw.PreferencesGroup ethernet_group;
    [GtkChild]
    unowned Adw.PreferencesGroup wifi_group;

    string _hostname = Environment.get_host_name ();
    public string hostname {
        get {
            return _hostname;
        }
        set {
            string? error;

            _hostname = value;
            is_ready = validate_hostname (_hostname, out error);
            hostname_error = error;

            if (is_ready) {
                hostname_entry.remove_css_class ("error");
            } else {
                hostname_entry.add_css_class ("error");
            }
        }
    }

    public string? hostname_error { get; private set; default = null; }

    construct {
        var addin = Addin.get_instance ();

        simcard_group.visible = addin.modems.n_items > 0;
        ethernet_group.visible = addin.ethers.n_items > 0;
        wifi_group.visible = addin.wlans.n_items > 0;
    }
}
