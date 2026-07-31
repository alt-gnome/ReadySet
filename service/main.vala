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

Peas.Engine engine;
Peas.ExtensionSet addins;
MainLoop ml;

Peas.Engine get_engine () {
    if (engine == null) {
        engine = new Peas.Engine ();
        engine.enable_loader ("python");

        engine.add_search_path (
            Config.SERVICE_PLUGINS_DIR,
            null
        );
    }

    return engine;
}

void on_bus_aquired (DBusConnection conn, string name) {
    try {
        var service = new ReadySet.Service ();
        conn.register_object ("/org/altlinux/ReadySet", service);

        var engine = get_engine ();
        addins = new Peas.ExtensionSet.with_properties (
            engine,
            typeof (ReadySetService.Addin),
            {}, {}
        );

        for (int i = 0; i < engine.get_n_items (); i++) {
            var info = (Peas.PluginInfo) engine.get_item (i);
            engine.load_plugin (info);
            message ("%s loaded", info.module_name);
            var plugin = (ReadySetService.Addin) addins.get_extension (info);
            plugin.register_service (conn, "/org/altlinux/ReadySet" + plugin.get_object_path ());
        }

    } catch (IOError e) {
        register_fatal (e);
    }
}

void register_fatal (Error e) {
    ml.quit ();
    error ("Could not register service: %s\n", e.message);
}

int main (string[] args) {
    ml = new MainLoop ();

    Bus.own_name (
        BusType.SYSTEM, "org.altlinux.ReadySet",
        BusNameOwnerFlags.NONE,
        on_bus_aquired,
        (con, name) => {
            print ("Name '%s' acquired\n", name);
        },
        (con, name) => {
            print ("Could not acquire name '%s'. Stopping\n", name);
            ml.quit ();
        }
    );

    ml.run ();

    return 0;
}
