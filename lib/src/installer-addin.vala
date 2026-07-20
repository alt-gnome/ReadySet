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

/**
 * Base class for plugin that provides installed logic via
 * {@link ReadySet.InstallerAddin.install}.
 *
 * If you need additional pages for installer, you need to create step plugin
 * with {@link ReadySet.StepAddin}.
 *
 * == Context ==
 * 
 * {@link ReadySet.Context} is a way of communicating between plugins or an
 * application.
 *
 * {@link ReadySet.ExtensionBase.context} set somewhere at application
 * initialization. It seting after construction and before
 * {@link ReadySet.ExtensionBase.init_once}. It's an program error try to call to 
 * context before it set.
 *
 * @see ReadySet.StepAddin
 */
public partial abstract class ReadySet.InstallerAddin : ExtensionBase {

    /**
     * All available pages that can be built via
     * {@link ReadySet.InstallerAddin.build_page}.
     */
    public virtual string[] all_pages {
        owned get {
            return {};
        }
    }

    /**
     * Install logic. Calls on finish page in the application.
     * You can control progress indicator via `progress_data`.
     */
    public async abstract void install (ReadySet.ProgressData progres_data) throws ReadySet.ApplyError;

    /**
     * Build page for application for given id.
     * Returns {@link ReadySet.BasePage} for given id. It can be
     * accessed in steps list as `installer-<step-id>`.
     */
    public virtual BasePage? build_page (string id) {
        return null;
    }
}
