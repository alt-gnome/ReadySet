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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Software/ui/page.ui")]
public sealed class Software.Page : ReadySet.BasePage {

    string description_full = _("Third-party repositories provide access to additional software from selected external sources, including popular apps and drivers that are important for some devices. Some proprietary software may be included.");  // vala-lint=line-length

    string info_description_short = _("Manage third-party repositories.");

    [GtkChild]
    unowned Gtk.Box sources_box;
    [GtkChild]
    unowned Gtk.Button enable_button;
    [GtkChild]
    unowned ReadySet.StatusPage info_description;
    [GtkChild]
    unowned Gtk.Label content_description;

    public bool single_button { get; construct; }

    public Page (bool single_button) {
        Object (single_button: single_button);
    }

    construct {
        content_description.label = description_full;

        sources_box.visible = !single_button;

        var sources = get_sources ();

        var enabled = new Gee.ArrayList<string>.wrap (
            Addin.get_instance ().context.get_strv ("software.enabled-sources")
        );

        var groups = sources.get_groups_ids ();
        groups += null;
        foreach (var gid in groups) {

            Source[] group_sources;
            Group group;
            sources.get_group_sources (gid, out group_sources, out group);

            if (group_sources.length != 0) {
                if (group != null) {
                    if (group.required && group_sources.length == 1) {
                        //  User has no choice, so we enabling single source at
                        //  required group
                        switch_source (group_sources[0].id, true);
                        continue;
                    }
                }

                var pref_group = new Adw.PreferencesGroup ();

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

                bool initial_active = false;
                if (group != null) {
                    if (group.required) {
                        initial_active = true;
                    }
                }
                SourceRow latest_row;
                foreach (var s in group_sources) {
                    var row = new SourceRow (s, single_button) {
                        active = initial_active || s.id in enabled
                    };
                    if (latest_row != null) {
                        if (group != null) {
                            if (group.required) {
                                row.group = latest_row;
                            }
                        }
                    }
                    pref_group.add (row);
                    latest_row = row;
                    initial_active = false;
                }

                sources_box.append (pref_group);
            }
        }

        if (single_button) {
            update_button ();
        }

        notify["layout-mode"].connect (layout_mode_changed);
        layout_mode_changed ();
    }

    void layout_mode_changed () {
        var wide = layout_mode == HORIZONTAL || layout_mode == BIG;
        content_description.visible = wide;
        info_description.description = wide ? info_description_short : description_full;
    }

    [GtkCallback]
    void on_enable_button_clicked () {
        var enabled = Addin.get_instance ().context.get_strv ("software.enabled-sources");
        var sources = get_sources ();

        if (enabled.length == sources.size) {
            Addin.get_instance ().context.set_strv ("software.enabled-sources", {});
        } else {
            if (sources.get_groups_ids ().length > 0) {
                warning ("Groups doesn't supported in `single-button` mode, groups will be ignored");
            }

            Source[] group_sources;
            sources.get_group_sources (null, out group_sources, null);

            string[] all = {};
            foreach (var s in group_sources) {
                all += s.id;
            }
            Addin.get_instance ().context.set_strv ("software.enabled-sources", all);
        }

        update_button ();
    }

    void update_button () {
        var enabled = Addin.get_instance ().context.get_strv ("software.enabled-sources");
        if (enabled.length == get_sources ().size) {
            enable_button.label = _("Disable Third-Party repositories");
            enable_button.remove_css_class ("suggested-action");
        } else {
            enable_button.label = _("Enable Third-Party repositories");
            enable_button.add_css_class ("suggested-action");
        }
    }
}
