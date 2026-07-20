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

    public string[] get_all_hooks (string type_, string target, BusName sender) throws Error {
        check_type_target (type_, target);
        polkit_check (sender, "org.altlinux.ReadySet.GetAllHooks");

        return get_all_hooks_from_dir (get_system_hooks_dir (type_, target));
    }

    /**
     * type_ - "pre" or "post"
     * target - "initial-setup" or "installer"
     * name - hook name
     */
    public bool exec_hook (string type_, string target, string name, string[] env, BusName sender) throws Error {
        check_type_target (type_, target);
        polkit_check (sender, "org.altlinux.ReadySet.ExecHook");

        return real_exec_hook (type_, target, name, env);
    }

    public void copy_to_user (string src, string dest, string username, BusName sender) throws Error {
        polkit_check (sender, "org.altlinux.ReadySet.CopyToUser");

        ReadySet.copy_to_user (src, dest, username);
    }
}
