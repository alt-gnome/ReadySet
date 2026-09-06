/*
 * Copyright (C) 2026 David Sultaniiazov <x1z53@alt-gnome.ru>
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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/LicenseAgreement/ui/page.ui")]
public sealed class LicenseAgreement.Page : ReadySet.BasePage {

    [GtkChild]
    unowned Gtk.CheckButton check_button;
    [GtkChild]
    unowned ReadySet.StatusPage status_page;

    public string license_agreement_file_path { get; set; }
    public string license_text { get; set; default = ""; }

    public override bool need_go_up_button { get { return false; } }

    construct {
        var raw_text = get_raw_license_text (
            Addin.get_instance ().context.get_string ("license-agreement.file-path"),
            false
        );

        if (raw_text == "" || raw_text == null) {
            license_text = "";
            accessible = false;
            return;
        }

        license_text = html_to_pango (raw_text);
        accessible = true;

        if (Addin.get_instance ().context.mode == EXISTING_USER) {
            var eu = Addin.get_instance ().get_existing_user ();
            if (eu == ReadySet.ExistingUserStatus.YES) {
                status_page.description = _(
                    "We have updated our License Agreement. Please accept the new terms to continue."
                );
            }
        }
    }

    [GtkCallback]
    void on_checkbutton_toggled () {
        Settings la_settings = new Settings ("org.altlinux.ReadySet.license-agreement");

        if (!Addin.get_instance ().context.sandbox) {
            la_settings.set_string (
                "passed-license-hash",
                check_button.active ? Addin.get_instance ().new_hash : Addin.get_instance ().passed_hash
            );
        }
    }
}
