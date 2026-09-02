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

public sealed class ReadySet.CommandHandler : Object {

    public const string BASH_COMP = "generate-bash-completion";
    public const string NTD = "nothing-to-do";

    public const string[] ALL = {
        BASH_COMP,
        NTD,
    };

    string[] initial_args;

    public string? command { get; private set; default = null; }

    public string[] args { get; private set; }

    public CommandHandler (string[] args) {
        initial_args = args;
    }

    public void parse () {
        assert (initial_args != null);
        assert (initial_args.length != 0);

        if (initial_args.length == 1) {
            args = initial_args.copy ();
        }

        var program = initial_args[0];
        if (!initial_args[1].has_prefix ("-")) {
            command = initial_args[1];
        }

        if (command != null) {
            if (!(command in ALL)) {
                error ("Unknown command: %s", command);
            }
        }

        var builder = new StrvBuilder ();
        builder.add (program);
        builder.addv (initial_args[command == null ? 1 : 2:]);
        args = builder.end ();
    }

    public static string build_summary () {
        var builder = new StrvBuilder ();
        builder.add (_("Commands"));
        foreach (var cmd in ALL) {
            var line_builder = new StringBuilder ();
            line_builder.append ("  ");
            line_builder.append (efill (cmd, 30));
            line_builder.append ("  ");
            switch (cmd) {
                case BASH_COMP:
                    line_builder.append (_("Generate bash completion script"));
                    break;
                case NTD:
                    line_builder.append (_("Print 0 if nothing to do else 1 to stderr"));
                    break;
            }
            builder.add (line_builder.free_and_steal ());
        }
        return string.joinv ("\n", builder.end ());
    }

    static string efill (string in, int width) {
        if (in.length >= width) {
            return in;
        }
        var add = new char[width - in.length];
        for (int i = 0; i < add.length; i++) {
            add[i] = ' ';
        }
        return in + (string) add;
    }
}
