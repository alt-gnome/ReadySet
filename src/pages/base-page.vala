/* Copyright 2024 rirusha
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

[GtkTemplate (ui = "/space/rirusha/ReadySet/ui/base-page.ui")]
public abstract class ReadySet.BasePage : Adw.NavigationPage {

    [GtkChild]
    unowned Adw.ToolbarView toolbar_view;

    public static Adw.NavigationView root_view { get; set; }

    public Gtk.Widget content {
        get {
            return toolbar_view.content;
        }
        set {
            toolbar_view.content = value;
        }
    }

    public bool is_ready { get; set; default = false; }

    public bool search_is_possible { get; set; default = false; }

    public bool search_enabled { get; set; default = false; }

    public signal void apply ();

    [GtkCallback]
    void apply_clicked () {
        apply ();
    }
}