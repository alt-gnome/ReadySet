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

[GtkTemplate (ui = "/org/altlinux/ReadySet/ui/steps-main-page.ui")]
public sealed class ReadySet.StepsMainPage : Adw.BreakpointBin {

    [GtkChild]
    unowned PositionedStack positioned_stack;
    [GtkChild]
    unowned PositionedStack info_positioned_stack;
    [GtkChild]
    unowned PagesIndicator pages_indicator;
    [GtkChild]
    unowned Gtk.Label sandbox_label_left;
    [GtkChild]
    unowned Gtk.Label sandbox_label_right;
    [GtkChild]
    unowned Gtk.Button context_button;
    [GtkChild]
    unowned Gtk.Revealer to_up_revealer;
    [GtkChild]
    unowned Gtk.CenterBox button_center_box;
    [GtkChild]
    unowned Gtk.Button osk_button;
    [GtkChild]
    unowned Gtk.Stack main_stack;
    [GtkChild]
    unowned EndPage end_page;

    [GtkChild]
    unowned Gtk.Button to_up_button;
    [GtkChild]
    unowned Gtk.Button go_prev_button;
    [GtkChild]
    unowned Gtk.Button go_next_button;

    [GtkChild]
    unowned Adw.Breakpoint big_breakpoint;
    [GtkChild]
    unowned Adw.Breakpoint small_breakpoint;
    [GtkChild]
    unowned Adw.Breakpoint vertical_breakpoint;
    [GtkChild]
    unowned Adw.Breakpoint horizontal_breakpoint;

    [GtkChild]
    unowned Adw.Bin top_bin;
    [GtkChild]
    unowned Adw.Bin bottom_bin;

    Devel.Window devel_window;

    Gtk.ScrolledWindow _current_scrolled_window;
    protected Gtk.ScrolledWindow current_scrolled_window {
        get {
            return _current_scrolled_window;
        }
        set {
            if (_current_scrolled_window != null) {
                //  Reset value of a previous scroll
                _current_scrolled_window.vadjustment.value = 0;
                _current_scrolled_window.vadjustment.notify["value"].disconnect (update_scroll_on_top);
            }

            _current_scrolled_window = value;

            if (_current_scrolled_window != null) {
                _current_scrolled_window.vadjustment.notify["value"].connect (update_scroll_on_top);
                scroll_anim_target = new Adw.PropertyAnimationTarget (_current_scrolled_window.vadjustment, "value");
            }
            update_scroll_on_top ();
        }
    }

    Adw.PropertyAnimationTarget scroll_anim_target;
    Adw.TimedAnimation scroll_animation;

    protected bool scroll_on_top { get; private set; default = true; }

    bool _is_compact;
    protected bool is_compact {
        get {
            return _is_compact;
        }
        set {
            _is_compact = value;

            if (_is_compact) {
                osk_button.width_request =
                    osk_button.height_request =
                    go_prev_button.height_request =
                    go_prev_button.width_request =
                    to_up_button.height_request =
                    to_up_button.width_request =
                    32;
                button_center_box.margin_bottom = 6;
                go_next_button.remove_css_class ("pill");

            } else {
                osk_button.width_request =
                    osk_button.height_request =
                    go_prev_button.height_request =
                    go_prev_button.width_request =
                    to_up_button.height_request =
                    to_up_button.width_request =
                    48;
                button_center_box.margin_bottom = 12;
                go_next_button.add_css_class ("pill");
            }
        }
    }

    public bool can_close { get; set; }

    public bool show_steps_list { get; set; }

    public bool is_ready_to_continue { get; set; }

    public bool can_up { get; set; }

    static Gee.ArrayList<string> passed_pages = new Gee.ArrayList<string> ();

    public bool simple { get; set; }

    public virtual LayoutMode layout_mode { get; set; }

    PageInfo _last_current_page;
    PageInfo last_current_page {
        get {
            return _last_current_page;
        }
        set {
            if (_last_current_page != null) {
                _last_current_page.notify["is-ready"].disconnect (update_buttons);
                notify["scroll-on-top"].disconnect (update_scroll);
            }

            _last_current_page = value;

            _last_current_page.notify["is-ready"].connect (update_buttons);
            notify["scroll-on-top"].connect (update_scroll);
            update_scroll ();
        }
    }

    public bool can_cancel { get; set; }

    PagesModel _model;
    public PagesModel? model {
        get {
            return _model;
        }
        set {
            if (_model != null) {
                _model.selection_changed.disconnect (selection_changed);
            }

            _model = value;

            positioned_stack.bind_model (_model, page_creation_func);
            info_positioned_stack.bind_model (_model, page_info_creation_func);

            if (_model != null) {
                _model.selection_changed.connect (selection_changed);
                selection_changed ();
            }
        }
    }

    Gtk.Widget page_creation_func (PageInfo page) {
        if (page.id in passed_pages) {
            page.passed = true;
        }

        bind_property ("layout-mode", page.page, "layout-mode", SYNC_CREATE);

        return page.page;
    }

    Gtk.Widget page_info_creation_func (PageInfo page) {
        notify["is-compact"].connect (() => {
            if (is_compact) {
                page.page.info.add_css_class ("compact");
            } else {
                page.page.info.remove_css_class ("compact");
            }
        });
        return page.page.info;
    }

