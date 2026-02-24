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

namespace ReadySet {

    [DBus (name = "org.altlinux.ReadySet")]
    public interface Service : Object {

        public abstract void exec_pre_hooks (
            string[] env = {}
        ) throws Error;

        public abstract void exec_post_hooks (
            string[] env = {}
        ) throws Error;
    }

    Service proxy;

    public Service get_ready_set_proxy () throws Error {
        if (proxy == null) {
            var con = Bus.get_sync (BusType.SYSTEM);

            if (con == null) {
                error ("Failed to connect to bus");
            }

            proxy = con.get_proxy_sync<Service> (
                "org.altlinux.ReadySet",
                "/org/altlinux/ReadySet",
                DBusProxyFlags.NONE
            );
        }

        return proxy;
    }

    public string context_key_to_env_key (string key) {
        var builder = new StringBuilder ();

        int next_index = 0;
        unichar c;

        while (key.get_next_char (ref next_index, out c)) {
            if (c == '-') {
                builder.append_unichar ('_');
            } else {
                builder.append_unichar (c.toupper ());
            }
        }

        return "READY_SET_CONTEXT_%s" + builder.free_and_steal ();
    }

    public const string STEP_ID_LABEL = "step-id";

    public delegate Gtk.Widget CreateFunc (PageInfo page);

    public bool env_exec (string program, string[] env) throws Error {
        var launcher = new SubprocessLauncher (NONE);
        launcher.set_environ (env);

        var process = launcher.spawn (program);

        return process.wait_check ();
    }

    public void exec_user_pre_hooks (string[] env = {}) throws Error {
        exec_hooks (File.new_build_filename (Config.DATADIR, Config.NAME, "pre-hooks", "user"), env);
    }

    public void exec_user_post_hooks (string[] env) throws Error {
        exec_hooks (File.new_build_filename (Config.DATADIR, Config.NAME, "post-hooks", "user"), env);
    }

    void exec_hooks (File hooks_dir, string[] env) throws Error {
        var enumerator = hooks_dir.enumerate_children (
            "%s,%s,%s".printf (
                FileAttribute.STANDARD_NAME,
                FileAttribute.STANDARD_TYPE,
                FileAttribute.ACCESS_CAN_EXECUTE
            ),
            NONE
        );

        if (enumerator == null) {
            return;
        }

        FileInfo? info;
        while ((info = enumerator.next_file ()) != null) {
            var type_ = info.get_file_type ();
            if (type_ != FileType.REGULAR) {
                continue;
            }

            var script = Path.build_filename (hooks_dir.get_path (), info.get_name ());

            env_exec (script, env);
        }
    }
}
