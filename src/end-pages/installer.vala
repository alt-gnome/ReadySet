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

[GtkTemplate (ui = "/org/altlinux/ReadySet/ui/installer-end-page.ui")]
public sealed class ReadySet.InstallerEndPage : EndPage {

    [GtkChild]
    unowned Gtk.Stack stack;
    [GtkChild]
    unowned StatusPage icon_status_page;
    [GtkChild]
    unowned Gtk.ProgressBar progress_bar;
    [GtkChild]
    unowned Gtk.Revealer progress_revealer;
    [GtkChild]
    unowned Adw.StatusPage status_page;
    [GtkChild]
    unowned Gtk.Button quit_button;
    [GtkChild]
    unowned Gtk.Button reboot_button;
    [GtkChild]
    unowned Gtk.ListBox stages_box;
    [GtkChild]
    unowned Gtk.Revealer log_btn_revealer;
    [GtkChild]
    unowned Gtk.Button log_btn;
    [GtkChild]
    unowned Gtk.Revealer log_revealer;
    [GtkChild]
    unowned Vte.Terminal logs_view;
    [GtkChild]
    unowned Gtk.Box progress_box;
    [GtkChild]
    unowned Gtk.Label description_label;
    [GtkChild]
    unowned Gtk.Label global_percentage_label;
    [GtkChild]
    unowned Adw.ToastOverlay toast_overlay;

    InstallerProgressData progress_data = new InstallerProgressData ();

    construct {
        var name = Environment.get_os_info (OsInfoKey.NAME);

        if (name != null) {
            //  Translators: %s here is os distribution name: ALT, Fedora, Ubuntu
            status_page.description = _("%s is installed on Your device.").printf (name);
        } else {
            status_page.description = _("System is installed on Your device.");
        }

        logs_view.add_css_class ("log-view");
    }

    public override async void start_action () {
        stack.visible_child_name = "applying";

        progress_data.bind_property ("description", description_label, "label", SYNC_CREATE);
        progress_data.bind_property ("value", progress_bar, "fraction", SYNC_CREATE);
        progress_data.bind_property ("pulse-step", progress_bar, "pulse-step", SYNC_CREATE);
        progress_data.bind_property ("paintable", icon_status_page, "paintable", SYNC_CREATE);
        progress_data.bind_property ("icon-name", icon_status_page, "icon-name", SYNC_CREATE);
        progress_data.pulse.connect (on_pulse);
        progress_data.push_log.connect (on_push_log);
        progress_data.notify["value"].connect (update_global);
        progress_data.pass_stage.connect (update_global);
        update_global ();

        progress_data.bind_property ("visibility", progress_revealer, "reveal-child", SYNC_CREATE);

        var model = progress_data.get_model ();

        var filter_model = new Gtk.FilterListModel (model, new Gtk.BoolFilter (
            new Gtk.PropertyExpression (typeof (InstallerStage), null, "is-current")
        ) { invert = true }) { watch_items = true };
        var sort_model = new Gtk.SortListModel (filter_model, new Gtk.NumericSorter (
            new Gtk.PropertyExpression (typeof (InstallerStage), null, "numeric-state")
        ) { sort_order = Gtk.SortType.ASCENDING });

        stages_box.bind_model (sort_model, build_state_row);


        try {
            if (sandbox) {
                progress_data.fill_stages ({
                    new InstallerStage ("1", _("Preparing"), 0.1),
                    new InstallerStage ("2", _("Installing")),
                    new InstallerStage ("3", _("Cleaning"), 0.05),
                });

                yield fake_install (progress_data);

                update_reboot_visible ();
                stack.visible_child_name = "ready";

            } else {
                yield finalizer.run (progress_data);
                update_reboot_visible ();
                stack.visible_child_name = "ready";
            }
        } catch (ApplyError e) {
            var error_data = apply_error_to_data (e);
            progress_data.push_log (errorify (error_data.message));
            progress_data.push_log (errorify (_("Error message: %s").printf (error_data.description)));
            set_error ();
            progress_data.icon_name = "dialog-error-symbolic";
        }
    }

    Gtk.Widget build_state_row (Object el) {
        return new InstallerStageRow ((InstallerStage) el);
    }

    void update_reboot_visible () {
        var can_reboot = false;
        try {
            can_reboot = can_reboot_system ();
        } catch (Error e) {}

        can_reboot = can_reboot && !sandbox;

        if (can_reboot) {
            quit_button.remove_css_class ("suggested-action");
            reboot_button.visible = true;
        } else {
            quit_button.add_css_class ("suggested-action");
            reboot_button.visible = false;
        }
    }

    void update_global () {
        var model = progress_data.get_model ();

        double global = 0.0;

        InstallerStage? current_stage = null;

        for (uint i = 0; i < model.get_n_items (); i++) {
            var stage = (InstallerStage) model.get_item (i);
            if (stage.state == PASSED) {
                global += stage.size;
            } else if (stage.state == CURRENT) {
                current_stage = stage;
            } else {
                break;
            }
        }


        uint percent = 0;

        if (current_stage != null) {
            global += progress_data.value * current_stage.size;
            percent = (uint) (global * 100);
        }

        global_percentage_label.label = "<b>%u%%</b>".printf (percent);
    }

    void on_pulse () {
        progress_bar.pulse ();
    }

    void on_push_log (string log) {
        if (!log_btn_revealer.reveal_child) {
            log_btn_revealer.reveal_child = true;
            log_revealer.bind_property ("reveal-child", log_btn, "visible", SYNC_CREATE | INVERT_BOOLEAN);
        }

        logs_view.feed (log.data);
        logs_view.feed ("\r\n".data);
    }

    void set_error () {
        if (!progress_box.has_css_class ("error")) {
            progress_box.remove_css_class ("accent");
            icon_status_page.remove_css_class ("accent");
            progress_box.add_css_class ("error");
            icon_status_page.add_css_class ("error");

            var toast = new Adw.Toast (_("Something went wrong"));
            toast.button_label = _("Details");
            toast.button_clicked.connect (open_log);

            toast_overlay.add_toast (toast);
        }
    }

    [GtkCallback]
    void toggle_log () {
        log_revealer.reveal_child = !log_revealer.reveal_child;
    }

    void open_log () {
        log_revealer.reveal_child = true;
    }

    async void wait_async (uint sec) {
        Timeout.add_seconds_once (sec, () => {
            Idle.add (wait_async.callback);
        });
        yield;
    }

    async void fake_install (InstallerProgressData progress_data) throws ApplyError {
        progress_data.pulse_step = 0.6;

        progress_data.description = "Preparing some data";

        yield wait_async (1);

        for (uint i = 0; i < 3; i++) {
            progress_data.pulse ();
            yield wait_async (1);
        }

        progress_data.pass_stage ("1");

        double val = 0;
        for (uint i = 0; i < 5; i++) {
            progress_data.description = "Installing %u".printf (i);
            progress_data.push_log ("Some very important data: IMPORTANT!!!!: " + Uuid.string_random ());
            progress_data.value = val;
            yield wait_async (1);
            val += 0.2;
        }

        progress_data.pass_stage ("2");

        progress_data.push_log ("Warning example");

        progress_data.description = "Cleaning some data";

        for (uint i = 0; i < 2; i++) {
            progress_data.pulse ();
            yield wait_async (1);
        }

        progress_data.visibility = false;

        yield wait_async (1);

        progress_data.pass_stage ("3");
        progress_data.description = "";
    }

    [GtkCallback]
    bool description_label_is_not_empty (string? str, bool percentage_visible) {
        return str != null && str != "" || percentage_visible;
    }
}
