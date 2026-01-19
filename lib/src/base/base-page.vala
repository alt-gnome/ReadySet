/* Copyright (C) 2024-2025 Vladimir Romanov <rirusha@altlinux.org>
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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Lib/ui/base-page.ui")]
public class ReadySet.BasePage : BaseBarePage {

    [GtkChild]
    unowned Adw.Bin title_bin;
    [GtkChild]
    unowned Adw.Bin child_bin;
    [GtkChild]
    unowned Gtk.Box nbox;

    bool icon_widget_set = false;

    public Gtk.Widget? icon_widget {
        get {
            if (icon_widget_set) {
                return nbox.get_first_child ();
            } else {
                return null;
            }
        }
        set {
            if (value == null) {
                return;
            }

            nbox.remove (nbox.get_first_child ());
            nbox.prepend (value);
            icon_widget_set = true;
        }
    }

    public string title { get; set; default = _("Unknown page"); }

    public string description { get; set; default = _("This page says that your distribution has made a mistake."); }

    public Gtk.Widget title_widget {
        get {
            return title_bin.child;
        }
        set {
            title_bin.child = value;
        }
    }

    bool content_widget_set = false;

    public new Gtk.Widget? content {
        get {
            if (content_widget_set) {
                return nbox.get_last_child ();
            }

            return null;
        }
        set {
            if (content_widget_set) {
                nbox.remove (nbox.get_last_child ());
            }

            nbox.append (value);
            content_widget_set = true;
        }
    }

    static construct {
        set_css_name ("basepage");
    }

    construct {
        base.content = nbox;
    }
}
