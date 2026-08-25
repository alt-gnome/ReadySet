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

/**
 * Object that {@link ReadySet.Context} understand and which
 * can be registered.
 */
public abstract class ReadySet.ContextObject : Object {

    /**
     * Object in string format.
     *
     * You must override getter/setter methods. On getter you must return
     * string representation of object. On setter you must parse string
     * representation of object.
     */
    public abstract string string_format { owned get; set; }

    /**
     * Copy func for {@link ContextObject}.
     */
    public abstract ContextObject copy ();
}
