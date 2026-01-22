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

public sealed class ReadySetInternal.Application: GLib.Application {

    bool generate_rules_opt;
    bool clear_rules_opt;
    bool reload_polkit;
    string user_opt;

    internal const OptionEntry[] OPTION_ENTRIES = {
        { "version", 'v', 0, OptionArg.NONE, null, N_("Print version information and exit"), null },
        { "generate-rules", '\0', 0, OptionArg.NONE, null, N_("Generate polkit rules"), null },
        { "clear-rules", '\0', 0, OptionArg.NONE, null, N_("Clear generated rules"), null },
        { "restart-polkit", '\0', 0, OptionArg.NONE, null, N_("Reload polkit after actions"), null },
        { "user", 'u', 0, OptionArg.STRING, null, N_("User for which will be generated plugin polkit rules"), "STEPS_NO_APPLY" },
        { null }
    };

    public Application () {
        Object (
            application_id: Config.APP_ID_DYN
        );
    }

    construct {
        add_main_option_entries (OPTION_ENTRIES);
    }

    protected override int handle_local_options (VariantDict options) {
        if (options.contains ("version")) {
            print ("%s\n", Config.VERSION);
            return 0;
        }

        if (options.contains ("user")) {
            user_opt = options.lookup_value ("user", VariantType.STRING).dup_string ();
        }

        if (options.contains ("generate-rules")) {
            generate_rules_opt = true;
        }

        if (options.contains ("clear-rules")) {
            clear_rules_opt = true;
        }

        if (options.contains ("restart-polkit")) {
            reload_polkit = true;
        }

        return -1;
    }

    protected override void startup () {
        base.startup ();

        if (generate_rules_opt && clear_rules_opt) {
            error ("internal-clear-rules and internal-generate-rules options cannot be used together");
        }

        string user = "ready-set";
        if (user_opt != null) {
            user = user_opt;
        }

        if (generate_rules_opt) {
            clear_rules ();
            generate_rules (user);
        }

        if (clear_rules_opt) {
            clear_rules ();
        }

        if (reload_polkit) {
            try {
                pkexec ({ "systemctl", "reload", "polkit" });
            } catch (Error e) {
                error ("Failed to reload polkit: %s", e.message);
            }
        }
    }

    protected override void activate () {
        base.activate ();
    }
}
