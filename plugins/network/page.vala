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
    [GtkChild]
    unowned ModeledStack wifi_adapters;

    string _hostname = Environment.get_host_name ();
    public string hostname {
        get {
            return _hostname;
        }
        set {
            _hostname = value;
            update_is_ready ();
        }
    }

    public bool good_hostname { get; private set; }

    public string? hostname_error { get; private set; default = null; }

    construct {
        var addin = Addin.get_instance ();

        addin.context.bind_property_to_context (this, "hostname",
            "network.hostname",
            SYNC_CREATE
        );

#if 0
        addin.modems.bind_property ("n-items",
            simcard_group, "visible",
            SYNC_CREATE,
            set_visibility
        );
#else
        simcard_group.visible = false;
#endif

        ethernet_group.bind_model (addin.ethers,
            (ether) => {
                return new EthernetAdapterRow ((NM.DeviceEthernet) ether);
            }
        );
        addin.ethers.bind_property ("n-items",
            ethernet_group, "visible",
            SYNC_CREATE,
            set_visibility
        );

        wifi_adapters.bind_model (addin.wlans,
            (wlan) => { return new WiFiAdapterBox ((NM.DeviceWifi) wlan); },
            null,
            (wlan) => { return ((NM.DeviceWifi) wlan).get_description (); }
        );
        addin.wlans.bind_property ("n-items",
            wifi_group, "visible",
            SYNC_CREATE,
            set_visibility
        );

        NetworkMonitor.get_default ().notify["network-available"].connect (update_is_ready);
        update_is_ready ();
    }

    void update_is_ready () {
        string? error;
        good_hostname = validate_hostname (_hostname, out error);
        hostname_error = error;

        is_ready = good_hostname && validate_network ();

        if (good_hostname) {
            hostname_entry.remove_css_class ("error");
        } else {
            hostname_entry.add_css_class ("error");
        }
    }

    bool set_visibility (Binding bind, Value n_items, ref Value visible) {
        visible.set_boolean (n_items.get_uint () > 0);
        return true;
    }
}
