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

[GtkTemplate (ui = "/org/altlinux/ReadySet/ui/installer-stage-row.ui")]
public sealed class ReadySet.InstallerStageRow : Gtk.ListBoxRow {

    [GtkChild]
    unowned Gtk.Label name_label;
    [GtkChild]
    unowned Gtk.Label state_label;

    public InstallerStage stage { get; construct; }

    public InstallerStageRow (InstallerStage stage) {
        Object (stage: stage);
    }

    construct {
        stage.bind_property ("name", name_label, "label", GLib.BindingFlags.SYNC_CREATE);
        stage.bind_property ("state", state_label, "label", GLib.BindingFlags.SYNC_CREATE, state_transfotm);
    }

    bool state_transfotm (Binding binding, Value value_from, ref Value value_to) {
        var state = (InstallerStageState) value_from.get_enum ();
        switch (state) {
            case PASSED:
                remove_css_class ("accent");
                add_css_class ("dimmed");
                value_to.set_string ("<b>%s</b>".printf (_("Finished")));
                break;
            case NOT_PASSED:
                value_to.set_string ("<b>%s</b>".printf (_("Waiting")));
                break;
            case CURRENT:
                add_css_class ("accent");
                value_to.set_string ("<b>%s</b>".printf (_("Processing…")));
                break;
        }

        return true;
    }
}
