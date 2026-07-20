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
 * Extension base with common logic between
 * {@link ReadySet.InstallerAddin} and 
 * {@link ReadySet.StepAddin}.
 */
public partial abstract class ReadySet.ExtensionBase : Peas.ExtensionBase {

    public virtual string? resource_base_path {
        get {
            return null;
        }
    }

    Context _context;
    /**
     * A way of communicating between plugins or an application.
     * 
     * @see ReadySet.StepAddin
     * @see ReadySet.Context
     */
    public Context context {
        get {
            assert (_context != null);
            return _context;
        }
        internal set {
            _context = value;
        }
    }

    /**
     * Init plugin. Calls by application after context was set.
     * Calls once.
     */
    public async virtual void init_once () {}

    /**
     * Get context variables for registration. Calls by application.
     * Better to this for getting created {@link HashTable}.
     * {{{
     *  base.get_context_vars ()
     * }}}
     *
     */
    public virtual HashTable<string, ContextVarInfo> get_context_vars () {
        var vars = new HashTable<string, ContextVarInfo> (str_hash, str_equal);
        return vars;
    }
}
