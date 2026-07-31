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
    unowned Bytes ssid;
    NM.ActiveConnection? listener = null;

    public string? status { get; private set; default = null; }
    public bool is_active { get; private set; default = false; }

    NM.Utils.SecurityType security;
    public bool needs_secrets { get; private set; default = false; }

    public AccessPointRow (NM.DeviceWifi wlan, NM.AccessPoint ap) {
        device = wlan;
        ssid = ap.ssid;

        title = NM.Utils.ssid_to_utf8 (ssid?.get_data ());

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
        needs_secrets = security != INVALID
            && security != NONE
            && security != OWE;

        if (ap == device.active_access_point) {
            is_active = true;
            device.notify["active-connection"].connect (listen_to_active);
            listen_to_active ();
        }
    }

    [GtkCallback]
    async void on_activated () {
        var addin = Addin.get_instance ();

        if (addin.context.sandbox) {
            if (needs_secrets) {
                var dialog = new AccessPointPasswordDialog (
                    device, ssid, security
                );
                dialog.present (root);
            }
            return;
        }

        NM.RemoteConnection? conn = null;

        foreach (var known in addin.client.connections) {
            if (same_ssid (ssid, known.get_setting_wireless ()?.ssid)) {
                conn = known;
                break;
            }
        }

        if (conn == null) {
            try {
                conn = yield addin.client.add_connection_async (
                    new_wireless_connection (ssid, security),
                    false,
                    null
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

            try {
                yield conn.delete_async (null);
            } catch (Error e) {
                error (e.message);
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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Network/ui/access-point-password-dialog.ui")]
public sealed class Network.AccessPointPasswordDialog : Adw.AlertDialog {

    unowned NM.DeviceWifi device;
    unowned Bytes ssid;
    NM.Utils.SecurityType security;

    string _username = "";
    public string username {
        get {
            return _username;
        }
        set {
            _username = value;
            set_response_enabled ("apply",
                validate_wifi_secrets (security, _password, _username)
            );
        }
    }
    public bool needs_username { get; private set; default = false; }

    string _password = "";
    public string password {
        get {
            return _password;
        }
        set {
            _password = value;
            set_response_enabled ("apply",
                validate_wifi_secrets (security, _password, _username)
            );
        }
    }

    public AccessPointPasswordDialog (
            NM.DeviceWifi wlan,
            Bytes ssid,
            NM.Utils.SecurityType sec
    ) {
        device = wlan;
        this.ssid = ssid;
        security = sec;

        heading = NM.Utils.ssid_to_utf8 (ssid?.get_data ());

        needs_username = sec == WPA3_SUITE_B_192
                || sec == WPA2_ENTERPRISE || sec == WPA_ENTERPRISE
                || sec == DYNAMIC_WEP || sec == LEAP;
    }

    [GtkCallback]
    void username_entered () {
        focus (TAB_FORWARD);
    }
}

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Network/ui/wifi-adapter-row.ui")]
public sealed class Network.WiFiAdapterRow : Adw.ExpanderRow {

    unowned NM.DeviceWifi device;
    TimeoutCaller ap_scanner = new TimeoutCaller ();

    ListStore all_aps = new ListStore (typeof (NM.AccessPoint));
    Gtk.SortListModel sorted_aps;
    Gtk.FilterListModel unique_aps;
    AccessPointFilter unique_filter = new AccessPointFilter ();

    ListStore rows = new ListStore (typeof (AccessPointRow));

    public WiFiAdapterRow (NM.DeviceWifi wlan) {
        device = wlan;

        title = device.get_description ();

        sorted_aps = new Gtk.SortListModel (all_aps,
            new AccessPointSorter (device)
        );
        unique_aps = new Gtk.FilterListModel (sorted_aps, unique_filter);
        unique_aps.items_changed.connect (update_rows);

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
                    enable_expansion = true;
                    subtitle = null;
                    remove_css_class ("error");
                } catch (Error e) {
                    ans = false;
                    expanded = false;
                    enable_expansion = false;
                    subtitle = _("Failed to scan access points");
                    add_css_class ("error");
                }
            }
        );

        if (ans) {
            unique_filter.reset ();
            all_aps.splice (0, all_aps.n_items, device.access_points.data);

            device.access_point_added.connect (append_ap);
            device.access_point_removed.connect (remove_ap);
        }
        return ans;
    }

    void refresh_and_schedule () {
        ap_scanner.start (Priority.DEFAULT_IDLE, 15, refresh_ap_list);
    }

    void update_rows (uint pos, uint removed, uint added) {
        var new_rows = new AccessPointRow[added];
        uint idx;

        for (idx = 0; idx < added; ++idx) {
            new_rows[idx] = new AccessPointRow (device,
                (NM.AccessPoint) unique_aps.get_item (pos + idx)
            );
        }

        for (idx = pos; idx < rows.n_items; ++idx) {
            remove ((AccessPointRow) rows.get_item (idx));
        }

        rows.splice (pos, removed, new_rows);

        for (idx = pos; idx < rows.n_items; ++idx) {
            add_row ((AccessPointRow) rows.get_item (idx));
        }
    }
}
