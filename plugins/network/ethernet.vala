/* Copyright (C) 2026 Valery Zabrovsky <brow@altlinux.org>
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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Network/ui/ethernet-row.ui")]
public sealed class Network.EthernetRow : Adw.ActionRow {

    [GtkChild]
    unowned Gtk.Image icon;
    [GtkChild]
    unowned Gtk.Switch toggler;
    [GtkChild]
    unowned Gtk.Button settings;

    unowned NM.Connection conn;
    NM.ActiveConnection? active;
    unowned NM.DeviceEthernet? device = null;

    public EthernetRow (NM.Connection eth) {
        NM.Client nmc = Addin.get_instance ().client;

        conn = eth;
        active = get_active_connection (conn);
        update_active_device ();
        toggler.active = active != null;

        conn.changed.connect (update_title);
        update_title ();
        settings.sensitive = !Addin.get_instance ().context.sandbox;

        nmc.active_connection_added.connect (check_for_activated);
        nmc.active_connection_removed.connect (check_for_deactivated);
    }

    void check_for_activated (NM.ActiveConnection new_active) {
        if (new_active.uuid == conn.get_uuid ()) {
            active = new_active;
            update_active_device ();
            toggler.active = true;
        }
    }

    void check_for_deactivated (NM.ActiveConnection old_active) {
        if (old_active.uuid == conn.get_uuid ()) {
            active = null;
            update_active_device ();
            toggler.active = false;
        }
    }

    void update_active_device () {
        if (device != null) {
            device.notify["ip4-connectivity"].disconnect (update_icon);
            device.notify["ip6-connectivity"].disconnect (update_icon);
        }

        device = null;
        if (active != null) {
            foreach (var possible in active.devices) {
                if (possible.device_type == ETHERNET) {
                    device = (NM.DeviceEthernet) possible;
                    break;
                }
            }
        }

        if (device != null) {
            device.notify["ip4-connectivity"].connect (update_icon);
            device.notify["ip6-connectivity"].connect (update_icon);
        }
        update_icon ();
    }

    void update_title () {
        title = conn.get_id ();
    }

    void update_icon () {
        if (device != null
                && device.ip4_connectivity == FULL
                && device.ip6_connectivity == FULL) {
            icon.icon_name = "lan-symbolic";
        } else {
            icon.icon_name = "offline-lan-symbolic";
        }
    }

    [GtkCallback]
    void edit_connection () {
        NM.Client nmc = Addin.get_instance ().client;
        var dialog = new Net.ConnectionEditor (conn, device, null, nmc) {
            transient_for = root as Gtk.Window,
        };
        dialog.present ();
    }
}
