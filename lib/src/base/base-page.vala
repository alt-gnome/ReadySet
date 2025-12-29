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
public class ReadySet.BasePage : Gtk.Box {

    [GtkChild]
    unowned Adw.Bin title_bin;
    [GtkChild]
    unowned Adw.Bin child_bin;
    [GtkChild]
    unowned Gtk.Stack loading_stack;
    [GtkChild]
    unowned Adw.Bin top_bin;
    [GtkChild]
    unowned Adw.Bin bottom_bin;
    [GtkChild]
    unowned Gtk.ScrolledWindow scrolled_window;

    bool icon_widget_set = false;

    public Gtk.Widget? icon_widget {
        get {
            if (icon_widget_set) {
                return icon_widget;
            } else {
                return null;
            }
        }
        set {
            if (value == null) {
                return;
            }

            loading_stack.remove (loading_stack.get_child_by_name ("default"));
            loading_stack.add_named (value, "default");
            loading_stack.visible_child_name = "default";
            icon_widget_set = true;
        }
    }

    public Gtk.Widget top_widget {
        get {
            return top_bin.child;
        }
        set {
            top_bin.child = value;
        }
    }

    public Gtk.Widget bottom_widget {
        get {
            return bottom_bin.child;
        }
        set {
            bottom_bin.child = value;
        }
    }

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

    public bool scroll_on_top { get; private set; default = true; }

    Adw.PropertyAnimationTarget scroll_anim_target;
    Adw.TimedAnimation scroll_animation;

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

    construct {
        scrolled_window.vadjustment.notify["value"].connect (update_scroll_on_top);
        scroll_anim_target = new Adw.PropertyAnimationTarget (scrolled_window.vadjustment, "value");
    }

    void update_scroll_on_top () {
        scroll_on_top = scrolled_window.vadjustment.value <= 360.0;
    }

    public virtual bool allowed () {
        return true;
    }

    public virtual async void apply () throws ApplyError {
        return;
    }

    public void start_loading () {
        loading_stack.visible_child_name = "loading";
    }

    public void stop_loading () {
        loading_stack.visible_child_name = "default";
    }

    public void to_up () {
        scrolled_window.set_kinetic_scrolling (false);

        if (scroll_animation != null) {
            scroll_animation.reset ();
        }

        scroll_animation = new Adw.TimedAnimation (scrolled_window, scrolled_window.vadjustment.value, 0.0, 100, scroll_anim_target);

        scroll_animation.play ();
        scrolled_window.set_kinetic_scrolling (true);
    }
}
