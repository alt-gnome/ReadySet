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
    ListStore conn_list;

    public EthernetAdapterWindow (NM.DeviceEthernet eth) {
        var addin = Addin.get_instance ();

        device = eth;
        eth.add_weak_pointer (&device);

        conn_list = new ListStore (typeof (NM.Connection));
        conn_list.splice (0, 0, device.available_connections.data);
        addin.client.connection_added.connect (connection_added);
        addin.client.connection_removed.connect (connection_removed);

        title = device.get_description ();
        connections.bind_model (conn_list,
            (conn) => { return new EthernetRow ((NM.Connection) conn); }
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

    bool device_transition = false;
    bool internal_toggle;

    public EthernetRow (NM.Connection eth) {
        var addin = Addin.get_instance ();

        conn = eth;
        eth.add_weak_pointer (&conn);
        active = get_active_connection (conn);
        update_active_device ();
        internal_toggle = true;
        toggler.active = active != null;
        internal_toggle = false;

        conn.changed.connect (update_title);
        update_title ();
        settings.sensitive = !Addin.get_instance ().context.sandbox;

        addin.client.active_connection_added.connect (check_for_activated);
        addin.client.active_connection_removed.connect (check_for_deactivated);

        toggler.bind_property ("visible",
            this, "activatable-widget",
            SYNC_CREATE,
            set_primary_action
        );
        addin.context.bind_context_to_property ("network.simple",
            settings, "visible",
            SYNC_CREATE | INVERT_BOOLEAN
        );
    }

    void check_for_activated (NM.ActiveConnection new_active) {
        if (new_active.uuid == conn.get_uuid ()) {
            if (device != null) {
                device_transition = true;
            }

            active = new_active;
            update_active_device ();
            internal_toggle = true;
            toggler.active = true;
            internal_toggle = false;
            toggler.visible = true;
        }
    }

    void check_for_deactivated (NM.ActiveConnection old_active) {
        if (old_active.uuid == conn.get_uuid ()) {
            if (device_transition) {
                device_transition = false;
                return;
            }

            if (device != null) {
                device.state_changed.connect (track_link_cooldown);
            }

            active = null;
            update_active_device ();
            internal_toggle = true;
            toggler.active = false;
            internal_toggle = false;
            toggler.visible = true;
        }
    }

    void update_active_device () {
        if (device != null) {
            device.remove_weak_pointer (&device);
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
            device.add_weak_pointer (&device);
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
                && (device.ip4_connectivity == FULL
                    || device.ip6_connectivity == FULL)) {
            icon.icon_name = "lan-symbolic";
        } else {
            icon.icon_name = "offline-lan-symbolic";
        }
    }

    bool set_primary_action (Binding bind, Value visible, ref Value widget) {
        if (visible.get_boolean ()) {
            widget.set_object (toggler);
        } else if (settings.visible) {
            widget.set_object (settings);
        } else {
            activatable = false;
        }
        return true;
    }

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

    [GtkCallback]
    async void toggle_connection () {
        if (internal_toggle || Addin.get_instance ().context.sandbox) {
            return;
        }

        NM.Client nmc = Addin.get_instance ().client;
        try {
            if (toggler.active) {
                yield nmc.activate_connection_async (conn, null, null, null);
            } else {
                yield device.disconnect_async (null);
            }
        } catch (Error e) {
            warning (e.message);
            internal_toggle = true;
            toggler.active = !toggler.active;
            internal_toggle = false;
            toggler.visible = false;
        }
    }

    [GtkCallback]
    void edit_connection () {
        NM.Client nmc = Addin.get_instance ().client;
        var dialog = new Net.ConnectionEditor (conn, device, null, nmc) {
            transient_for = root as Gtk.Window,
        };
        dialog.present ();
        toggler.visible = true;
    }
}
