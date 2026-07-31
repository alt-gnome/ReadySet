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

    bool validate_wifi_secrets (
            NM.Utils.SecurityType sec,
            string? password = null,
            string? username = null
    ) {
        switch (sec) {
        case NONE:
        case OWE:
            return true;
        case STATIC_WEP:
            return password != null && NM.Utils.wep_key_valid (password, KEY);
        case WPA_PSK:
        case WPA2_PSK:
        case SAE:
            return password != null && NM.Utils.wpa_psk_valid (password);
        case LEAP:
        case DYNAMIC_WEP:
        case WPA_ENTERPRISE:
        case WPA2_ENTERPRISE:
        case WPA3_SUITE_B_192:
            return username != null && username.length > 0
                && password != null && password.length > 0;
        default:
            return false;
        }
    }

    NM.Utils.SecurityType get_available_ap_security (
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
                return type;
            }
        }

        return INVALID;
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

    static bool same_ssid (Bytes ssid1, Bytes ssid2) {
        return NM.Utils.same_ssid (ssid1.get_data (), ssid2.get_data (), true);
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
