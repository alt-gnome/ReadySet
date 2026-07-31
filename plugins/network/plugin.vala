/*
 * Copyright (C) 2025-2026 Vladimir Romanov <rirusha@altlinux.org>
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

public class Network.Addin : ReadySet.StepAddin {

    static Addin instance;

    protected override string? resource_base_path {
        get {
            return "/org/altlinux/ReadySet/Plugin/Network/";
        }
    }

    public NM.Client client { get; construct; }

    public ListStore modems { get; construct; }
    public ListStore ethers { get; construct; }
    public ListStore wlans { get; construct; }

    static construct {
        typeof (EthernetRow).ensure ();

        typeof (WiFiAdapterRow).ensure ();
        typeof (AccessPointRow).ensure ();
        typeof (AccessPointPasswordDialog).ensure ();
    }

    construct {
        instance = this;

        try {
            client = new NM.Client ();
        } catch (Error e) {
            critical (e.message);
        }

        modems = new ListStore (typeof (NM.DeviceModem));
        ethers = new ListStore (typeof (NM.DeviceEthernet));
        wlans = new ListStore (typeof (NM.DeviceWifi));
    }

    internal static Addin get_instance () {
        return instance;
    }

    public override HashTable<string, ReadySet.ContextVarInfo> get_context_vars () {
        var vars = base.get_context_vars ();

        vars["hostname"] = new ReadySet.ContextVarInfo (STRING);
        return vars;
    }

    public async override ReadySet.BasePage[] build_pages () {
        return { new Network.Page () };
    }

    public async override void init_once () {
        if (context.sandbox) {
            return;
        }

        client.device_added.connect (add_device);
        client.device_removed.connect (remove_device);

        foreach (var device in client.devices) {
            add_device (device);
        }
    }

    static void update_category (ListStore category, NM.Device device) {
        uint pos;
        bool ok = device.state != UNMANAGED && device.state != UNAVAILABLE;
        if (category.find_with_equal_func (device, same_devices, out pos)) {
            if (!ok) {
                category.remove (pos);
            }
        } else {
            if (ok) {
                category.append (device);
            }
        }
    }

    void update_device (
            NM.Device device,
            uint new_state = device.state,
            uint old_state = device.state,
            uint reason = device.state_reason
    ) {
        switch (device.device_type) {
        case MODEM:
            update_category (modems, device);
            break;
        case ETHERNET:
            update_category (ethers, device);
            break;
        case WIFI:
            update_category (wlans, device);
            break;
        default:
            break;
        }
    }

    void add_device (NM.Device device) {
        switch (device.device_type) {
        case MODEM:
        case ETHERNET:
        case WIFI:
            device.state_changed.connect (update_device);
            update_device (device);
            break;
        default:
            break;
        }
    }

    void remove_device (NM.Device device) {
        switch (device.device_type) {
        case MODEM:
        case ETHERNET:
        case WIFI:
            update_device (device);
            device.state_changed.disconnect (update_device);
            break;
        default:
            break;
        }
    }

    public async override void apply (ReadySet.ProgressData progress_data) throws ReadySet.ApplyError {
        try {
            yield client.save_hostname_async (
                context.get_string ("network.hostname"), null
            );

            foreach (var conn in client.connections) {
                yield conn.save_async (null);
            }
        } catch (Error e) {
            throw ReadySet.ApplyError.build_error (
                _("Failed to apply network settings"), e.message
            );
        }
    }
}

public void peas_register_types (TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type (typeof (ReadySet.StepAddin), typeof (Network.Addin));
}
