/* Copyright 2024-2025 Vladimir Vaskov <rirusha@altlinux.org>
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
public class ReadySet.BasePage : Gtk.Box {

    [GtkChild]
    unowned Adw.Bin title_bin;
    [GtkChild]
    unowned Adw.Bin child_bin;
    [GtkChild]
    unowned Gtk.Stack loading_stack;
    [GtkChild]
    unowned Gtk.ScrolledWindow scrolled_window;

    public bool show_banner { get; set; default = false; }

    public string banner_message { get; set; default = ""; }

    public string icon_name { get; set; default = "dialog-error-symbolic"; }

    public string title_header { get; set; default = _("Unknown"); }

    public string title { get; set; default = _("Unknown page"); }

    public string description { get; set; default = _("This page says that your distribution has made a mistake."); }

    public string start_apply_message { get; set; default = _("Applying changes…"); }

    public bool passed { get; set; default = false; }

    public bool is_ready { get; set; default = false; }

    public Gtk.Widget title_widget {
        get {
            return title_bin.child;
        }
        set {
            title_bin.child = value;
        }
    }

    protected Gtk.ScrolledWindow root_scrolled_window {
        get {
            return scrolled_window;
        }
    }

    public Gtk.Widget content {
        get {
            return child_bin.child;
        }
        set {
            child_bin.child = value;
        }
    }

    static construct {
        set_css_name ("basepage");
    }

    public virtual bool allowed () {
        return true;
    }

    public virtual async void apply () throws ApplyError {
        warning ("Empty 'apply' detected");
        return;
    }

    public void start_loading () {
        loading_stack.visible_child_name = "loading";
    }

    public void stop_loading () {
        loading_stack.visible_child_name = "default";
    }
}
