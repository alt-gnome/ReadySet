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

public sealed class ReadySet.FinalizerFactory : Object {

    public Context context { get; construct; }

    public PagesModel model { get; set; }

    public InstallerAddin? installer_plugin { get; construct; default = null; }

    public FinalizerFactory (
        Context context,
        InstallerAddin? installer_plugin
    ) {
        Object (
            context: context,
            installer_plugin: installer_plugin
        );
    }

    public Finalizer build () {
        Finalizer finalizer;

        switch (context.mode) {
            case EXISTING_USER:
                finalizer = new ExistingUserFinalizer ();
                break;
            case INITIAL_SETUP:
                finalizer = new InitialSetupFinalizer ();
                break;
            case INSTALLER:
                finalizer = new InstallerFinalizer ();
                break;
            default:
                assert_not_reached ();
        }

        finalizer.context = context;
        finalizer.model = model;
        finalizer.installer_plugin = installer_plugin;

        return finalizer;
    }
}

public abstract class ReadySet.Finalizer : Object {

    public Context context { get; set; }

    public PagesModel model { get; set; }

    public InstallerAddin? installer_plugin { get; set; }

    public abstract async void run (ProgressData progress_data = new ProgressData ()) throws ApplyError;
}
