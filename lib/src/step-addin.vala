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
 * Base class for plugin that provides `step`.
 *
 * What is `step`?
 *
 * This class provides a page or series of pages that serve as a "step"
 * to set up the current session (for initial setup, tour modes) or to
 * save settings for future use (initial-setup with
 * {@link ReadySet.StepAddin.apply} or installer with
 * {@link ReadySet.InstallerAddin.install}).
 *
 * == Using gresource ==
 * 
 * If you using gresource, you should override {@link ReadySet.StepAddin.resource_base_path}
 * and return your base path as get method. `style.css` will be loaded
 * from resource if file with this name exists.
 *
 * Example:
 * {{{
 *  protected override string? resource_base_path {
 *      get {
 *          return "/com/example/MyPlugin/";
 *      }
 *  }
 * }}}
 *
 * == Acessible ==
 *
 * If necessary, you can hide entire plugin via {@link ReadySet.StepAddin.accessible}
 * or pages separately via {@link ReadySet.BasePage.acessible} if your plugin
 * is in unsuitable conditions for work (there are no permissions to perform
 * actions, there are not enough executable files in the system, or a
 * different desktop environment).
 *
 * The acessibility of your plugin can be changed by other plugins. For each
 * plugin, a context variable `step-<step-id>-enabled` is created (the step id
 * is determined by the `Module` field in the plugin file), which bind with
 * the property.
 *
 * == Context ==
 * 
 * {@link ReadySet.Context} is a way of communicating between plugins or an
 * application.
 *
 * {@link ReadySet.StepAddin.context} set somewhere at application
 * initialization. It seting after construction and before
 * {@link ReadySet.StepAddin.init_once}. It's an program error try to call to 
 * context before it set.
 *
 * == Dependencies ==
 *
 * You can describe plugins dependencies in .plugin file. The application will
 * check that all dependencies are queued up to the current plugin.
 * Otherwise error will be thrown and application will be aborted. 
 *
 * Example:
 * {{{
 *  [Plugin]
 *  Name=Cool Plugin
 *  Depends=language,keyboard
 *  Module=cool-plugin
 *  Version=0.1.0
 *  Authors=David Hacker
 * }}}
 *
 * @see ReadySet.BasePage
 * @see ReadySet.InstallerAddin
 */
public abstract class ReadySet.StepAddin : Peas.ExtensionBase {

    protected virtual string? resource_base_path {
        get {
            return null;
        }
    }

    /**
     * Whether `step` accessible or not.
     *
     * @see ReadySet.StepAddin
     */
    public virtual bool accessible { get; set; default = true; }

    Context _context;
    /**
     * A way of communicating between plugins or an application.
     * 
     * @see ReadySet.StepAddin
     */
    public Context context {
        get {
            assert (_context != null);
            return _context;
        }
        set {
            _context = context;
        }
    }

    /**
     * Tries to find `style.css` at gresource and load for
     * `display`. You don't need to call it manually, application do
     * it by itself.
     */
    public void load_css_for_display (Gdk.Display display) {
        var provider = new Gtk.CssProvider ();
        if (resource_base_path != null) {
            try {
                var bytes = resources_lookup_data (
                    Path.build_filename (resource_base_path, "style.css"),
                    ResourceLookupFlags.NONE
                );

                provider = new Gtk.CssProvider ();
                provider.load_from_bytes (bytes);
                Gtk.StyleContext.add_provider_for_display (display, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            } catch (Error e) {
                debug ("style.css doesn't provides by resources");
            }
        }
    }

    /**
     * Apply for initial setup.
     */
    public async virtual void apply (ReadySet.ProgressData progres_data) throws ReadySet.ApplyError {}

    /**
     * Build pages for application.
     */
    public async abstract BasePage[] build_pages ();

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
