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

namespace ReadySet.Completions {

    void print_completion_script () {
        var plugin_manager = new PluginManager (new Context (true));
        plugin_manager.blank_init ();

        var steps_plugins = plugin_manager.get_available_steps ();
        var installers_plugins = plugin_manager.get_available_installers ();

        print ("# bash completion for ready-set\n");
        print ("# Regenerate with: ready-set generate-bash-completion\n\n");
        print ("_ready_set() {\n");
        print ("    local cur prev opts commands\n");
        print ("    COMPREPLY=()\n");
        print ("    cur=\"${COMP_WORDS[COMP_CWORD]}\"\n");
        print ("    prev=\"${COMP_WORDS[COMP_CWORD-1]}\"\n\n");
        print ("    opts=\"");

        bool first_opt = true;
        foreach (var entry in OptionsHandler.OPTION_ENTRIES) {
            if (entry.long_name == null)
                continue;

            if (entry.flags == OptionFlags.HIDDEN)
                continue;

            if (!first_opt)
                print (" ");
            first_opt = false;

            print ("--%s", entry.long_name);
        }

        //  GApplication standard help flags
        print (" -h --help --help-all --help-gapplication");

        print ("\"\n\n");

        print ("    steps=\"");
        first_opt = true;
        foreach (var name in steps_plugins) {
            if (!first_opt)
                print (" ");
            first_opt = false;
            print ("%s", name);
        }
        print ("\"\n\n");

        print ("    installers=\"");
        first_opt = true;
        foreach (var name in installers_plugins) {
            if (!first_opt)
                print (" ");
            first_opt = false;
            print ("%s", name);
        }
        print ("\"\n\n");

        print ("    case \"${prev}\" in\n");

        print ("        generate-bash-completion)\n");
        print ("            return\n");
        print ("            ;;\n");

        foreach (var entry in OptionsHandler.OPTION_ENTRIES) {
            if (entry.long_name == null)
                continue;

            if (entry.flags == OptionFlags.HIDDEN)
                continue;

            if (entry.arg == OptionArg.NONE)
                continue;

            print ("        --%s)\n", entry.long_name);

            switch (entry.long_name) {
                case "force-mode":
                    print ("            COMPREPLY=( $(compgen -W \"initial-setup existing-user installer\" -- \"${cur}\") )\n");
                    break;
                case "force-layout":
                    print ("            COMPREPLY=( $(compgen -W \"big small vertical horizontal\" -- \"${cur}\") )\n");
                    break;
                case "steps":
                    print ("            compopt -o nospace 2>/dev/null\n");
                    print ("            local prefix=\"${cur%,*}\"\n");
                    print ("            if [[ \"\$prefix\" != \"\$cur\" ]]; then\n");
                    print ("                prefix=\"\$prefix,\"\n");
                    print ("            else\n");
                    print ("                prefix=\"\"\n");
                    print ("            fi\n");
                    print ("            local suffix=\"${cur##*,}\"\n");
                    print ("            local chosen=\"\${prefix%,}\"\n");
                    print ("            local available=\"\"\n");
                    print ("            local available_count=0\n");
                    print ("            for step in \${steps}; do\n");
                    print ("                if [[ \",\$chosen,\" != *\",\$step,\"* ]]; then\n");
                    print ("                    available=\"\$available \$step\"\n");
                    print ("                    available_count=\$((available_count + 1))\n");
                    print ("                fi\n");
                    print ("            done\n");
                    print ("            COMPREPLY=( $(compgen -W \"\$available\" -- \"\$suffix\") )\n");
                    print ("            for i in \"${!COMPREPLY[@]}\"; do\n");
                    print ("                if [[ \$available_count -gt 1 ]]; then\n");
                    print ("                    COMPREPLY[i]=\"${prefix}\${COMPREPLY[i]},\"\n");
                    print ("                else\n");
                    print ("                    COMPREPLY[i]=\"${prefix}\${COMPREPLY[i]}\"\n");
                    print ("                fi\n");
                    print ("            done\n");
                    break;
                case "installer":
                    print ("            COMPREPLY=( $(compgen -W \"${installers}\" -- \"${cur}\") )\n");
                    break;
                case "conf-file":
                    print ("            _filedir\n");
                    break;
                default:
                    print ("            return\n");
                    break;
            }

            print ("            ;;\n");
        }

        print ("    esac\n\n");
        print ("    commands=\"generate-bash-completion\"\n\n");
        print ("    if [[ ${cur} == -* ]]; then\n");
        print ("        COMPREPLY=( $(compgen -W \"${opts}\" -- \"${cur}\") )\n");
        print ("        return\n");
        print ("    fi\n\n");
        print ("    if [[ ${COMP_CWORD} -eq 1 ]]; then\n");
        print ("        if [[ -z ${cur} ]]; then\n");
        print ("            COMPREPLY=( $(compgen -W \"${commands} ${opts}\" -- \"${cur}\") )\n");
        print ("        else\n");
        print ("            COMPREPLY=( $(compgen -W \"${commands}\" -- \"${cur}\") )\n");
        print ("        fi\n");
        print ("        return\n");
        print ("    fi\n");
        print ("}\n\n");
        print ("complete -F _ready_set ready-set\n");
    }
}
