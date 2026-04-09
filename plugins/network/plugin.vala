/*
 * Copyright (C) 2025-2026 Vladimir Romanov <rirusha@altlinux.org>
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

    bool _accessible;
    public override bool accessible {
        get {
            return _accessible;
        }
        protected set {
            _accessible = value;
        }
    }

    protected override string? resource_base_path {
        get {
            return "/org/altlinux/ReadySet/Plugin/Network/";
        }
    }

    static construct {

    }

    public override HashTable<string, ReadySet.ContextVarInfo> get_context_vars () {
        var vars = base.get_context_vars ();

        return vars;
    }

    public async override ReadySet.BaseBarePage[] build_pages () {
        return { new Network.Page () };
    }

    public async override void init_once () {
        if (!context.sandbox) {
            try {
                var client = new NM.Client (null);
                var devices = client.get_devices ();
                bool has_connectable_device = false;

                foreach (var device in devices) {
                    var device_type = device.get_device_type ();

                    if (device_type == NM.DeviceType.ETHERNET ||
                        device_type == NM.DeviceType.WIFI ||
                        device_type == NM.DeviceType.MODEM) {

                        var state = device.get_state ();

                        if (state != NM.DeviceState.UNMANAGED &&
                            state != NM.DeviceState.UNAVAILABLE) {
                            has_connectable_device = true;
                        }
                    }
                }

                accessible = has_connectable_device;

            } catch (Error e) {
                error (e.message);
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
