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

public class ReadySetSoftware.Addin : Tuner.Addin {

    construct {
        load_css ();

        var sources_dir = Path.build_filename (
            Config.READYSET_DATADIR,
            "software",
            "sources.d"
        );

        if (Software.get_sources (sources_dir).size > 0) {
            add_page (new Page ());
        }
    }

    public void load_css () {
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/org/altlinux/ReadySetSoftware/TunerPlugin/style.css");
        Gtk.StyleContext.add_provider_for_display (
            Gdk.Display.get_default (),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }
}

public void peas_register_types (TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type (typeof (Tuner.Addin), typeof (ReadySetSoftware.Addin));
}
