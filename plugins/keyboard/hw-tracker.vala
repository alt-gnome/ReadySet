/*
 * Copyright (C) 2024-2026 Vladimir Romanov <rirusha@altlinux.org>
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

public class Keyboard.HwTracker : Object {

    static HwTracker? _instance = null;

    Wl.Display? display = null;
    Wl.Registry? registry = null;
    PhocDeviceState.DeviceStateV1? device_state = null;

    bool has_hw_kb = false;

    public bool has_hw_keyboard {
        get {
            return has_hw_kb;
        }
    }

    public bool allow_active {
        get {
            return !has_hw_kb;
        }
    }

    HwTracker () {
        Object ();
    }

    public static HwTracker get_instance () {
        if (_instance == null) {
            _instance = new HwTracker ();
            _instance.init_wayland ();
        }
        return _instance;
    }

    ~HwTracker () {
        cleanup ();
    }

    void init_wayland () {
        unowned string? display_name = Environment.get_variable ("WAYLAND_DISPLAY");
        if (display_name == null) {
            debug ("WAYLAND_DISPLAY not set, skipping hw keyboard detection");
            return;
        }

        display = new Wl.Display.connect (display_name);
        if (display == null) {
            warning ("Failed to connect to Wayland display");
            return;
        }

        registry = display.get_registry ();
        if (registry == null) {
            warning ("Failed to get Wayland registry");
            return;
        }

        Wl.RegistryListener listener = {
            global: on_registry_global,
            global_remove: on_registry_global_remove
        };

        registry.add_listener (listener, this);
        display.roundtrip ();

        if (device_state != null) {
            PhocDeviceState.DeviceStateV1Listener ds_listener = {
                capabilities: on_device_state_capabilities
            };
            device_state.add_listener (ds_listener, this);
            display.roundtrip ();
        }
    }

    static void on_registry_global (void* data, Wl.Registry reg, uint32 name, string interface, uint32 version) {
        var self = (HwTracker) data;

        if (interface == "zphoc_device_state_v1") {
            self.device_state = reg.bind<PhocDeviceState.DeviceStateV1> (name, ref PhocDeviceState.interface, uint32.min (2, version));
        }
    }

    static void on_registry_global_remove (void* data, Wl.Registry registry, uint32 name) {
    }

    static void on_device_state_capabilities (void* data, PhocDeviceState.DeviceStateV1 device_state, uint32 capabilities) {
        var self = (HwTracker) data;

        debug ("Device state capabilities: 0x%x", capabilities);

        bool has_hw_kb = (capabilities & PhocDeviceState.Capability.KEYBOARD) != 0;

        if (self.has_hw_kb == has_hw_kb) {
            return;
        }

        self.has_hw_kb = has_hw_kb;
        self.notify_property ("allow-active");
    }

    void cleanup () {
        device_state = null;
        registry = null;
        display = null;
    }
}
