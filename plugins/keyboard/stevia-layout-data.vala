/*
 * Copyright (C) 2026 Vladimir Romanov <rirusha@altlinux.org>
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

public sealed class Keyboard.SteviaLayoutData : Deser.DataObject {

    [Description (nick = "type")]
    public string type_ { get; set; }

    public string layout_id { get; set; }

    public string name { get; set; }

    public string language { get; set; }

    public string flavor { get; set; }
}

public sealed class Keyboard.SteviaLayoutsData : Deser.DataObject {
    public GLib.GenericArray<SteviaLayoutData> layouts { get; set; }

    public override Deser.ValueCodec get_property_codec (GLib.ParamSpec property)
        throws Deser.Error {
        if (property.name == "layouts")
            return Deser.create_codec_for_array<SteviaLayoutData> ();
        return base.get_property_codec (property);
    }
}
