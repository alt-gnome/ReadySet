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

    unowned NM.DeviceWifi device;
    unowned NM.AccessPoint point;

    NM.ActiveConnection? listener = null;
    public string? status { get; private set; default = null; }

    NM.Utils.SecurityType[] security;
    public bool needs_secrets { get; private set; default = false; }

    public AccessPointRow (
            NM.DeviceWifi wlan,
            NM.AccessPoint ap,
            Bytes? hidden_ssid = null
    ) {
        device = wlan;
        point = ap;

        Bytes ssid = (ap.ssid != null && ap.ssid.length > 0)
                ? ap.ssid
                : (!) hidden_ssid;
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

        security = get_available_ap_security (device, ap);
        if (security.length == 0) {
            activatable = false;
            subtitle = _("Can't connect: undetermined security type");
        } else {
            needs_secrets = security[0] != OWE && security[0] != NONE;
        }

        if (ap == device.active_access_point) {
            activatable = false;
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

        NM.RemoteConnection? conn = null;

        foreach (var known in addin.client.connections) {
            if (same_ssid (point.ssid, known.get_setting_wireless ()?.ssid)
                    && device.interface == known.get_interface_name ()) {
                conn = known;
                break;
            }
        }

        bool need_new = conn == null;
        if (need_new) {
            try {
                NM.Connection tmp = prepare_wireless_connection (device, point);
                apply_security (tmp, security[0]);
                conn = yield addin.client.add_connection_async (
                    tmp, false, null
                );
            } catch (Error e) {
                status = _("Connection setup failed");
                warning (e.message);
                return;
            }
        }

        try {
            yield addin.client.activate_connection_async (
                conn, device, null, null
            );
        } catch (Error e) {
            status = _("Connection failed");
            warning (e.message);

            if (need_new) {
                try {
                    yield conn.delete_async (null);
                } catch (Error e) {
                    error (e.message);
                }
            }
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
            status = null;
            return;
        }

        switch (listener.state) {
        case ACTIVATING:
            status = _("Connecting…");
            break;
        case ACTIVATED:
            if (device.ip4_connectivity == FULL
                    && device.ip6_connectivity == FULL) {
                status = _("Connected");
            } else {
                status = _("Connected without internet");
            }
            break;
        case DEACTIVATING:
            status = _("Disconnecting…");
            break;
        default:
            status = null;
            break;
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
        WS_WEP_KEY,
        WS_DYNAMIC_WEP,
        WS_LEAP,
        WS_OWE;
    }

    [GtkChild]
    unowned Gtk.Stack stack;

    unowned NM.Connection connection;

    public ApSecurityEditor (NM.Connection conn, NM.Utils.SecurityType[] sec) {
        connection = conn;
        heading = connection.get_id ();

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
            case STATIC_WEP:
                mask |= WS_WEP_KEY;
                break;
            case DYNAMIC_WEP:
                mask |= WS_DYNAMIC_WEP;
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
            var page = new NMA.WsWpaEap (connection, true, false, null);
            page.ws_changed.connect (validate);
            stack.add_titled (page, null, _("WPA/WPA2/WPA3 Enterprise"));
        }
        if (WS_SAE in mask) {
            var page = new NMA.WsSae (connection, false);
            page.ws_changed.connect (validate);
            stack.add_titled (page, null, _("WPA3 Personal"));
        }
        if (WS_WPA_PSK in mask) {
            var page = new NMA.WsWpaPsk (connection, false);
            page.ws_changed.connect (validate);
            stack.add_titled (page, null, _("WPA/WPA2 Personal"));
        }
        if (WS_WEP_KEY in mask) {
            var page1 = new NMA.WsWepKey (connection, KEY, false, false);
            page1.ws_changed.connect (validate);
            stack.add_titled (page1, null, _("WEP 40/104-bit Key (Hex/ASCII)"));

            var page2 = new NMA.WsWepKey (connection, PASSPHRASE, false, false);
            page2.ws_changed.connect (validate);
            stack.add_titled (page2, null, _("WEP 128-bit Passphrase"));
        }
        if (WS_DYNAMIC_WEP in mask) {
            var page = new NMA.WsDynamicWep (connection, true, false);
            page.ws_changed.connect (validate);
            stack.add_titled (page, null, _("Dynamic WEP (802.1x)"));
        }
        if (WS_LEAP in mask) {
            var page = new NMA.WsLeap (connection, false);
            page.ws_changed.connect (validate);
            stack.add_titled (page, null, _("LEAP"));
        }
        if (WS_OWE in mask) {
            var page = new NMA.WsOwe (connection);
            page.ws_changed.connect (validate);
            stack.add_titled (page, null, _("Enhanced Open"));
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
