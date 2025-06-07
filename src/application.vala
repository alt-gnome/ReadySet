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

public sealed class ReadySet.Application: Adw.Application {

    const ActionEntry[] ACTION_ENTRIES = {};

    const OptionEntry[] OPTION_ENTRIES = {
        { "version", 'v', 0, OptionArg.NONE, null, N_("Print version information and exit"), null },
        { "steps-file", 'f', 0, OptionArg.FILENAME, null, N_("Filename with steps"), "FILENAME" },
        { "steps", 's', 0, OptionArg.STRING, null, N_("Steps. e.g: `steps=language,keyboard,end`"), "STEPS" },
        { null }
    };

    public string? steps_filename = null;
    public string[]? steps = null;

    public bool show_steps { get; set; default = false; }

    ApplyCallback[] apply_callbacks = {};

    public Application () {
        Object (
            application_id: Config.APP_ID_DYN,
            resource_base_path: "/space/rirusha/ReadySet/"
        );
    }

    static construct {
        typeof (BasePageDesc).ensure ();
        typeof (ContextRow).ensure ();
        typeof (LangSelectTitle).ensure ();
        typeof (LanguagesBox).ensure ();
        typeof (MarginLabel).ensure ();
        typeof (PagesIndicator).ensure ();
        typeof (PositionedStack).ensure ();
        typeof (StepRow).ensure ();
        typeof (StepsMainPage).ensure ();
        typeof (StepsSidebar).ensure ();

        typeof (TestPage).ensure ();
        typeof (BasePage).ensure ();
        typeof (EndPage).ensure ();
        typeof (KeyboardPage).ensure ();
        typeof (LanguagePage).ensure ();
        typeof (UserPage).ensure ();
        typeof (UserWithRootPage).ensure ();
        typeof (WelcomePage).ensure ();
    }

    construct {
        add_main_option_entries (OPTION_ENTRIES);
        add_action_entries (ACTION_ENTRIES, this);
        set_accels_for_action ("app.quit", { "<primary>q" });
    }

    protected override int handle_local_options (VariantDict options) {
        if (options.contains ("version")) {
            print ("%s\n", Config.VERSION);
            return 0;

        } else if (options.contains ("steps-file")) {
            steps_filename = options.lookup_value ("steps-file", null).get_bytestring ();

        } else if (options.contains ("steps")) {
            steps = options.lookup_value ("steps", null).get_string ().split (",");
            for (int i = 0; i < steps.length; i++) {
                steps[i] = steps[i].strip ();
            }
        }

        return -1;
    }

    public void add_apply_callback (ApplyCallback callback) {
        apply_callbacks.resize (apply_callbacks.length + 1);
        apply_callbacks[apply_callbacks.length - 1] = callback;
    }

    public void apply_all () throws ApplyError {
        foreach (var callback in apply_callbacks) {
            callback.apply ();
        }
    }

    public void reload_window () {
        (active_window as ReadySet.Window)?.reload_window ();
    }

    public override void activate () {
        base.activate ();

        if (active_window == null) {
            var win = new Window (this);

            win.present ();

        } else {
            active_window.present ();
        }
    }

    public new static ReadySet.Application get_default () {
        return (ReadySet.Application) GLib.Application.get_default ();
    }
}
