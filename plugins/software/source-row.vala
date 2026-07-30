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

public sealed class Software.SourceRow : Adw.ActionRow {

    public Source source { get; construct; }

    public bool single_button { get; construct; }

    internal Gtk.CheckButton check;

    public bool active {
        get {
            return check.active;
        }
        set {
            check.active = value;
        }
    }

    public SourceRow group {
        set {
            check.group = value.check;
        }
    }

    static bool nonfree_shown = false;

    public SourceRow (Source source, bool single_button = false) {
        Object (source: source, single_button: single_button);
    }

    construct {
        check = new Gtk.CheckButton () {
            valign = Gtk.Align.CENTER,
            can_focus = false,
            css_classes = { "selection-mode" }
        };

        activatable = true;
        activatable_widget = check;

        check.toggled.connect (on_check_toggled);

        update_state (Gtk.AccessibleState.CHECKED, check.active, -1);

        title = dgettext (source.gettext_domain, source.name);
        subtitle = dgettext (source.gettext_domain, source.description);

        if (source.nonfree) {
            add_css_class ("warning");
        }

        add_prefix (check);
        Addin.get_instance ().context.data_changed.connect (data_changed);
    }

    void data_changed (string key) {
        var enabled = new Gee.ArrayList<string>.wrap (
            Addin.get_instance ().context.get_strv ("software.enabled-sources")
        );

        check.active = source.id in enabled;
    }

    void show_nonfree_dialog () {
        if (nonfree_shown) {
            return;
        }

        var dialog = new Adw.AlertDialog (_("Non-Free Repository"), _("This repository contains software with a non-free license. Pay attention to the software license restrictions before usage."));  // vala-lint=line-length

        dialog.add_response ("ok", _("Ok"));
        dialog.set_close_response ("ok");

        dialog.present (this);

        nonfree_shown = true;
    }

    void on_check_toggled () {
        update_state (Gtk.AccessibleState.CHECKED, check.active, -1);

        if (check.active) {
            if (source.nonfree && !single_button) {
                show_nonfree_dialog ();
            }
        }

        switch_source (source.id, check.active);
        notify_property ("active");
    }
}
