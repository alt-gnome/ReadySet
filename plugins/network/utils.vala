/*
 * Copyright (C) 2025 Vladimir Romanov <rirusha@altlinux.org>
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

namespace Network {

    bool same_devices (Object obj1, Object obj2) {
        var dev1 = (NM.Device) obj1;
        var dev2 = (NM.Device) obj2;
        return dev1.interface == dev2.interface;
    }

    bool validate_network () {
        if (Addin.get_instance ().context.get_boolean ("network.required")) {
            return NetworkMonitor.get_default ().network_available;
        }

        return true;
    }

    bool validate_hostname (string hostname, out string? error) {
        if (hostname.has_prefix ("-")) {
            error = _("Leading hyphen is not allowed");
            return false;
        }

        unichar cur;
        int idx = 0;

        while (hostname.get_next_char (ref idx, out cur)) {
            if ((cur >= 0x80 || !cur.isalnum ()) && cur != '-') {
                error = _("Only Latin letters, digits and hyphens are allowed");
                return false;
            }
        }

        if (idx < 4) {
            error = _("Host name is too short");
            return false;
        }

        if (hostname[idx - 1] == '-') {
            error = _("Trailing hyphen is not allowed");
            return false;
        }

        error = null;
        return true;
    }

    bool same_ssid (Bytes? ssid1, Bytes? ssid2) {
        return ssid1 != null && ssid1.length > 0
            && ssid2 != null && ssid2.length > 0
            && NM.Utils.same_ssid (ssid1.get_data (), ssid2.get_data (), true);
    }

    NM.Utils.SecurityType[] get_available_ap_security (
            NM.DeviceWifi device,
            NM.AccessPoint ap
    ) {
        NM.Utils.SecurityType[] types = {
            WPA3_SUITE_B_192,   // aka WPA3-Enterprise
            SAE,                // aka WPA3-Personal
            WPA2_ENTERPRISE,
            WPA2_PSK,
            WPA_ENTERPRISE,
            WPA_PSK,
            STATIC_WEP,
            DYNAMIC_WEP,
            LEAP,
            OWE,
            NONE,
        };
        NM.Utils.SecurityType[] res = {};

        foreach (var type in types) {
            if (NM.Utils.security_valid (
                    type,
                    device.wireless_capabilities,
                    true,
                    ap.mode == ADHOC,
                    ap.flags,
                    ap.wpa_flags,
                    ap.rsn_flags
            )) {
                res += type;
            }
        }

        return res;
    }

    NM.Connection prepare_wired_connection (NM.DeviceEthernet eth) {
        NM.Connection conn = NM.SimpleConnection.new ();
        conn.add_setting (new NM.SettingWired () {
            auto_negotiate = true,
        });
        conn.add_setting (new NM.SettingIP4Config () {
            method = "auto",
        });
        conn.add_setting (new NM.SettingIP6Config () {
            method = "auto",
        });

        NM.Client nmc = Addin.get_instance ().client;
        string conn_id = _("Wired connection %u");
        uint idx = 1;
        foreach (var known in nmc.connections) {
            if (known.get_id () == conn_id.printf (idx)) {
                ++idx;
            }
        }

        conn.add_setting (new NM.SettingConnection () {
            uuid = NM.Utils.uuid_generate (),
            id = conn_id.printf (idx),
            interface_name = eth.interface,
            type = "802-3-ethernet",
            autoconnect = true,
        });

        return conn;
    }

    NM.Connection prepare_wireless_connection (
            NM.DeviceWifi wlan,
            NM.AccessPoint ap,
            Bytes? hidden_ssid = null
    ) {
        NM.Connection conn = NM.SimpleConnection.new ();
        Bytes ssid = (ap.ssid != null && ap.ssid.length > 0)
                ? ap.ssid
                : (!) hidden_ssid;

        conn.add_setting (new NM.SettingConnection () {
            uuid = NM.Utils.uuid_generate (),
            id = NM.Utils.ssid_to_utf8 (ssid.get_data ()),
            interface_name = wlan.interface,
            type = "802-11-wireless",
            autoconnect = true,
        });
        conn.add_setting (new NM.SettingIP4Config () {
            method = "auto",
        });
        conn.add_setting (new NM.SettingIP6Config () {
            method = "auto",
        });

        var setting_w = new NM.SettingWireless () {
            ssid = ssid,
        };
        switch (ap.mode) {
        case INFRA:
            setting_w.mode = "infrastructure";
            break;
        case ADHOC:
            setting_w.mode = "adhoc";
            break;
        case MESH:
            setting_w.mode = "mesh";
            break;
        case AP:
            setting_w.mode = "ap";
            break;
        default:
            break;
        }
        conn.add_setting (setting_w);

        return conn;
    }

    void apply_security (NM.Connection conn, NM.Utils.SecurityType sec) {
        switch (sec) {
        case WPA3_SUITE_B_192:
            conn.add_setting (new NM.SettingWirelessSecurity () {
                key_mgmt = "wpa-eap-suite-b-192",
                pmf = NM.SettingWirelessSecurityPmf.REQUIRED,
            });
            break;
        case SAE:
            conn.add_setting (new NM.SettingWirelessSecurity () {
                key_mgmt = "sae",
                pmf = NM.SettingWirelessSecurityPmf.REQUIRED,
            });
            break;
        case WPA2_ENTERPRISE:
            conn.add_setting (new NM.SettingWirelessSecurity () {
                key_mgmt = "wpa-eap",
                pmf = NM.SettingWirelessSecurityPmf.OPTIONAL,
            });
            break;
        case WPA2_PSK:
            conn.add_setting (new NM.SettingWirelessSecurity () {
                key_mgmt = "wpa-psk",
                pmf = NM.SettingWirelessSecurityPmf.OPTIONAL,
            });
            break;
        case WPA_ENTERPRISE:
            conn.add_setting (new NM.SettingWirelessSecurity () {
                key_mgmt = "wpa-eap",
            });
            break;
        case WPA_PSK:
            conn.add_setting (new NM.SettingWirelessSecurity () {
                key_mgmt = "wpa-psk",
            });
            break;
        case STATIC_WEP:
            conn.add_setting (new NM.SettingWirelessSecurity () {
                key_mgmt = "none",
            });
            break;
        case DYNAMIC_WEP:
            conn.add_setting (new NM.SettingWirelessSecurity () {
                key_mgmt = "ieee8021x",
            });
            break;
        case LEAP:
            conn.add_setting (new NM.SettingWirelessSecurity () {
                key_mgmt = "ieee8021x",
                auth_alg = "leap",
            });
            break;
        case OWE:
            conn.add_setting (new NM.SettingWirelessSecurity () {
                key_mgmt = "owe",
                pmf = NM.SettingWirelessSecurityPmf.REQUIRED,
            });
            break;
        default:
            conn.remove_setting (typeof (NM.SettingWirelessSecurity));
            break;
        }
    }
}

public sealed class Network.AccessPointSorter : Gtk.Sorter {

    unowned NM.DeviceWifi device;

    public AccessPointSorter (NM.DeviceWifi wlan) {
        device = wlan;
    }

    public override Gtk.Ordering compare (Object? obj1, Object? obj2) {
        if (obj1 == null) {
            return obj2 == null ? Gtk.Ordering.EQUAL : Gtk.Ordering.LARGER;
        }
        if (obj2 == null) {
            return Gtk.Ordering.SMALLER;
        }

        var ap1 = (NM.AccessPoint) obj1;
        var ap2 = (NM.AccessPoint) obj2;
        if (ap1 == device.active_access_point) {
            return Gtk.Ordering.SMALLER;
        }
        if (ap2 == device.active_access_point) {
            return Gtk.Ordering.LARGER;
        }
        return Gtk.Ordering.from_cmpfunc (ap2.strength - ap1.strength);
    }

    public override Gtk.SorterOrder get_order () {
        return Gtk.SorterOrder.TOTAL;
    }
}

public sealed class Network.AccessPointFilter : Gtk.Filter {

    Gee.HashSet<Bytes> ssids = new Gee.HashSet<Bytes> (hash, same_ssid);

    static uint hash (Bytes ssid) {
        return ssid.hash ();
    }

    public override bool match (Object? obj) {
        if (obj == null) {
            return false;
        }

        var ap = (NM.AccessPoint) obj;
        if (ap.ssid == null || ap.ssid.length <= 0) {
            return false;
        }

        return ssids.add (ap.ssid);
    }

    public void reset () {
        ssids.clear ();
    }
}

public sealed class Network.TimeoutCaller {

    TimeoutSource? source = null;

    public void start (int priority, uint interval, owned SourceFunc func) {
        stop ();
        if (func ()) {
            source = new TimeoutSource.seconds (interval);
            source.set_priority (priority);
            source.set_callback ((owned) func);
            source.attach ();
        }
    }

    public void stop () {
        source?.destroy ();
        source = null;
    }
}
