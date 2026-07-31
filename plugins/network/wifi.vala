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
    }
}

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Network/ui/wifi-adapter-row.ui")]
public sealed class Network.WiFiAdapterRow : Adw.ExpanderRow {

    unowned NM.DeviceWifi device;

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

        refresh_ap_list ();
        Timeout.add_seconds_full (0, 15, refresh_ap_list);
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
