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
}

public partial sealed class Software.SourceFlatpak {

    public async override void undo () throws Error {
        try {
            var proxy = yield get_proxy ();
            yield proxy.remove_flatpak_repo (body.remote_name);

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
}
