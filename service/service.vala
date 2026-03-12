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

[DBus (name = "org.altlinux.ReadySet")]
public sealed class ReadySet.Service : Object {

    public void exec_pre_hooks (string[] env, BusName sender) throws Error {
        polkit_check (sender, "org.altlinux.ReadySet.ExecPreHooks");

        exec_user_pre_hooks (env);
    }

    public void exec_post_hooks (string[] env, BusName sender) throws Error {
        polkit_check (sender, "org.altlinux.ReadySet.ExecPostHooks");

        exec_user_post_hooks (env);
    }
}
