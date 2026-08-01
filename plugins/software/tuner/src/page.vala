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

public sealed class ReadySetSoftware.Page : Tuner.Page {

    construct {
        title = _("Third-party Repositories");
        id = "ready-set-software";
        icon_name = "gis-software-symbolic";

        var sources_dir = Path.build_filename (
            Config.READYSET_DATADIR,
            "software",
            "sources.d"
        );
        var sources = Software.get_sources (sources_dir);

        var groups = sources.get_groups_ids ();
        groups += null;
        foreach (var gid in groups) {
            Software.Source[] group_sources;
            Software.Group? group;
            sources.get_group_sources (gid, out group_sources, out group);

            if (group_sources.length == 0) {
                continue;
            }

            var pref_group = new Tuner.Group ();
            if (group != null) {
                if (group.name != null) {
                    pref_group.title = dgettext (group.gettext_domain, group.name);
                }
                if (group.description != null) {
                    pref_group.description = dgettext (group.gettext_domain, group.description);
                }
            } else {
                if (groups.length == 1) {
                    pref_group.title = _("Software sources");
                } else {
                    pref_group.title = _("Other software sources");
                }
            }

            foreach (var s in group_sources) {
                var binding = new SourceBinding (s);
                var sw = new Tuner.Switch () {
                    title = dgettext (s.gettext_domain, s.name),
                    subtitle = dgettext (s.gettext_domain, s.description),
                    binding = binding
                };

                binding.dialog_parent = sw.native_widget;
                pref_group.add (sw);
            }

            add_group (pref_group);
        }
    }
}
