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
     * Returnes stages of current installer. They can be marked as `passed` via
     * {@link ReadySet.InstallerProgressData.pass_stage} at {@link install} running.
     *
     * This method calls once when installation process begin. But before {@link install}.
     */
    public async abstract InstallerStage[] get_stages ();

    /**
     * Performs the installation asynchronously.
     *
     * The application calls this method from its finish page. Update
     * `progres_data` to report a progress value from `0.0` to `1.0` and a
     * current status message.
     *
     * Example:
     * {{{
     *  ReadySet.InstallerProgressData progress_data;
     *
     *  public async override ReadySet.InstallerStage[] get_stages () {
     *      return yield get_stages_from_backend ();
     *  }
     *
     *  public async override void install (ReadySet.InstallerProgressData progress_data) throws ReadySet.ApplyError {
     *      progress_data.pulse_step = 0.4;
     *
     *      example_backend.progress_data = progress_data;
     *      example_backend.events.connect (handle_events);
     *      yield example_backend.run ();
     *  }
     *
     *  void handle_events (EventData event) {
     *      if (event.type_ == "stage-passed") {
     *          progress_data.pass_stage = event.stage;
     *      } else if (event.type_ == "progress") {
     *          progress_data.value = event.progress;
     *      } else {
     *          progress_data.pulse ();
     *      }
     *  }
     * }}}
     */
    public async abstract void install (ReadySet.InstallerProgressData progress_data) throws ReadySet.ApplyError;
}
