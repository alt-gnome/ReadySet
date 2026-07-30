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

public sealed class Software.SourcesData : Serialize.DataObject {

    public Serialize.Array<Group> groups { get; set; default = new Serialize.Array<Group> (); }

    public Serialize.Array<Source> sources { get; set; default = new Serialize.Array<Source> (); }
}

[SingleInstance]
public sealed class Software.Sources : Object {

    public int size {
        get {
            return real_sources.size;
        }
    }

    Gee.HashMap<string, Group> real_groups = new Gee.HashMap<string, Group> ();

    Gee.ArrayList<Source> real_sources = new Gee.ArrayList<Source> ();

    Gee.HashMap<string, Gee.ArrayList<Source>> group_sources_map = new Gee.HashMap<string, Gee.ArrayList<Source>> ();

    public Sources (SourcesData sourced_data) {
        var seen_source_ids = new Gee.HashSet<string> ();
        foreach (var s in sourced_data.sources) {
            if (!s.good_type ()) {
                continue;
            }

            if (seen_source_ids.contains (s.id)) {
                warning ("Software source id duplication: %s", s.id);
                continue;
            }
            seen_source_ids.add (s.id);
            real_sources.add (s);
        }

        foreach (var g in sourced_data.groups) {
            if (real_groups.has_key (g.id)) {
                warning ("Software group id duplication: %s", g.id);
                continue;
            }
            real_groups[g.id] = g;
        }

        foreach (var s in real_sources) {
            if (s.group == null) {
                continue;
            }

            Gee.ArrayList<Source>? list;
            if (!group_sources_map.has_key (s.group)) {
                list = new Gee.ArrayList<Source> ();
                group_sources_map[s.group] = list;
            } else {
                list = group_sources_map[s.group];
            }

            list.add (s);
        }
    }

    public new Source @get (int index) {
        return real_sources[index];
    }

    public string[] get_groups_ids () {
        var groups = real_groups.values;
        var iter_sort = groups.order_by ((el1, el2) => {
            if (el1.priority < el2.priority) {
                return 1;
            } else if (el1.priority > el2.priority) {
                return -1;
            } else {
                return 0;
            }
        });
        var iter_cut = iter_sort.map<string> ((el) => el.id);
        var arr = new Gee.ArrayList<string> ();
        arr.add_all_iterator (iter_cut);

        return arr.to_array ();
    }

    public Group? get_group (string id) {
        if (real_groups.has_key (id)) {
            return real_groups[id];
        }
        return null;
    }

    public void get_group_sources (string? id, out Source[] sources, out Group? group) {
        group = id != null ? get_group (id) : null;

        var result = new Gee.ArrayList<Source> ();

        if (id == null) {
            foreach (var s in real_sources) {
                if (s.group == null) {
                    result.add (s);
                    continue;
                }

                if (!real_groups.has_key (s.group)) {
                    result.add (s);
                    continue;
                }

                var source_group = real_groups[s.group];
                if (!source_group.required && group_sources_map[s.group].size < 2) {
                    result.add (s);
                }
            }
        } else if (group != null && group_sources_map.has_key (id)) {
            var list = group_sources_map[id];
            if (list.size >= 2 || group.required) {
                result.add_all (list);
            }
        }

        sources = result.to_array ();
    }
}
