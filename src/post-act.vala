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

public sealed class ReadySet.PostAct : Object {

    Peas.Engine engine;
    Peas.ExtensionSet addins;

    public Context context { get; construct; }

    public PostAct (Context context) {
        Object (context: context);
    }

    Peas.Engine get_engine () {
        if (engine == null) {
            engine = new Peas.Engine ();
            engine.enable_loader ("python");

            engine.add_search_path (
                Config.POST_ACT_PLUGINS_DIR,
                null
            );
        }

        return engine;
    }

    // return true if window should stay open
    public async PostActStatusFlags run () {
        PostActStatusFlags res = 0;

        var engine = get_engine ();
        addins = new Peas.ExtensionSet.with_properties (
            engine,
            typeof (ReadySet.PostActAddin),
            {}, {}
        );

        for (int i = 0; i < engine.get_n_items (); i++) {
            var info = (Peas.PluginInfo) engine.get_item (i);
            engine.load_plugin (info);
            debug ("%s loaded", info.module_name);
            var plugin = (ReadySet.PostActAddin) addins.get_extension (info);

            try {
                res = res | (yield plugin.run (context));
            } catch (Error e) {
                warning (e.message);
            }
        }

        return res;
    }
}
