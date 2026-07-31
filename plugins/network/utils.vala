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
