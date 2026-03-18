/*
 * Copyright (C) 2026 Vladimir Romanov <rirusha@altlinux.org>
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

public sealed class Keyboard.InputSources : ReadySet.ContextObject {

    Gee.ArrayList<InputInfo> data = new Gee.ArrayList<InputInfo> (InputInfo.equal);

    public int size {
        get {
            return data.size;
        }
    }

    public bool contains (InputInfo item) {
        return data.contains (item);
    }

    public InputSources.take (owned InputInfo[] input_infos) {
        this.data.add_all_array (input_infos);
    }

    public void remove (InputInfo input_info) {
        data.remove (input_info);
    }

    public void add (owned InputInfo input_info) {
        if (input_info in data) {
            return;
        }
        data.add (input_info);
    }

    public void add_many (owned InputInfo[] input_infos) {
        foreach (var input_info in input_infos) {
            add (input_info);
        }
    }

    public InputInfo[] to_array () {
        return data.to_array ();
    }

    public void insert_before (InputInfo what, InputInfo where) {
        if (!(where in this)) {
            return;
        }

        remove (what);

        data.insert (data.index_of (where), what);
    }

    public override ReadySet.ContextObject copy () {
        var new_set = new InputSources ();
        new_set.add_many (data.to_array ());
        return new_set;
    }
}
