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
 * Declares whether a step is available in existing-user mode.
 *
 * Step plugins that do not implement this interface are treated as returning
 * {@link ReadySet.ExistingUserStatus.NO}.
 */
public interface ReadySet.ExistingUser : StepAddin {

    /**
     * Returns the policy for showing this step in existing-user mode.
     *
     * The default implementation returns
     * {@link ReadySet.ExistingUserStatus.IF_NOT_PASSED}, so the step is shown
     * only when it is absent from the performed-steps list.
     *
     * @return the existing-user availability policy
     */
    public virtual ExistingUserStatus get_existing_user () {
        return IF_NOT_PASSED;
    }
}
