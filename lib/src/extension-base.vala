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

    /**
     * Base path of this extension's compiled resources.
     *
     * Override this property when the extension ships a gresource bundle.
     * The application uses the path to load extension resources, including a
     * `style.css` file when one is present. The default value is `null`, which
     * means that the extension does not provide a resource base path.
     */
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
     * Initializes the extension after {@link ExtensionBase.context} is set.
     *
     * This hook is called before values from configuration and command-line
     * options are applied to the context.
     */
    public virtual void init_context () {}

    /**
     * Initializes the extension after initial configuration and command-line
     * option values have been applied to the context.
     */
    public virtual void init () {}

    /**
     * Returns the context variables provided by this extension.
     *
     * Override this method and add entries to the table returned by the base
     * implementation:
     * {{{
     * var vars = base.get_context_vars ();
     * vars["enabled"] = new ContextVarInfo (ContextType.BOOLEAN, true);
     * return vars;
     * }}}
     *
     * The application registers the returned variables under the extension's
     * module name. The default implementation returns a new empty table.
     *
     * @return a newly allocated table of variable names and their metadata
     */
    public virtual HashTable<string, ContextVarInfo> get_context_vars () {
        var vars = new HashTable<string, ContextVarInfo> (str_hash, str_equal);
        return vars;
    }
}
