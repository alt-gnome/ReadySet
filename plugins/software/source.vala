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

public errordomain Software.SourceError {
    COMMON,
    CANCELLED
}

public Software.SourceError source_error_from_error (Error e, string common_message) {
    if (e.matches (GLib.DBusError.quark (), GLib.DBusError.ACCESS_DENIED)) {
        return new Software.SourceError.CANCELLED (e.message);
    }

    return new Software.SourceError.COMMON (common_message);
}

public partial class Software.Source : Deser.DataObject {

    public bool good_type () {
        switch (type_) {
            case "flatpak":
                var flatpak_source = (SourceFlatpak) this;
                if (flatpak_source.body == null ||
                    flatpak_source.body.url == null ||
                    flatpak_source.body.repo_url == null ||
                    flatpak_source.body.remote_name == null
                ) {
                    warning (
                        "Invalid flatpak software source '%s': body requires url, repo-url and remote-name",
                        id
                    );
                    return false;
                }

                return true;
            case "stplr":
                return Program.exists ("stplr");
            case "alt-repo":
                return Program.exists ("apm") || Program.exists ("apt-repo");
            case "custom":
                return true;
            default:
                assert_not_reached ();
        }
    }

    public string id { get; set; }

    [Description (nick="type")]
    public string type_ { get; set; }

    public string name { get; set; }

    public string description { get; set; }

    public string gettext_domain { get; set; }

    public string group { get; set; }

    public bool nonfree { get; set; }

    public async virtual void apply () throws Error {
        assert_not_reached ();
    }

    public virtual bool check () {
        assert_not_reached ();
    }
}

public class Software.SourceRemote : Source {

    public sealed class Body : Object {
        public string url { get; set; }

        public string repo_url { get; set; }

        public string remote_name { get; set; }
    }

    public Body body { get; set; }
}

public partial sealed class Software.SourceFlatpak : SourceRemote {
    public async override void apply () throws Error {
        try {
            var proxy = yield get_proxy ();
            yield proxy.add_flatpak_repo (body.remote_name, body.url, body.repo_url);

        } catch (Flatpak.Error e) {
            throw source_error_from_error (
                e,
                _("Failed to add or enable '%s' flatpak remote with name %s: %s").printf (
                    body.url,
                    body.remote_name,
                    e.message
                )
            );
        }
    }

    public override bool check () {
        try {
            var inst = new Flatpak.Installation.system ();
            foreach (var remote in inst.list_remotes ()) {
                if (remote.get_url () == body.repo_url && !remote.get_disabled ()) {
                    return true;
                }
            }

            return false;

        } catch (Error e) {
            warning ("Check error: %s", e.message);
            return false;
        }
    }
}

public partial sealed class Software.SourceStplr : SourceRemote {
    public async override void apply () throws Error {
        try {
            var proxy = yield get_proxy ();
            yield proxy.add_stplr_repo (body.remote_name, body.url);

        } catch (Error e) {
            if (NetworkMonitor.get_default ().get_connectivity () != FULL) {
                //  On bad connection ot will be connected btw
                return;
            }

            throw source_error_from_error (
                e,
                _("Failed to add '%s' stplr repository with name %s: %s").printf (
                    body.url,
                    body.remote_name,
                    e.message
                )
            );
        }
    }

    public override bool check () {
        try {
            var sp = new Subprocess.newv ({
                "stplr", "repo", "list", "--json"
            }, STDOUT_PIPE | STDERR_SILENCE);
            Bytes? buf;
            if (sp.communicate (null, null, out buf, null)) {
                var worker = new Deser.JsonWorker.from_bytes (buf);
                var repos = worker.deserialize_with_codec (Deser.create_codec_for_array<StplrRepo> ());

                foreach (var r in repos) {
                    if (r.name == body.remote_name) {
                        return true;
                    }
                }
            }

            return false;

        } catch (Error e) {
            warning ("Check error: %s", e.message);
            return false;
        }
    }
}

public partial class Software.SourceAltRepo : Source {

    public sealed class Body : Object {
        public string[] repos { get; set; }
    }

    string[] _arched_repos;
    protected string[] arched_repos {
        get {
            if (_arched_repos == null) {
                string[] res = {};
                foreach (var r in body.repos) {
                    res += r.replace (" _arch_ ", " %s ".printf (Config.ARCH));
                }
                _arched_repos = res;
            }

            return _arched_repos;
        }
    }

    public Body body { get; set; }

    public async override void apply () throws Error {
        try {
            var proxy = yield get_proxy ();
            yield proxy.add_alt_repos (arched_repos);

        } catch (Error e) {
            throw source_error_from_error (
                e,
                _("Failed to add apt repository with repos: %s: %s").printf (
                    string.joinv (", ", body.repos),
                    e.message
                )
            );
        }
    }

    public override bool check () {
        try {
            if (Program.exists ("apm")) {
                var sp = new Subprocess.newv ({
                    "apm", "repo", "list", "--full", "--format", "json", "-a"
                }, STDOUT_PIPE | STDERR_SILENCE);
                Bytes? buf;
                if (sp.communicate (null, null, out buf, null)) {
                    var worker = new Deser.JsonWorker.from_bytes (buf);
                    var repos = worker.deserialize_object<ApmRepoResponse> ().data.repositories;

                    uint checked = 0;
                    foreach (var r in repos) {
                        if (r.entry in arched_repos) {
                            checked++;
                        }
                    }

                    return checked == arched_repos.length;
                }
            } else {
                var sp = new Subprocess.newv ({
                    "apt-repo"
                }, STDOUT_PIPE | STDERR_SILENCE);
                string? buf;
                if (sp.communicate_utf8 (null, null, out buf, null)) {
                    var repos = buf.strip ().split ("\n");

                    uint checked = 0;
                    foreach (var r in repos) {
                        if (r in arched_repos) {
                            checked++;
                        }
                    }

                    return checked == arched_repos.length;
                }
            }

            return false;

        } catch (Error e) {
            warning ("Check error: %s", e.message);
            return false;
        }
    }
}

public partial class Software.SourceCustom : Source {

    public sealed class Body : Object {
        public string cmd_apply { get; set; }

        public string cmd_undo { get; set; }

        public string cmd_check { get; set; }
    }

    public Body body { get; set; }

    public async override void apply () throws Error {
        try {
            var proxy = yield get_proxy ();
            yield proxy.exec_custom (body.cmd_apply);

        } catch (Error e) {
            throw source_error_from_error (
                e,
                _("Failed to exec: %s: %s").printf (
                    body.cmd_apply,
                    e.message
                )
            );
        }
    }

    public override bool check () {
        try {
            var sp = new Subprocess.newv ({ "bash", "-c", body.cmd_check }, STDOUT_SILENCE | STDERR_SILENCE);
            sp.wait ();
            return sp.get_exit_status () == 0;

        } catch (Error e) {
            warning ("Check error: %s", e.message);
            return false;
        }
    }
}
