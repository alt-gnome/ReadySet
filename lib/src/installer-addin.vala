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
 * Base class for plugins that implement installation logic.
 *
 * Override {@link ReadySet.InstallerAddin.install} to perform installation.
 * Optional installer pages can be exposed through
 * {@link ReadySet.InstallerAddin.steps}; regular workflow pages are provided
 * by {@link ReadySet.StepAddin} plugins.
 *
 * == Context ==
 *
 * The application assigns {@link ReadySet.ExtensionBase.context} after
 * construction. It then calls {@link ReadySet.ExtensionBase.init_context},
 * applies initial configuration and command-line values, and calls
 * {@link ReadySet.ExtensionBase.init}. Accessing the context before it is
 * assigned is a programming error.
 *
 * @see ReadySet.StepAddin
 */
public partial abstract class ReadySet.InstallerAddin : ExtensionBase {

    /**
     * Installer steps provided by this plugin, indexed by step identifier.
     *
     * The application uses each {@link ReadySet.InstallerStep} to build a
     * page when that identifier is selected. The default implementation
     * returns a new empty table.
     */
    public virtual HashTable<string, InstallerStep> steps {
        owned get {
            return new HashTable<string, InstallerStep> (str_hash, str_equal);
        }
    }

    /**
     * Performs the installation asynchronously.
     *
     * The application calls this method from its finish page. Update
     * `progres_data` to report a progress value from `0.0` to `1.0` and a
     * current status message.
     */
    public async abstract void install (ReadySet.ProgressData progres_data) throws ReadySet.ApplyError;
}
