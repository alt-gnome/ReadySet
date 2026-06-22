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

public sealed class Keyboard.InputSourcesManager : Object {

    public const string INPUT_SOURCE_TYPE_XKB = "xkb";
    public const string INPUT_SOURCE_TYPE_IBUS = "ibus";

    public const string[] MAIN_SOURCES = { "ara", "cn", "gb", "us", "fr", "de", "jp", "ru", "es" };

    Gnome.XkbInfo xkb_info;

#if HAVE_IBUS
    IBus.Bus ibus;
    Gee.HashMap<string, IBus.EngineDesc> ibus_engines;
    Cancellable ibus_cancellable;
#endif

    Serialize.Array<SteviaLayoutData>? stevia_layouts = null;

    public ListStore sources_model { get; default = new ListStore (typeof (InputInfo)); }

    public signal void changed ();

    construct {
        xkb_info = get_xkb_info ();

#if HAVE_IBUS
        IBus.init ();

        if (ibus != null) {
            ibus = new IBus.Bus.async ();

            if (ibus.is_connected ()) {
                fetch_ibus_engines ();
            } else {
                ibus.connected.connect (fetch_ibus_engines);
            }

            maybe_start_ibus ();
        }
#endif

        try {
            string content;
            FileUtils.get_contents ("/usr/share/phosh-osk-stevia/layouts.json", out content);

            stevia_layouts = Serialize.JsonWorker.simple_array_from_json<SteviaLayoutData> (
                content,
                { "layouts" },
                new Serialize.Settings () {
                    names_case = Serialize.Case.KEBAB
                }
            );
        } catch (Error e) {}
    }

    public async void init () {
        sources_model.remove_all ();

        if (!(yield get_stevia_infos ())) {
            yield get_locale_infos ();
#if HAVE_IBUS
            yield get_ibus_locale_infos ();
#endif
        }
    }

    public string? get_humanity_name (InputInfo input_info) {
        if (input_info.type_ == INPUT_SOURCE_TYPE_XKB) {
            string display_name;
            xkb_info.get_layout_info (input_info.id, out display_name, null, null, null);
            return display_name;
#if HAVE_IBUS
        } else if (input_info.type_ == INPUT_SOURCE_TYPE_IBUS) {
            if (ibus_engines != null) {
                if (ibus_engines.has_key (input_info.id)) {
                    return ibus_engines[input_info.id].get_longname ();
                }
            }

            if (stevia_layouts != null) {
                foreach (var layout in stevia_layouts) {
                    if (layout.layout_id == input_info.id) {
                        return layout.name;
                    }
                }
            }

            return input_info.id;
#endif
        }

        return null;
    }

    async bool get_stevia_infos () {
        if (stevia_layouts == null) {
            return false;
        }

        foreach (var mid in MAIN_SOURCES) {
            foreach (var layout in stevia_layouts) {
                if (layout.layout_id == mid && layout.type_ == INPUT_SOURCE_TYPE_XKB) {
                    yield add_source_to_model (INPUT_SOURCE_TYPE_XKB, mid, false);
                    break;
                }
            }
        }

        foreach (var layout in stevia_layouts) {
            yield add_source_to_model (layout.type_, layout.layout_id, true);
        }

        return true;
    }

    async void get_locale_infos () {
        string type = null;
        string id = null;
        string lang = null;
        string country = null;

        var inputs = get_current_inputs ();
        inputs.clear_automatically_added ();

        if (Gnome.Languages.get_input_source_from_locale (get_current_language (), out type, out id)) {
            inputs.add (new InputInfo (type, id) {
                added_automatically = true
            });
            set_current_inputs (inputs);

            yield add_source_to_model (type, id, true);
        }

        if (!Gnome.Languages.parse_locale (get_current_language (), out lang, out country, null, null)) {
            return;
        }

        foreach (var mid in MAIN_SOURCES) {
            yield add_source_to_model (INPUT_SOURCE_TYPE_XKB, mid, false);
        }

        var list = xkb_info.get_layouts_for_language (lang);
        yield add_sources_to_model (list, INPUT_SOURCE_TYPE_XKB, id, true);

        if (country != null) {
            list = xkb_info.get_layouts_for_country (country);
            yield add_sources_to_model (list, INPUT_SOURCE_TYPE_XKB, id, true);
        }

        list = xkb_info.get_all_layouts ();
        yield add_sources_to_model (list, INPUT_SOURCE_TYPE_XKB, id, true);

        changed ();
    }

    public bool get_layout (string type, string id, out string layout, out string variant) {
        layout = "";
        variant = "";

        if (type == "xkb") {
            xkb_info.get_layout_info (id, null, null, out layout, out variant);
            return true;
        }

#if HAVE_IBUS
        if (type == "ibus") {
            IBus.EngineDesc? engine_desc = null;

            if (ibus_engines != null) {
                if (ibus_engines.has_key (id)) {
                    engine_desc = ibus_engines[id];
                }
            }

            if (engine_desc == null) {
                return false;
            }

            layout = engine_desc.get_layout ();
            variant = "";
            return true;
        }
#endif

        return false;
    }

#if HAVE_IBUS
    async void get_ibus_locale_infos () {
        if (ibus_engines == null) {
            return;
        }

        foreach (var entry in ibus_engines) {
           yield add_source_to_model (INPUT_SOURCE_TYPE_IBUS, entry.key, true);
        }
    }

    void fetch_ibus_engines () {
        ibus_cancellable = new Cancellable ();

        ibus.list_engines_async.begin (-1, ibus_cancellable, ibus_engines_callback);

        ibus.connected.disconnect (fetch_ibus_engines);
    }

    void ibus_engines_callback (Object? obj, AsyncResult res) {
        var list = new List<IBus.EngineDesc> ();

        try {
            list = ((IBus.Bus) obj).list_engines_async_finish (res);

        } catch (Error e) {
            warning ("Couldn't finish IBus request: %s", e.message);
            return;
        }

        ibus_cancellable = null;

        ibus_engines = new Gee.HashMap<string, IBus.EngineDesc> ();

        foreach (var engine_desc in list) {
            var engine_id = engine_desc.get_name ();
            if (!engine_id.has_prefix ("xkb:")) {
                ibus_engines[engine_id] = engine_desc;
            }
        }

        get_ibus_locale_infos.begin (on_get_ibus_locale_infos_callback);
    }

    void on_get_ibus_locale_infos_callback () {
        changed ();
    }

    void maybe_start_ibus () {
        /* IBus doesn't export API in the session bus. The only thing
         * we have there is a well known name which we can use as a
         * sure-fire way to activate it.
         */
        Bus.unwatch_name (Bus.watch_name (BusType.SESSION, IBus.SERVICE_IBUS, BusNameWatcherFlags.AUTO_START));
    }
#endif

    async void add_source_to_model (string type, string id, bool is_extra) {
        var tmp = new List<weak string> ();
        tmp.append (id);
        yield add_sources_to_model (tmp, type, null, is_extra);
    }

    async void add_sources_to_model (List<weak string> list, string type, string? default_id, bool is_extra) {
        foreach (var id in list) {
            if (id == default_id) {
                continue;
            }

            var input_info = new InputInfo (type, id) {
                is_extra = is_extra
            };

            if (!sources_model.find_with_equal_func_full (input_info, equal_func, null)) {
                sources_model.append (input_info);
            }

            Idle.add (add_sources_to_model.callback);
            yield;
        }
    }

    bool equal_func (Object el1, Object el2) {
        return InputInfo.equal ((InputInfo) el1, (InputInfo) el2);
    }
}
