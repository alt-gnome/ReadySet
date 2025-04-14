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

public sealed class ReadySet.Result : Object {

    public string current_language { get; set; }

    public Gee.HashSet<InputInfo> current_inputs_info {
        get; set;
        default = new Gee.HashSet<InputInfo> (InputInfo.hash, InputInfo.equal);
    }

    static ReadySet.Result instance;

    public static ReadySet.Result get_instance () {
        if (instance == null) {
            instance = new ReadySet.Result ();
        }

        return instance;
    }
}
