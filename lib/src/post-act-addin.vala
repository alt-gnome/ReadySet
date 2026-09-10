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
 * Base class for plugins that perform actions after the ReadySet workflow.
 *
 * Post-act plugins receive the completed configuration context and may request
 * that the application window remain open by returning an appropriate status
 * flag.
 */
public abstract class ReadySet.PostActAddin : Peas.ExtensionBase {

    /**
     * Performs the plugin's post-workflow action.
     *
     * @param context the completed ReadySet configuration context
     * @return status flags that control post-act handling
     * @throws GLib.Error when the action cannot be completed
     */
    public abstract async PostActStatusFlags run (Context context) throws Error;
}
