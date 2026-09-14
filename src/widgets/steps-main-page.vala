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
    unowned PositionedStack vertical_stack;
    [GtkChild]
    unowned PositionedStack info_positioned_stack;
    [GtkChild]
    unowned Gtk.Label standalone_sandbox_label;
    [GtkChild]
    unowned Gtk.Label sandbox_label_left;
    [GtkChild]
    unowned Gtk.Label sandbox_label_right;
    [GtkChild]
    unowned Gtk.CenterBox button_center_box;
    [GtkChild]
    unowned Gtk.Button osk_button;
    [GtkChild]
    unowned Gtk.Stack main_stack;

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
    unowned Adw.Bin top_bin;
    [GtkChild]
    unowned Adw.Bin bottom_bin;

    [GtkChild]
    unowned Adw.ToolbarView page_toolbar;
    [GtkChild]
    unowned Gtk.Button end_page_back_button;

    bool _standalone;
    public bool standalone {
        get {
            return _standalone;
        }
        set {
            _standalone = value;
            update_center_button_pos ();
        }
    }

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
                    32;
                button_center_box.margin_bottom = 6;
                go_next_button.remove_css_class ("pill");

            } else {
                osk_button.width_request =
                    osk_button.height_request =
                    go_prev_button.height_request =
                    go_prev_button.width_request =
                    48;
                button_center_box.margin_bottom = 12;
                go_next_button.add_css_class ("pill");
            }
        }
    }

    public bool center_buttons { get; set; }
    bool center_buttons_hold = false;

    public bool is_ready_to_continue { get; set; }

    static Gee.ArrayList<string> passed_pages = new Gee.ArrayList<string> ();

    LayoutMode _layout_mode;
    public LayoutMode layout_mode {
        get {
            return _layout_mode;
        }
        set {
            _layout_mode = value;

            update_model_binds ();
            update_standalone ();
        }
    }

    PageInfo _last_current_page;
    PageInfo last_current_page {
        get {
            return _last_current_page;
        }
        set {
            if (_last_current_page != null) {
                _last_current_page.notify["is-ready"].disconnect (update_buttons);
                _last_current_page.page.next.disconnect (next);
            }

            _last_current_page = value;

            _last_current_page.notify["is-ready"].connect (update_buttons);
            _last_current_page.page.next.connect (next);
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
                _model.items_changed.disconnect (on_model_items_changed);
            }

            _model = value;

            update_model_binds ();

            if (_model != null) {
                _model.selection_changed.connect (selection_changed);
                _model.items_changed.connect (on_model_items_changed);
                selection_changed ();
                on_model_items_changed ();
            }
        }
    }

    Binding[] model_pages_bindings = {};

    public EndPageFactory end_page_factory { get; construct; }

    public string? force_layout { get; construct; }

    public bool sandbox { get; construct; }

    public StepsMainPage (
        PagesModel model,
        EndPageFactory end_page_factory,
        string? force_layout,
        bool sandbox
    ) {
        Object (
            model: model,
            end_page_factory: end_page_factory,
            force_layout: force_layout,
            sandbox: sandbox
        );
    }

    construct {
        sandbox_label_left.visible = sandbox && Config.NIGHTLY;
        sandbox_label_right.visible = sandbox && !Config.NIGHTLY;

        set_breakpoints ();

        setup.begin ();
    }

    void update_model_binds () {
        if (layout_mode == VERTICAL || layout_mode == SMALL) {
            if (positioned_stack.model != null) {
                positioned_stack.bind_model (
                    null,
                    page_creation_func,
                    page_creation_dispose
                );
            }
            if (info_positioned_stack.model != null) {
                info_positioned_stack.bind_model (
                    null,
                    page_info_creation_func
                );
            }
            if (vertical_stack.model == null) {
                vertical_stack.bind_model (
                    _model,
                    vertical_stack_creation_func,
                    vertical_stack_creation_dispose
                );
            }
        } else {
            if (vertical_stack.model != null) {
                vertical_stack.bind_model (
                    null,
                    vertical_stack_creation_func,
                    vertical_stack_creation_dispose
                );
            }
            if (positioned_stack.model == null) {
                positioned_stack.bind_model (
                    _model,
                    page_creation_func,
                    page_creation_dispose
                );
            }
            if (info_positioned_stack.model == null) {
                info_positioned_stack.bind_model (
                    _model,
                    page_info_creation_func
                );
            }
        }
    }

    void on_model_items_changed () {
        foreach (var b in model_pages_bindings) {
            b.unbind ();
        }

        for (uint i = 0; i < model.get_n_items (); i++) {
            model_pages_bindings += bind_property (
                "is-compact",
                model.get_item (i),
                "is-compact",
                SYNC_CREATE
            );
        }
    }

    Gtk.Widget page_creation_func (PageInfo page) {
        var scrolled_window = new Gtk.ScrolledWindow () {
            propagate_natural_height = true,
            hscrollbar_policy = NEVER
        };

        if (page.id in passed_pages) {
            page.passed = true;
        }

        bind_property ("layout-mode", page.page, "layout-mode", SYNC_CREATE);

        scrolled_window.child = page.page;

        return scrolled_window;
    }

    void page_creation_dispose (Gtk.Widget widget) {
        var scrolled_window = (Gtk.ScrolledWindow) widget;
        scrolled_window.child = null;
    }

    Gtk.Widget page_info_creation_func (PageInfo page) {
        return page.page.info ?? new StatusPage ();
    }

    Gtk.Widget vertical_stack_creation_func (PageInfo page) {
        var scrolled_window = new Gtk.ScrolledWindow () {
            propagate_natural_height = true,
            hscrollbar_policy = NEVER
        };

        var box = new Gtk.Box (VERTICAL, 36) {
            valign = page.page.valign
        };
        scrolled_window.child = box;

        if (page.page.info != null) {
            box.append (page.page.info);
        }
        box.append (page.page);

        return scrolled_window;
    }

    void vertical_stack_creation_dispose (Gtk.Widget widget) {
        var scrolled_window = (Gtk.ScrolledWindow) widget;
        scrolled_window.child = null;
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
    }

    void selection_changed () {
        update_buttons ();

        last_current_page = model.get_selected_item ();

        if (last_current_page == null) {
            critical ("Model has no enabled pages");
            return;
        }

        var base_page = last_current_page.page;
        top_bin.child = base_page.top_widget;
        bottom_bin.child = base_page.bottom_widget;

        passed_pages.add (last_current_page.id);
        last_current_page.passed = true;
        standalone = base_page.info == null;
        update_standalone ();
    }

    void update_standalone () {
        standalone_sandbox_label.visible = sandbox &&
            Config.NIGHTLY && standalone;
    }

    void update_buttons () {
        var selected_item = model.get_selected_item ();

        if (selected_item == null) {
            critical ("Model has no selected page");
            return;
        }

        is_ready_to_continue = selected_item.is_ready;
        can_cancel = model.get_selected () > 0;
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
    void cancel_clicked () {
        model?.select_item (model.get_selected () - 1, true);
    }

    [GtkCallback]
    void continue_clicked () {
        model.get_selected_item ().page.try_continue ();
    }

    void next () {
        var position = model.get_selected ();
        var n_items = model.get_n_items ();

        if (position == n_items - 1) {

            if (page_toolbar.content == null) {
                var page = end_page_factory.build ();
                page_toolbar.content = page;
                end_page_back_button.visible = page.can_go_prev ();
                page.start_action.begin ();
            }

            main_stack.visible_child_name = "end";

        } else {
            model.select_item (model.get_selected () + 1, true);
        }
    }

    [GtkCallback]
    void to_main () {
        main_stack.visible_child_name = "main";
    }

    void set_breakpoints () {
        if (force_layout != null) {
            Adw.Breakpoint? force_breakpoint = null;
            switch (layout_mode_from_string (force_layout)) {
                case BIG:
                    force_breakpoint = big_breakpoint;
                    break;
                case SMALL:
                    force_breakpoint = small_breakpoint;
                    break;
                case VERTICAL:
                    force_breakpoint = vertical_breakpoint;
                    break;
            }

            Adw.Breakpoint[] all_breakpoints = {
                big_breakpoint,
                small_breakpoint,
                vertical_breakpoint,
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

    [GtkCallback]
    bool @and (bool a, bool b) {
        return a && b;
    }

    [GtkCallback]
    void on_eventcontrollermotion_enter () {
        center_buttons_hold = true;
    }

    [GtkCallback]
    void on_eventcontrollermotion_leave () {
        center_buttons_hold = false;
        update_center_button_pos ();
    }

    void update_center_button_pos () {
        if (center_buttons_hold) {
            return;
        }

        center_buttons = standalone;
    }
}
