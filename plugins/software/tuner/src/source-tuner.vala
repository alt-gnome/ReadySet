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

public partial class Software.Source {

    public async virtual void undo () throws Error {}

    public virtual bool check () throws Error {
        return true;
    }
}

public partial sealed class Software.SourceFlatpak {

    public async override void undo () throws Error {
        try {
            var inst = new Flatpak.Installation.system ();

            Flatpak.Remote? remote = null;
            try {
                remote = inst.get_remote_by_name (body.remote_name);
            } catch (Flatpak.Error e) {
                if (e.code != Flatpak.Error.REMOTE_NOT_FOUND) {
                    throw e;
                }
            }

            if (remote != null) {
                remote.set_disabled (true);
                inst.modify_remote (remote);
            }

        } catch (Error e) {
            throw source_error_from_error (
                e,
                _("Failed to disable '%s' flatpak remote with name %s: %s").printf (
                    body.url,
                    body.remote_name,
                    e.message
                )
            );
        }
    }

    public override bool check () throws Error {
        try {
            var inst = new Flatpak.Installation.system ();

            Flatpak.Remote? remote = null;
            try {
                remote = inst.get_remote_by_name (body.remote_name);
            } catch (Flatpak.Error e) {
                if (e.code != Flatpak.Error.REMOTE_NOT_FOUND) {
                    throw e;
                }
            }

            return remote != null && !remote.get_disabled ();

        } catch (Error e) {
            throw source_error_from_error (
                e,
                _("Failed to check '%s' flatpak remote with name %s: %s").printf (
                    body.url,
                    body.remote_name,
                    e.message
                )
            );
        }
    }
}

public partial sealed class Software.SourceStplr {

    public async override void undo () throws Error {
        try {
            var proxy = yield get_proxy ();
            yield proxy.remove_stplr_repo (body.remote_name);

        } catch (Error e) {
            throw source_error_from_error (
                e,
                _("Failed to remove '%s' stplr repository with name %s: %s").printf (
                    body.url,
                    body.remote_name,
                    e.message
                )
            );
        }
    }

    public override bool check () throws Error {
        try {
            var sp = new Subprocess.newv ({
                "stplr", "repo", "list", "--json"
            }, STDOUT_PIPE | STDERR_SILENCE);
            Bytes? buf;
            if (sp.communicate (null, null, out buf, null)) {
                var worker = new Serialize.JsonWorker.from_bytes (buf);
                var repos = worker.deserialize_array<ReadySetSoftware.StplrRepo> ();

                foreach (var r in repos) {
                    if (r.name == body.remote_name) {
                        return true;
                    }
                }
            }

            return false;

        } catch (Error e) {
            throw source_error_from_error (
                e,
                _("Failed to check '%s' stplr repository with name %s: %s").printf (
                    body.url,
                    body.remote_name,
                    e.message
                )
            );
        }
    }
}

public partial class Software.SourceAltRepo {

    public async override void undo () throws Error {
        try {
            var proxy = yield get_proxy ();
            yield proxy.remove_alt_repos (arched_repos);

        } catch (Error e) {
            throw source_error_from_error (
                e,
                _("Failed to remove apt repository with repos: %s: %s").printf (
                    string.joinv (", ", body.repos),
                    e.message
                )
            );
        }
    }

    public override bool check () throws Error {
        try {
            if (Program.exists ("apm")) {
                var sp = new Subprocess.newv ({
                    "apm", "repo", "list", "--full", "--format", "json", "-a"
                }, STDOUT_PIPE | STDERR_SILENCE);
                Bytes? buf;
                if (sp.communicate (null, null, out buf, null)) {
                    var worker = new Serialize.JsonWorker.from_bytes (buf, { "data", "repositories" });
                    var repos = worker.deserialize_array<ReadySetSoftware.ApmRepo> ();

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
            throw source_error_from_error (
                e,
                _("Failed to check apt repository with repos: %s: %s").printf (
                    string.joinv (", ", body.repos),
                    e.message
                )
            );
        }
    }
}

public partial class Software.SourceCustom {

    public async override void undo () throws Error {
        try {
            var proxy = yield get_proxy ();
            yield proxy.exec_custom (body.cmd_undo);

        } catch (Error e) {
            throw source_error_from_error (
                e,
                _("Failed to exec: %s: %s").printf (
                    body.cmd_undo,
                    e.message
                )
            );
        }
    }

    public override bool check () throws Error {
        try {
            var sp = new Subprocess.newv ({ "bash", "-c", body.cmd_check }, STDOUT_SILENCE | STDERR_SILENCE);
            sp.wait ();
            return sp.get_exit_status () == 0;

        } catch (Error e) {
            throw source_error_from_error (
                e,
                _("Failed to exec: %s: %s").printf (
                    body.cmd_check,
                    e.message
                )
            );
        }
    }
}
