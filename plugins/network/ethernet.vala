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

    unowned NM.DeviceEthernet device;

    public EthernetRow (NM.DeviceEthernet eth) {
        device = eth;

        title = device.get_description ();

        device.notify["ip4-connectivity"].connect (update_icon);
        device.notify["ip6-connectivity"].connect (update_icon);
        update_icon ();
    }

    void update_icon () {
        if (device.ip4_connectivity == FULL
                && device.ip6_connectivity == FULL) {
            icon.icon_name = "lan-symbolic";
        } else {
            icon.icon_name = "offline-lan-symbolic";
        }
    }
}
