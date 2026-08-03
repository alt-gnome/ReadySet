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

[DBus (name = "org.altlinux.ReadySet.SoftwareSources")]
public interface Software.Service : Object {
    public async abstract void add_stplr_repo (string remote_name, string url) throws Error;

    public async abstract void remove_stplr_repo (string remote_name) throws Error;

    public async abstract void add_alt_repos (string[] repos) throws Error;

    public async abstract void remove_alt_repos (string[] repos) throws Error;

    public async abstract void exec_custom (string cmd) throws Error;
}

public sealed class Software.StplrRepo : Serialize.DataObject {

    public string name { get; set; }

    public string url { get; set; }
}

public sealed class Software.ApmRepo : Serialize.DataObject {

    public string entry { get; set; }
}

namespace Software {

    public async Software.Service get_proxy () throws Error {
        var con = yield Bus.get (BusType.SYSTEM);

        if (con == null) {
            error ("Failed to connect to bus");
        }

        return con.get_proxy_sync<Software.Service> (
            "org.altlinux.ReadySet",
            "/org/altlinux/ReadySet/SoftwareSources",
            DBusProxyFlags.NONE
        );
    }

    Sources sources;

    public Sources get_sources (string? sources_dir = null) {
        if (sources == null) {
            assert (sources_dir != null);

            var sources_data = new SourcesData ();

            Dir dir;
            try {
                dir = Dir.open (sources_dir);
            } catch (Error e) {
                error ("Failed to read %s dir: %s", sources_dir, e.message);
            }
            string name;
            while ((name = dir.read_name ()) != null) {
                if (name.has_suffix (".yml") || name.has_suffix (".yaml")) {
                    var file = Path.build_filename (sources_dir, name);
                    try {
                        string content;
                        FileUtils.get_contents (file, out content);

                        var tsources_data = Serialize.YamlWorker.simple_from_yaml<SourcesData> (content);
                        sources_data.groups.add_all (tsources_data.groups);
                        sources_data.sources.add_all (tsources_data.sources);

                    } catch (Error e) {
                        warning (
                            "Failed to read software sources config %s: %s",
                            file,
                            e.message
                        );
                    }
                }
            }

            sources = new Sources (sources_data);
        }

        return sources;
    }
}
