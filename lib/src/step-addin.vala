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
 * to set up the current session (for initial setup or existing-user modes) or to
 * save settings for future use (initial-setup with
 * {@link ReadySet.StepAddin.apply} or installer with
 * {@link ReadySet.InstallerAddin.install}).
 *
 * == Using gresource ==
 *
 * If you using gresource, you should override {@link ReadySet.ExtensionBase.resource_base_path}
 * and return your base path as get method. `style.css` will be loaded
 * from resource if file with this name exists.
 *
 * Example:
 * {{{
 *  public override string? resource_base_path {
 *      get {
 *          return "/com/example/MyPlugin/";
 *      }
 *  }
 * }}}
 *
 * == Enabling ==
 *
 * If necessary, you can disable entire plugin via {@link ReadySet.StepAddin.enabled}
 * or pages separately via {@link ReadySet.BasePage.accessible} if your plugin
 * is in unsuitable conditions for work (there are no permissions to perform
 * actions, there are not enough executable files in the system, or a
 * different desktop environment).
 *
 * The enabling of your plugin can be changed by other plugins. For each
 * plugin, a context variable `steps.<step-id>.enabled` is created (the step id
 * is determined by the `Module` field in the plugin file), which bind with
 * the {@link ReadySet.StepAddin.enabled} property.
 *
 * == Context ==
 *
 * {@link ReadySet.Context} is a way of communicating between plugins or an
 * application.
 *
 * The application assigns {@link ReadySet.ExtensionBase.context} after
 * construction. It then calls {@link ReadySet.ExtensionBase.init_context},
 * applies initial configuration and command-line values, and calls
 * {@link ReadySet.ExtensionBase.init}. Accessing the context before it is
 * assigned is a programming error.
 *
 *
 * @see ReadySet.BasePage
 * @see ReadySet.InstallerAddin
 */
public abstract class ReadySet.StepAddin : ExtensionBase {

    /**
     * Module name used as the namespace for context variable registration.
     *
     * Override this when plugins expose similar context variables under
     * different module names, for example `user-passwdqc` and
     * `user-pwquality`.
     */
    public virtual string plugin_name { get { return plugin_info.module_name; } }

    /**
     * Whether this step is enabled.
     *
     * Disabled steps and their pages are excluded from the workflow.
     * Also plugin will not be applyed at the end.
     */
    public virtual bool enabled { get; set; default = true; }

    /**
     * Applies this step asynchronously during initial setup.
     *
     * The default implementation completes without making changes. Override
     * it to persist the settings collected by the step, updating
     * `progres_data` as the operation proceeds.
     *
     * @param progres_data mutable progress information for the operation
     * @throws ReadySet.ApplyError when the step cannot be applied
     */
    public async virtual void apply (ReadySet.ProgressData progres_data) throws ReadySet.ApplyError {}

    /**
     * Builds the pages contributed by this step.
     *
     * The default implementation returns an empty array.
     *
     * @return the pages to add to the application workflow
     */
    public async virtual BasePage[] build_pages () {
        return {};
    }
}
