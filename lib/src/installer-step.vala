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
 * Describes an optional page supplied by an installer plugin.
 *
 * Instances are exposed through {@link ReadySet.InstallerAddin.steps}; the
 * application uses them to construct the pages selected by its `steps`
 * option.
 */
public abstract class ReadySet.InstallerStep : Object {

    /**
     * Human-readable name of the step shown by command-line interfaces.
     *
     * The default value is `null`.
     */
    public virtual string? name {
        get {
            return null;
        }
    }

    /**
     * Builds the page for this installer step.
     *
     * The application adds the returned page when this step is selected by
     * its `steps` option.
     *
     * @return a newly constructed installer page
     */
    public abstract BasePage build_page ();
}
