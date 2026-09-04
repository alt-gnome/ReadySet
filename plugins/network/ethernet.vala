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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Network/ui/ethernet-adapter-row.ui")]
public sealed class Network.EthernetAdapterRow : Adw.ActionRow {

    [GtkChild]
    unowned Gtk.Image icon;

    unowned NM.DeviceEthernet device;
    EthernetAdapterWindow dialog = null;

    public EthernetAdapterRow (NM.DeviceEthernet eth) {
        device = eth;
        eth.add_weak_pointer (&device);

        title = device.get_description ();
        Addin.get_instance ().context.bind_context_to_property (
            "network.simple",
            this, "activatable",
            SYNC_CREATE | INVERT_BOOLEAN
        );

        device.notify["ip4-connectivity"].connect (update_icon);
        device.notify["ip6-connectivity"].connect (update_icon);
        update_icon ();
    }

    void update_icon () {
        if (device.ip4_connectivity == FULL
                || device.ip6_connectivity == FULL) {
            icon.icon_name = "lan-symbolic";
        } else {
            icon.icon_name = "offline-lan-symbolic";
        }
    }

    [GtkCallback]
    void on_activated () {
        if (dialog == null) {
            dialog = new EthernetAdapterWindow (device) {
                transient_for = root as Gtk.Window,
            };
        }
        dialog.present ();
    }

    ~EthernetAdapterRow () {
        dialog?.destroy ();
    }
}

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Network/ui/ethernet-adapter-window.ui")]
public sealed class Network.EthernetAdapterWindow : Adw.Window {

    [GtkChild]
    unowned Adw.PreferencesGroup connections;

    unowned NM.DeviceEthernet device;
    ListStore conn_list = new ListStore (typeof (NM.Connection));

    public EthernetAdapterWindow (NM.DeviceEthernet eth) {
        NM.Client nmc = Addin.get_instance ().client;

        device = eth;
        eth.add_weak_pointer (&device);

        nmc.connection_added.connect (connection_added);
        nmc.connection_removed.connect (connection_removed);
        foreach (var conn in nmc.connections) {
            connection_added (conn);
        }

        title = device.get_description ();
        connections.bind_model (conn_list,
            (conn) => { return new EthernetConnectionRow (
                (NM.Connection) conn, device
            ); }
        );
    }

    void connection_added (NM.RemoteConnection conn) {
        if (device.connection_valid (conn)) {
            conn_list.append (conn);
        }
    }

    void connection_removed (NM.RemoteConnection conn) {
        uint pos;
        if (conn_list.find_with_equal_func (conn, same_connections, out pos)) {
            conn_list.remove (pos);
        }
    }

    [GtkCallback]
    async void add_connection () {
        var addin = Addin.get_instance ();
        NM.Connection conn = prepare_wired_connection (device);

        if (addin.context.sandbox) {
            conn_list.append (conn);
            return;
        }

        try {
            yield addin.client.add_connection_async (conn, false, null);
        } catch (Error e) {
            warning (e.message);
        }
    }
}

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Network/ui/ethernet-connection-row.ui")]
public sealed class Network.EthernetConnectionRow : Adw.ActionRow {

    [GtkChild]
    unowned Gtk.Button settings;

    unowned NM.Connection connection;
    unowned NM.DeviceEthernet device;

    public EthernetConnectionRow (NM.Connection conn, NM.DeviceEthernet eth) {
        var addin = Addin.get_instance ();

        connection = conn;
        conn.add_weak_pointer (&connection);
        device = eth;
        eth.add_weak_pointer (&device);

        conn.changed.connect (update_title);
        update_title ();
        activatable = !addin.context.sandbox;
        settings.sensitive = activatable;
    }

    void update_title () {
        title = connection.get_id ();
    }

#if 0
    void track_link_cooldown (NM.Device eth, uint to, uint from, uint reason) {
        var to_state = (NM.DeviceState) to;
        var from_state = (NM.DeviceState) from;
        if ((NM.DeviceStateReason) reason == CARRIER) {
            if (from_state == DISCONNECTED && to_state == UNAVAILABLE) {
                // the cooldown begins
                toggler.sensitive = false;
                toggler.tooltip_text = _(
                    "Please wait until devices reloading is over…"
                );
            } else if (from_state == UNAVAILABLE && to_state == DISCONNECTED) {
                // the cooldown is over
                eth.state_changed.disconnect (track_link_cooldown);
                toggler.sensitive = true;
                toggler.tooltip_text = null;
            }
        } else {
            eth.state_changed.disconnect (track_link_cooldown);
        }
    }
#endif

    [GtkCallback]
    async void activate_connection () {
        try {
            yield Addin.get_instance ().client.activate_connection_async (
                connection, device, null, null
            );
        } catch (Error e) {
            warning (e.message);
        }
    }

    [GtkCallback]
    void edit_connection () {
        var editor = new Net.ConnectionEditor (
            connection, device, null, Addin.get_instance ().client
        ) {
            transient_for = get_native () as Gtk.Window,
        };
        editor.present ();
    }
}
