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

public sealed class ReadySet.EndPageFactory : Object {

    public Context context { get; construct; }

    public FinalizerFactory finalizer_factory { get; construct; }

    public EndPageFactory (Context context, FinalizerFactory finalizer_factory) {
        Object (context: context, finalizer_factory: finalizer_factory);
    }

    public EndPage build () {
        EndPage page;

        switch (context.mode) {
            case EXISTING_USER:
                page = new ExistingUserEndPage ();
                break;
            case INITIAL_SETUP:
                page = new InitialSetupEndPage ();
                break;
            case INSTALLER:
                page = new InstallerEndPage ();
                break;
            default:
                assert_not_reached ();
        }

        page.finalizer = finalizer_factory.build ();
        page.sandbox = context.sandbox;

        return page;
    }
}

public abstract class ReadySet.EndPage : Adw.Bin {

    public Finalizer finalizer { get; set; }

    public bool sandbox { get; set; }

    public abstract async void start_action ();

    public virtual bool can_go_prev () {
        return false;
    }
}