    construct {
        model = Application.get_default ().model;
        pages_indicator.model = model;

        can_close = Application.get_default ().can_close;
        context_button.visible = Config.IS_DEVEL;
        sandbox_label_left.visible = ReadySet.Application.get_default ().context.sandbox && Config.IS_DEVEL;
        sandbox_label_right.visible = ReadySet.Application.get_default ().context.sandbox && !Config.IS_DEVEL;

        notify["show-steps-list"].connect (update_icons_visible);
        notify["simple"].connect (update_icons_visible);
        update_icons_visible ();

        set_breakpoints ();

        setup.begin ();
    }

    async void setup () {
        Osk? proxy = null;
        try {
            proxy = yield get_osk_proxy ();
        } catch (Error e) {
            debug ("Can't get OSK proxy: %s", e.message);
        }

        var a11y_settings = new Settings ("org.gnome.desktop.a11y.applications");

        osk_button.visible = (proxy != null && a11y_settings.get_boolean ("screen-keyboard-enabled")) ||
             Environment.get_variable ("READY_SET_SHOW_OSK") == "always";

        to_up_revealer.notify["child-revealed"].connect (() => {
            if (!to_up_revealer.child_revealed) {
                to_up_revealer.visible = false;
            }
        });
        notify["can-up"].connect (() => {
            if (can_up) {
                to_up_revealer.visible = true;
                to_up_revealer.reveal_child = true;
            } else {
                to_up_revealer.reveal_child = false;
            }
        });
    }

    void update_icons_visible () {
        pages_indicator.show_icons = !show_steps_list && !simple;
    }

    void selection_changed () {
        update_buttons ();
        update_scroll ();

        last_current_page = model.get_selected_item ();

        var base_page = last_current_page.page;
        top_bin.child = base_page.top_widget;
        bottom_bin.child = base_page.bottom_widget;

        passed_pages.add (last_current_page.id);
        last_current_page.passed = true;
    }

    void update_scroll () {
        if (current_scrolled_window != null) {
            if (current_scrolled_window.vadjustment != null) {
                can_up = !(current_scrolled_window.vadjustment.value <= 360.0);
            }
        }
    }

    void update_buttons () {
        is_ready_to_continue = model.get_selected_item ().is_ready;
        can_cancel = model.get_selected () > 0;
    }

    [GtkCallback]
    void on_context_button_clicked () {
        if (devel_window == null) {
            devel_window = new Devel.Window ();
            devel_window.close_request.connect (on_devel_close_request);
        }

        devel_window.present ();
    }

    bool on_devel_close_request () {
        devel_window = null;
        return false;
    }

    void update_scroll_on_top () {
        scroll_on_top = current_scrolled_window?.vadjustment.value <= 360.0;
    }

    [GtkCallback]
    async void osk_clicked () {
        try {
            var proxy = yield get_osk_proxy ();
            yield proxy.set_visible (!proxy.visible);
        } catch (Error e) {
            warning (e.message);
        }
    }

    [GtkCallback]
    void up_clicked () {
        current_scrolled_window.set_kinetic_scrolling (false);

        if (scroll_anim_target == null) {
            return;
        }

        if (scroll_animation != null) {
            scroll_animation.reset ();
        }

        scroll_animation = new Adw.TimedAnimation (
            current_scrolled_window,
            current_scrolled_window.vadjustment.value,
            0.0,
            100,
            scroll_anim_target
        );

        scroll_animation.play ();
        current_scrolled_window.set_kinetic_scrolling (true);
    }

    [GtkCallback]
    void cancel_clicked () {
        model?.select_item (model.get_selected () - 1, true);
    }

    [GtkCallback]
    void continue_clicked () {
        var position = model.get_selected ();
        var n_items = model.get_n_items ();

        if (position == n_items - 1) {
            main_stack.visible_child_name = "finish";
            end_page.start_action.begin ();
        } else {
            model.select_item (model.get_selected () + 1, true);
        }
    }

    void set_breakpoints () {
        var force_layout = Application.get_default ().options_handler.force_layout;

        if (force_layout != null) {
            Adw.Breakpoint? force_breakpoint = null;
            switch (LayoutMode.from_string (force_layout)) {
                case BIG:
                    force_breakpoint = big_breakpoint;
                    break;
                case SMALL:
                    force_breakpoint = small_breakpoint;
                    break;
                case VERTICAL:
                    force_breakpoint = vertical_breakpoint;
                    break;
                case HORIZONTAL:
                    force_breakpoint = horizontal_breakpoint;
                    break;
            }

            Adw.Breakpoint[] all_breakpoints = {
                big_breakpoint,
                small_breakpoint,
                vertical_breakpoint,
                horizontal_breakpoint
            };

            foreach (var bp in all_breakpoints) {
                if (bp != force_breakpoint) {
                    remove_breakpoint (bp);
                }
            }

            //  Set breakpoint condition for all cases
            force_breakpoint.condition = new Adw.BreakpointCondition.length (
                Adw.BreakpointConditionLengthType.MIN_HEIGHT, 0, Adw.LengthUnit.SP
            );
        }
    }
}
