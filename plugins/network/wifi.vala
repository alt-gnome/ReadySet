/*
 * Copyright (C) 2026 Valery Zabrovsky <brow@altlinux.org>
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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Network/ui/access-point-row.ui")]
public sealed class Network.AccessPointRow : Adw.ActionRow {

    [GtkChild]
    unowned Gtk.Image icon;
    [GtkChild]
    unowned Gtk.Button settings;

    unowned NM.DeviceWifi device;
    unowned NM.AccessPoint point;
    NM.Connection connection = null;
    NM.ActiveConnection? listener = null;

    NM.Utils.SecurityType[] security;
    public bool needs_secrets { get; private set; default = false; }

    public AccessPointRow (
            NM.DeviceWifi wlan,
            NM.AccessPoint ap,
            Bytes? hidden_ssid = null
    ) {
        var addin = Addin.get_instance ();

        device = wlan;
        device.add_weak_pointer (&device);
        point = ap;
        point.add_weak_pointer (&point);
        destroy.connect (() => {
            device?.remove_weak_pointer (&device);
            point?.remove_weak_pointer (&point);
        });

        Bytes ssid = NM.Utils.is_empty_ssid (ap.ssid?.get_data ())
                ? (!) hidden_ssid
                : ap.ssid;
        title = NM.Utils.ssid_to_utf8 (ssid.get_data ());

        if (ap.strength >= 60) {
            icon.icon_name = "radiowaves-1-symbolic";
        } else if (ap.strength >= 40) {
            icon.icon_name = "radiowaves-2-symbolic";
        } else if (ap.strength >= 20) {
            icon.icon_name = "radiowaves-3-symbolic";
        } else {
            icon.icon_name = "radiowaves-4-symbolic";
        }

        settings.sensitive = !addin.context.sandbox;

        security = get_available_ap_security (device, ap);
        if (security.length == 0) {
            activatable = false;
            subtitle = _("Can't connect: undetermined security type");
        } else {
            needs_secrets = security[0] != OWE && security[0] != NONE;
        }

        addin.client.connection_added.connect (connection_added);
        addin.client.connection_removed.connect (connection_removed);
        foreach (var known in addin.client.connections) {
            if (connection != null) {
                break;
            }
            connection_added (known);
        }

        if (ap == device.active_access_point) {
            if (addin.context.sandbox) {
                activatable = false;
            }
            device.notify["active-connection"].connect (listen_to_active);
            listen_to_active ();
        }
    }

    [GtkCallback]
    async void on_activated () {
        var addin = Addin.get_instance ();

        if (addin.context.sandbox) {
            if (needs_secrets) {
                var dialog = new ApSecurityEditor (
                    prepare_wireless_connection (device, point),
                    security
                );
                dialog.present (root);
            }
            return;
        }

        if (point == device.active_access_point) {
            settings.activate ();
            return;
        }

        if (connection == null) {
            connection = prepare_wireless_connection (device, point);
            apply_security (connection, security[0]);

            switch (security[0]) {
            case WPA3_SUITE_B_192:
            case WPA2_ENTERPRISE:
            case WPA_ENTERPRISE:
                if (addin.context.get_boolean ("network.simple")) {
                    var editor = new ApSecurityEditor (connection, security);
                    if ((yield editor.choose (get_native (), null)) != "apply"
                            || !(yield add_connection ())) {
                        return;
                    }
                } else {
                    var editor = create_editor ();
                    editor.done.connect (on_editor_closed);
                    editor.set_title (title);
                    editor.present ();
                    return;
                }
                break;
            default:
                if (!(yield add_connection ())) {
                    return;
                }
                break;
            }
        }

        yield activate_connection ();
    }

    async void on_editor_closed (Net.ConnectionEditor editor, bool res) {
        if (res) {
            yield activate_connection ();
        }
        editor.done.disconnect (on_editor_closed);
    }

    async bool add_connection () {
        try {
            return (yield Addin.get_instance ().client.add_connection_async (
                connection, false, null
            )) != null;
        } catch (Error e) {
            subtitle = _("Connection setup failed");
            warning (e.message);
            return false;
        }
    }

    async void activate_connection () {
        try {
            yield Addin.get_instance ().client.activate_connection_async (
                connection, device, null, null
            );
        } catch (Error e) {
            subtitle = _("Connection failed");
            warning (e.message);
        }
    }

    void listen_to_active () {
        if (listener != null) {
            listener.state_changed.disconnect (update_status);
            device.notify["ip4-connectivity"].disconnect (update_status);
            device.notify["ip6-connectivity"].disconnect (update_status);
        }
        listener = device.active_connection;
        if (listener != null) {
            listener.state_changed.connect (update_status);
            device.notify["ip4-connectivity"].connect (update_status);
            device.notify["ip6-connectivity"].connect (update_status);
        }
        update_status ();
    }

    void update_status () {
        if (listener == null) {
            subtitle = null;
            return;
        }

        switch (listener.state) {
        case ACTIVATING:
            subtitle = _("Connecting…");
            break;
        case ACTIVATED:
            if (device.ip4_connectivity == FULL
                    || device.ip6_connectivity == FULL) {
                subtitle = _("Connected");
            } else {
                subtitle = _("Connected without internet");
            }
            break;
        case DEACTIVATING:
            subtitle = _("Disconnecting…");
            break;
        default:
            subtitle = null;
            break;
        }
    }

    void connection_added (NM.RemoteConnection conn) {
        if (same_ssid (point.ssid, conn.get_setting_wireless ()?.ssid)
                && device.connection_valid (conn)) {
            connection = conn;
            settings.visible = true;
        }
    }

    void connection_removed (NM.RemoteConnection conn) {
        if (connection?.get_uuid () == conn.get_uuid ()) {
            connection = null;
            settings.visible = false;
        }
    }

    Net.ConnectionEditor create_editor () {
        return new Net.ConnectionEditor (
            connection, device, point, Addin.get_instance ().client
        ) {
            transient_for = get_native () as Gtk.Window,
        };
    }

    [GtkCallback]
    void edit_connection () {
        if (Addin.get_instance ().context.get_boolean ("network.simple")) {
            new ApSecurityEditor (connection, security).present (get_native ());
        } else {
            create_editor ().present ();
        }
    }
}

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Network/ui/ap-security-editor.ui")]
public sealed class Network.ApSecurityEditor : Adw.AlertDialog {

    [Flags]
    enum AvailableWs {
        WS_WPA_EAP,
        WS_SAE,
        WS_WPA_PSK,
        WS_LEAP,
        WS_OWE;
    }

    [GtkChild]
    unowned Gtk.Stack stack;

    unowned NM.Connection connection;

    public ApSecurityEditor (NM.Connection conn, NM.Utils.SecurityType[] sec) {
        connection = conn;
        connection.add_weak_pointer (&connection);
        destroy.connect (() => {
            connection?.remove_weak_pointer (&connection);
        });
        heading = connection.get_id ();

        var with_secrets = NM.SimpleConnection.new_clone (connection);
        var ws = connection.get_setting_wireless_security ();
        var remote = connection as NM.RemoteConnection;
        if (remote != null) {
            var setting_name = ws?.key_mgmt == "wpa-eap"
                    ? NM.Setting8021x.SETTING_NAME
                    : NM.SettingWirelessSecurity.SETTING_NAME;

            try {
                with_secrets.update_secrets (setting_name,
                    remote.get_secrets (setting_name)
                );
            } catch (Error e) {
                warning (e.message);
                with_secrets = connection;
            }
        }

        AvailableWs mask = 0;
        foreach (var type in sec) {
            switch (type) {
            // TODO: Suite B needs its own Ws; waiting for libnma impl.
            case WPA3_SUITE_B_192:
            case WPA2_ENTERPRISE:
            case WPA_ENTERPRISE:
                mask |= WS_WPA_EAP;
                break;
            case SAE:
                mask |= WS_SAE;
                break;
            case WPA2_PSK:
            case WPA_PSK:
                mask |= WS_WPA_PSK;
                break;
            case LEAP:
                mask |= WS_LEAP;
                break;
            case OWE:
                mask |= WS_OWE;
                break;
            default:
                break;
            }
        }

        if (WS_WPA_EAP in mask) {
            var page = new NMA.WsWpaEap (with_secrets, true, false, null);
            page.ws_changed.connect (validate);
            stack.add_titled (page, "wpa-eap", _("WPA/WPA2/WPA3 Enterprise"));
        }
        if (WS_SAE in mask) {
            var page = new NMA.WsSae (with_secrets, false);
            page.ws_changed.connect (validate);
            stack.add_titled (page, "sae", _("WPA3 Personal"));
        }
        if (WS_WPA_PSK in mask) {
            var page = new NMA.WsWpaPsk (with_secrets, false);
            page.ws_changed.connect (validate);
            stack.add_titled (page, "wpa-psk", _("WPA/WPA2 Personal"));
        }
        if (WS_LEAP in mask) {
            var page = new NMA.WsLeap (with_secrets, false);
            page.ws_changed.connect (validate);
            stack.add_titled (page, "leap", _("LEAP"));
        }
        if (WS_OWE in mask) {
            var page = new NMA.WsOwe (with_secrets);
            page.ws_changed.connect (validate);
            stack.add_titled (page, "owe", _("Enhanced Open"));
        }

        switch (ws?.key_mgmt) {
        case "wpa-eap":
            stack.visible_child_name = "wpa-eap";
            break;
        case "sae":
            stack.visible_child_name = "sae";
            break;
        case "wpa-psk":
            stack.visible_child_name = "wpa-psk";
            break;
        case "ieee8021x":
            if (ws?.auth_alg == "leap") {
                stack.visible_child_name = "leap";
            }
            break;
        case "owe":
            stack.visible_child_name = "owe";
            break;
        }

        stack.notify["visible-child"].connect_after (validate_current);
        validate_current ();
    }

    [GtkCallback]
    void on_response (string resp) {
        switch (resp) {
        case "apply":
            ((NMA.Ws) stack.visible_child).fill_connection (connection);
            break;
        default:
            break;
        }
    }

    void validate (NMA.Ws page) {
        bool valid;

        try {
            valid = page.validate ();
        } catch (Error e) {
            valid = false;
        }

        set_response_enabled ("apply", valid);
    }

    void validate_current () {
        validate ((NMA.Ws) stack.visible_child);
    }
}

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Network/ui/wifi-adapter-box.ui")]
public sealed class Network.WiFiAdapterBox : Adw.Bin {

    [GtkChild]
    unowned Gtk.ListBox box;

    unowned NM.DeviceWifi device;
    TimeoutCaller ap_scanner = new TimeoutCaller ();

    ListStore all_aps = new ListStore (typeof (NM.AccessPoint));
    AccessPointFilter unique_filter = new AccessPointFilter ();

    public WiFiAdapterBox (NM.DeviceWifi wlan) {
        device = wlan;
        device.add_weak_pointer (&device);
        destroy.connect (() => {
            device?.remove_weak_pointer (&device);
        });

        box.bind_model (
            new Gtk.FilterListModel (
                new Gtk.SortListModel (all_aps, new AccessPointSorter (device)),
                unique_filter
            ),
            (ap) => { return new AccessPointRow (device, (NM.AccessPoint) ap); }
        );

        realize.connect (() => {
            device.access_point_added.connect (append_ap);
            device.access_point_removed.connect (remove_ap);
            refresh_and_schedule ();
        });
        unrealize.connect (() => {
            ap_scanner.stop ();
            device.access_point_added.disconnect (append_ap);
            device.access_point_removed.disconnect (remove_ap);
        });
        device.notify["active-access-point"].connect (refresh_and_schedule);
    }

    void append_ap (NM.DeviceWifi device, Object ap) {
        all_aps.append (ap);
    }

    void remove_ap (NM.DeviceWifi device, Object ap) {
        uint pos;
        if (all_aps.find (ap, out pos)) {
            all_aps.remove (pos);
        }
    }

    bool refresh_ap_list () {
        device.access_point_added.disconnect (append_ap);
        device.access_point_removed.disconnect (remove_ap);

        bool ans = true;
        device.request_scan_async.begin (null,
            (obj, res) => {
                try {
                    ans = device.request_scan_async.end (res);
                } catch (Error e) {
                    ans = false;
                }
            }
        );

        unique_filter.reset ();
        if (ans) {
            all_aps.splice (0, all_aps.n_items, device.access_points.data);

            device.access_point_added.connect (append_ap);
            device.access_point_removed.connect (remove_ap);
        } else {
            all_aps.remove_all ();
        }
        return ans;
    }

    void refresh_and_schedule () {
        ap_scanner.start (Priority.DEFAULT_IDLE, 15, refresh_ap_list);
    }
}
