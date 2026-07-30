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

namespace Software {

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

    public bool program_exists (string program) {
        return Environment.find_program_in_path (program) != null;
    }
}
