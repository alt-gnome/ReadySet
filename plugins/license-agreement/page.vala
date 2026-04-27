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
    public string license_file_path { get; set; }
    public string license_text { get; set; default = ""; }

    public Page () {
        Object (
            need_go_up_button: false
        );
    }

    construct {
        Addin.get_instance ().context.bind_context_to_property (
            "license-agreement-file-path",
            this,
            "license-agreement-file-path",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE
        );
        read_license_file ();
    }

    [GtkCallback]
    void read_license_file () {
        if (license_file_path == null || license_file_path == "") {
            license_text = "";
            accessible = false;
            return;
        }

        var variants = get_language_variants (get_current_language ());

        var found = false;
        File? file = null;
        foreach (var variant in variants) {
            var path = license_file_path.replace ("LANG", variant);

            file = File.new_for_path (path);

            if (file.query_exists ()) {
                found = true;
                break;
            }
        }

        if (!found || file == null) {
            license_text = "";
            accessible = false;
            return;
        }

        string text;

        try {
            uint8[] data;
            file.load_contents (null, out data, null);
            text = ((string) data);
        } catch (Error error) {
            license_text = "";
            accessible = false;
            return;
        }

        license_text = html_to_pango (text);
        accessible = true;
    }
}
