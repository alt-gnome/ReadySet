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

[GtkTemplate (ui = "/org/altlinux/ReadySet/ui/end-page.ui")]
public sealed class ReadySet.EndPage : BaseBarePage {

    const string SERVICE_NAME = "gdm-password";

    Gdm.Client client;
    Gdm.Greeter greeter;
    Gdm.UserVerifier user_verifier;

    [GtkChild]
    unowned Gtk.Stack stack;
    [GtkChild]
    unowned Adw.StatusPage error_status_page;
    [GtkChild]
    unowned Adw.StatusPage apply_status_page;
    [GtkChild]
    unowned Gtk.ProgressBar progress_bar;

    ProgressData progress_data = new ProgressData ();

    bool password_sent = false;

    construct {
        Application.get_default ().on_finish.connect (done);
    }

    public async void start_action () {
        var app = Application.get_default ();
        var context = app.context;
        context.locked = true;

        if (!app.has_installer && !context.intact) {
            try {
                client = new Gdm.Client ();
                greeter = yield client.get_greeter (null);
                user_verifier = yield client.get_user_verifier (null);
            } catch (Error e) {
                warning ("Failed to connect to GDM: %s", e.message);
                client = null;
                greeter = null;
                user_verifier = null;
            }
        }

        stack.visible_child_name = "applying";

        progress_data.bind_property ("message", apply_status_page, "description");
        progress_data.bind_property ("value", progress_bar, "fraction");

        progress_data.notify["value"].connect (update_progress_visibility);
        update_progress_visibility ();

        Gee.ArrayList<Applyable> applyable_arr = new Gee.ArrayList<Applyable> ();

        for (int i = 0; i < app.model.get_n_items (); i++) {
            var page_info = (PageInfo) app.model.get_item (i);

            if (!page_info.apply_plugin) {
                continue;
            }

            if (!(page_info.plugin in applyable_arr)) {
                applyable_arr.add (page_info.plugin);
            }
            applyable_arr.add (page_info.page);
        }

        if (context.intact) {
            Timeout.add_seconds (1, () => {
                progress_data.value += 0.2;
                progress_data.message = _("Doing some stuff…");

                if (progress_data.value >= 1.0) {
                    Idle.add (start_action.callback);
                    return false;
                }

                return true;
            });
            yield;

        } else {
            try {
                foreach (var applyable in applyable_arr) {
                    progress_data.value = 0.0;

                    yield applyable.apply (progress_data);

                    progress_data.value = 1.0;
                }

                yield app.installer_plugin.install (progress_data);

                var raw_context = context.get_raw_string ();
                var env = new Gee.ArrayList<string> ();

                foreach (var key in raw_context.get_keys ()) {
                    env.add ("%s=\"%s\"".printf (context_key_to_env_key (key), raw_context[key]));
                }

                get_ready_set_proxy ().exec_post_hooks (env.to_array ());

            } catch (ApplyError e) {
                var apply_error_data = ApplyError.to_data (e);

                error_status_page.title = apply_error_data.message;
                error_status_page.description = _("Error message: %s").printf (apply_error_data.description);

                stack.visible_child_name = "error";
                is_ready = false;
            } catch (Error e) {
                error_status_page.title = _("Error while execute post hooks");
                error_status_page.description = _("Error message: %s").printf (e.message);

                stack.visible_child_name = "error";
                is_ready = false;
            }
        }

        stack.visible_child_name = "ready";
        is_ready = true;
    }

    void update_progress_visibility () {
        progress_bar.visible = 1.0 > progress_data.value > 0;
    }

    void done () {
        var app = Application.get_default ();
        var context = app.context;

        if (context.intact) {
            return;
        }

        if (!app.has_installer && client != null) {
            activate_action ("app.hide-window", null);
            log_user_in ();
        } else {
            app.quit ();
        }
    }

    void request_info_query (Gdm.UserVerifier user_verifier, string question, bool is_secret) {
        /* TODO: pop up modal dialog */
        debug (
            "user verifier asks%s question: %s",
            is_secret ? " secret" : "",
            question
        );
    }

    void on_info (Gdm.UserVerifier user_verifier, string service_name, string info) {
        debug ("PAM module info: %s", info);
    }

    void on_problem (Gdm.UserVerifier user_verifier, string service_name, string problem) {
        warning ("PAM module error: %s", problem);
    }

    void on_info_query (Gdm.UserVerifier user_verifier, string service_name, string question) {
        request_info_query (user_verifier, question, false);
    }

    void on_secret_info_query (Gdm.UserVerifier user_verifier, string service_name, string question) {
        var context = Application.get_default ().context;

        debug ("PAM module secret info query %s", question);
        if (context.has_key ("user-password") && !password_sent) {
            debug ("sending password\n");
            user_verifier.call_answer_query.begin (service_name, context.get_string ("user-password"), null);
            password_sent = true;
        } else {
            request_info_query (user_verifier, question, true);
        }
    }

    void on_session_opened (Gdm.Greeter greeter, string service_name, string session_id) {
        try {
            greeter.call_start_session_when_ready_sync (service_name, true, null);
        } catch (Error e) {
            warning ("Failed to open session: %s", e.message);
        }
    }

    void add_uid_file (int64 uid) {
        var gis_uid_path = Path.build_filename (Environment.get_home_dir (), "gnome-initial-setup-uid");
        var uid_str = uid.to_string ();

        try {
            FileUtils.set_contents (gis_uid_path, uid_str);
        } catch (Error e) {
            warning ("Unable to create %s: %s", gis_uid_path, e.message);
        }
    }

    void log_user_in () {
        var context = Application.get_default ().context;

        if (client == null) {
            warning ("No GDM connection; not initiating login");
            return;
        }

        user_verifier.info.connect (on_info);
        user_verifier.problem.connect (on_problem);
        user_verifier.info_query.connect (on_info_query);
        user_verifier.secret_info_query.connect (on_secret_info_query);

        greeter.session_opened.connect (on_session_opened);

        add_uid_file (context.get_int ("user-created-uid"));

        try {
            user_verifier.call_begin_verification_for_user_sync (SERVICE_NAME, context.get_string ("user-username"), null);
        } catch (Error e) {
            warning ("Could not begin verification: %s", e.message);
        }
    }
}
