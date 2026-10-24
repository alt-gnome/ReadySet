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
 * Adds ordering constraints to a step plugin.
 *
 * Implement this interface when the step must be applied after specific
 * other step modules.
 */
public interface ReadySet.ApplyAfter : StepAddin {

    /**
     * Returns module identifiers that must be applied before this step.
     *
     * Identifiers that do not refer to loaded step modules are ignored.
     *
     * @return the module identifiers this step depends on
     */
    public abstract string[] get_apply_after ();
}
