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
        typeof (WiFiAdapterRow).ensure ();
        typeof (AccessPointRow).ensure ();
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

        return vars;
    }

    public async override ReadySet.BasePage[] build_pages () {
        return { new Network.Page () };
    }

    public async override void init_once () {
        if (context.sandbox) {
            return;
        }

        foreach (var device in client.devices) {
            if (device.state != UNMANAGED && device.state != UNAVAILABLE) {
                switch (device.device_type) {
                case MODEM:
                    modems.append (device);
                    break;
                case ETHERNET:
                    ethers.append (device);
                    break;
                case WIFI:
                    wlans.append (device);
                    break;
                default:
                    break;
                }
            }
        }
    }

    public async override void apply (ReadySet.ProgressData progress_data) throws ReadySet.ApplyError {

    }
}

public void peas_register_types (TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type (typeof (ReadySet.StepAddin), typeof (Network.Addin));
}
