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

[CCode (cheader_filename = "phoc-device-state-unstable-v1-client-protocol.h", lower_case_cprefix = "zphoc_device_state_v1_")]
namespace PhocDeviceState {

    [CCode (cname = "struct zphoc_device_state_v1", free_function = "zphoc_device_state_v1_destroy", has_type_id = false)]
    [Compact]
    public class DeviceStateV1 {
        [CCode (cname = "zphoc_device_state_v1_add_listener")]
        public int add_listener (DeviceStateV1Listener listener, void* data);
    }

    [CCode (cname = "enum zphoc_device_state_v1_capability", cprefix = "ZPHOC_DEVICE_STATE_V1_CAPABILITY_", has_type_id = false)]
    [Flags]
    public enum Capability {
        TABLET_MODE_SWITCH,
        LID_SWITCH,
        KEYBOARD
    }

    [CCode (has_target = false, has_typedef = false)]
    public delegate void DeviceStateV1ListenerCapabilities (void* data, DeviceStateV1 device_state, uint32 capabilities);

    [CCode (cname = "struct zphoc_device_state_v1_listener", has_type_id = false)]
    public struct DeviceStateV1Listener {
        public DeviceStateV1ListenerCapabilities capabilities;
    }

    [CCode (cname = "zphoc_device_state_v1_interface")]
    public extern Wl.Interface interface;
}
