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

[DBus (name = "org.altlinux.ReadySet.SoftwareSources")]
public sealed class SoftwareSources.Service : Object {

    const string SOFTWARE_ACTION = "org.altlinux.ReadySet.Software.ManageRepos";

    public void add_flatpak_repo (string remote_name, string url, BusName sender) throws Error {
        ReadySetService.polkit_check (sender, SOFTWARE_ACTION);

        var inst = new Flatpak.Installation.system ();

        Flatpak.Remote? remote = null;
        try {
            remote = inst.get_remote_by_name (remote_name);
        } catch (Flatpak.Error e) {
            if (e.code != Flatpak.Error.REMOTE_NOT_FOUND) {
                throw e;
            }
        }

        var session = new ApiBase.Session ();
        var request = new ApiBase.Request.GET (url);
        var data = session.send_and_read (request);

        var new_remote = new Flatpak.Remote.from_file (remote_name, data);
        new_remote.set_gpg_verify (true);

        if (remote != null) {
            remote.set_disabled (false);
            inst.modify_remote (remote);
            inst.modify_remote (new_remote);
        } else {
            inst.add_remote (new_remote, false);
        }
    }

    public void remove_flatpak_repo (string remote_name, BusName sender) throws Error {
        ReadySetService.polkit_check (sender, SOFTWARE_ACTION);

        var inst = new Flatpak.Installation.system ();

        Flatpak.Remote? remote = null;
        try {
            remote = inst.get_remote_by_name (remote_name);
        } catch (Flatpak.Error e) {
            if (e.code != Flatpak.Error.REMOTE_NOT_FOUND) {
                throw e;
            }
        }

        if (remote != null) {
            remote.set_disabled (true);
            inst.modify_remote (remote);
        }
    }

    public void add_stplr_repo (string remote_name, string url, BusName sender) throws Error {
        ReadySetService.polkit_check (sender, SOFTWARE_ACTION);

        var sp = new Subprocess.newv ({
            "stplr", "repo", "add", remote_name, url
        }, STDOUT_SILENCE | STDERR_SILENCE);
        sp.wait ();
    }

    public void remove_stplr_repo (string remote_name, string url, BusName sender) throws Error {
        ReadySetService.polkit_check (sender, SOFTWARE_ACTION);

        var sp = new Subprocess.newv ({
            "stplr", "repo", "remove", remote_name
        }, STDOUT_SILENCE | STDERR_SILENCE);
        sp.wait ();
    }

    public void add_alt_repos (string[] repos, BusName sender) throws Error {
        ReadySetService.polkit_check (sender, SOFTWARE_ACTION);

        string[] cmd;
        if (Program.exists ("apm")) {
            cmd = { "apm", "repo" };
        } else {
            cmd = { "apt-repo" };
        }

        cmd += "add";

        string[] str_cmds = {};
        foreach (var r in repos) {
            var cmdp = cmd.copy ();
            cmdp += r;
            str_cmds += string.joinv (" ", cmdp);
        }

        var sp = new Subprocess.newv ({
            "bash", "-c", string.joinv (" && ", str_cmds)
        }, STDOUT_SILENCE | STDERR_SILENCE);
        sp.wait ();
    }

    public void remove_alt_repos (string[] repos, BusName sender) throws Error {
        ReadySetService.polkit_check (sender, SOFTWARE_ACTION);

        string[] cmd;
        if (Program.exists ("apm")) {
            cmd = { "apm", "repo" };
        } else {
            cmd = { "apt-repo" };
        }

        cmd += "rm";

        string[] str_cmds = {};
        foreach (var r in repos) {
            var cmdp = cmd.copy ();
            cmdp += r;
            str_cmds += string.joinv (" ", cmdp);
        }

        var sp = new Subprocess.newv ({
            "bash", "-c", string.joinv (" && ", str_cmds)
        }, STDOUT_SILENCE | STDERR_SILENCE);
        sp.wait ();
    }

    public void exec_custom (string cmd, BusName sender) throws Error {
        ReadySetService.polkit_check (sender, SOFTWARE_ACTION);

        var sp = new Subprocess.newv ({
            "bash", "-c", cmd
        }, STDOUT_SILENCE | STDERR_SILENCE);
        sp.wait ();
    }
}

public sealed class SoftwareSources.Addin : ReadySetService.Addin {

    public override string get_object_path () {
        return "/SoftwareSources";
    }

    public override void register_service (DBusConnection conn, string path) throws GLib.IOError {
        conn.register_object (path, new SoftwareSources.Service ());
    }
}

public void peas_register_types (TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type (typeof (ReadySetService.Addin), typeof (SoftwareSources.Addin));
}
