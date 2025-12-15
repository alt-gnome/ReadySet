/*
 * Copyright (C) 2025 Vladimir Romanov <rirusha@altlinux.org>
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

[GtkTemplate (ui = "/space/rirusha/ReadySet/ui/input-row.ui")]
public sealed class ReadySet.InputRow : Adw.ActionRow {

    public InputInfo input_info { get; construct; }

    public bool is_extra { get; construct set; }

    public new bool is_selected { get; set; }

    public InputRow (InputInfo input_info, string name, bool is_extra) {
        Object (
            input_info: input_info,
            title: name,
            is_extra: is_extra
        );
    }
}
