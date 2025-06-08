/*
 * Copyright (C) 2025 Vladimir Vaskov <rirusha@altlinux.org>
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

public class ReadySet.LanguageData : Object {

    public string? current_language { get; set; }
}

public class ReadySet.KeyboardData : Object {

    public Gee.HashSet<InputInfo> current_inputs_info {
        get; set;
        default = new Gee.HashSet<InputInfo> (InputInfo.hash, InputInfo.equal);
    }
}

public class ReadySet.UserData : Object {

    public string fullname { get; set; default = ""; }

    public string username { get; set; default = ""; }

    public string password { get; set; default = ""; }

    public string repeat_password { get; set; default = ""; }

    public bool equal_to_root { get; set; default = true; }

    public string root_password { get; set; default = ""; }

    public string repeat_root_password { get; set; default = ""; }
}

public sealed class ReadySet.Data : Object {

    public LanguageData language { get; default = new LanguageData (); }

    public KeyboardData keyboard { get; default = new KeyboardData (); }

    public UserData user { get; default = new UserData (); }

    static ReadySet.Data instance;

    public static ReadySet.Data get_instance () {
        if (instance == null) {
            instance = new ReadySet.Data ();
        }

        return instance;
    }
}
