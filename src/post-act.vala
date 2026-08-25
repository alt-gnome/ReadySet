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

public sealed class ReadySet.PostAct : Object, AsyncInitable {

    const string SERVICE_NAME = "gdm-password";

#if WITH_GDM
    Gdm.Client client;
    Gdm.Greeter greeter;
    Gdm.UserVerifier user_verifier;
#endif

    bool password_sent = false;

    public Context context { get; construct; }

    public PostAct (Context context) {
        Object (context: context);
    }

    public async bool init (GLib.Cancellable? cancellable) {
        try {
            client = new Gdm.Client ();
            greeter = yield client.get_greeter (null);
            user_verifier = yield client.get_user_verifier (null);
            debug ("Connected to GDM");
            return true;
        } catch (Error e) {
            warning ("Failed to connect to GDM: %s", e.message);
            client = null;
            greeter = null;
            user_verifier = null;
            return false;
        }
    }

    public void @do () {
#if WITH_GDM
        if (client == null) {
            debug ("No GDM connection");
        } else {
            log_user_in ();
            return;
        }
#endif
#if WITH_PHROG
        var phrog_schema = SettingsSchemaSource.get_default ().lookup ("mobi.phosh.phrog", false);
        if (phrog_schema != null) {
            var phrog_settings = new Settings (phrog_schema.get_id ());
            phrog_settings.set_string ("first-run", "");
        }
#endif
    }

#if WITH_GDM
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
        debug ("PAM module secret info query %s", question);
        if (context.has_key ("user.password") && !password_sent) {
            debug ("sending password\n");
            user_verifier.call_answer_query.begin (service_name, context.get_string ("user.password"), null);
            password_sent = true;
        } else {
            request_info_query (user_verifier, question, true);
        }
    }

    void on_session_opened (Gdm.Greeter greeter, string service_name, string session_id) {
        try {
            debug ("Starting session");
            greeter.call_start_session_when_ready_sync (service_name, true, null);
        } catch (Error e) {
            warning ("Failed to open session: %s", e.message);
        }
    }

    // void add_uid_file (int64 uid) {
    //     var gis_uid_path = Path.build_filename (Environment.get_home_dir (), "gnome-initial-setup-uid");
    //     var uid_str = uid.to_string ();

    //     try {
    //         FileUtils.set_contents (gis_uid_path, uid_str);
    //     } catch (Error e) {
    //         warning ("Unable to create %s: %s", gis_uid_path, e.message);
    //     }
    // }

    void log_user_in () {
        if (client == null) {
            warning ("No GDM connection; not initiating login");
            Application.get_default ().quit ();
            return;
        }

        user_verifier.info.connect (on_info);
        user_verifier.problem.connect (on_problem);
        user_verifier.info_query.connect (on_info_query);
        user_verifier.secret_info_query.connect (on_secret_info_query);
        debug ("Connected callbacks to user-verifier");

        greeter.session_opened.connect (on_session_opened);
        debug ("Connected callbacks to greeter");

        try {
            debug ("Begin verification for user");
            user_verifier.call_begin_verification_for_user_sync (
                SERVICE_NAME,
                context.get_string ("user.username"),
                null
            );
            debug ("Verification for user succeed");
        } catch (Error e) {
            warning ("Could not begin verification: %s", e.message);
        }
    }
#endif
}
