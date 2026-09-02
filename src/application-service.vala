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

public sealed class ReadySet.ApplicationService : Object {

    public bool has_installer {
        get {
            return options_handler.installer != null;
        }
    }

    InstallerAddin? installer_plugin {
        owned get {
            if (!has_installer) {
                return null;
            }

            return plugin_manager.get_installer_plugin ();
        }
    }

    internal PagesModel? model { get; private set; default = null; }

    public OptionsHandler options_handler { get; construct; }

    public PluginManager plugin_manager { get; construct; }

    public Context context { get; construct; }

    public PostAct post_act { get; construct; }

    public FinalizerFactory finalizer_factory { get; private set; }

    public ApplicationService (VariantDict options) {
        var options_handler = new OptionsHandler.from_options (options);
        var context = new Context (options_handler.sandbox);

        Object (
            options_handler: options_handler,
            context: context,
            plugin_manager: new PluginManager (context),
            post_act: new PostAct (context)
        );
    }

    public void init () {
        plugin_manager.init (options_handler.installer, options_handler.steps);

#if DEVEL
        if (options_handler.force_mode == null) {
#endif
            if (installer_plugin != null) {
                context.init_mode (INSTALLER);
            } else if (in_group ("ready-set") || in_group ("gnome-initial-setup")) {
                context.init_mode (INITIAL_SETUP);
            } else {
                context.init_mode (EXISTING_USER);
            }
#if DEVEL
        } else {
            context.init_mode (Mode.from_string (options_handler.force_mode));
        }
#endif

        if (options_handler.apply_only && context.mode == EXISTING_USER) {
            error ("`finalize` can not be used in existing-user mode");
        }

        print ("\nApplication mode: %s\n\n", context.mode.to_string ());
        if (has_installer) {
            print (
                "Installer:\n  %s - %s\n\n",
                installer_plugin.plugin_info.module_name,
                installer_plugin.plugin_info.name
            );
        }

        plugin_manager.check_steps (options_handler.steps);
        if (has_installer) {
            plugin_manager.check_installers ();
        }

        finalizer_factory = new FinalizerFactory (
            context,
            installer_plugin
        );
        bind_property ("model", finalizer_factory, "model", SYNC_CREATE);

        if (!options_handler.sandbox) {
            exec_pre_hooks ();
        }

        if (!options_handler.apply_only) {
            init_lib_css ();
        }
    }

    void exec_pre_hooks () {
        try {
            string hooks_type = "pre";
            string hooks_target;

            if (context.mode == Mode.INITIAL_SETUP) {
                hooks_target = "initial-setup";

                var pre_hooks_dir = get_user_hooks_dir (hooks_type, hooks_target);

                foreach (var name in ReadySet.get_all_hooks_from_dir (pre_hooks_dir)) {
                    ReadySet.real_exec_hook_from_dir (pre_hooks_dir, name);
                }

            } else if (context.mode == Mode.INSTALLER) {
                hooks_target = "installer";
            } else {
                return;
            }

            var service = get_ready_set_proxy_sync ();

            foreach (var name in service.get_all_hooks (hooks_type, hooks_target)) {
                service.exec_hook (hooks_type, hooks_target, name);
            }

        } catch (Error e) {
            warning ("Error on executing pre hooks: %s", e.message);
        }
    }

    public async bool init_model () {
        return yield build_model ();
    }

    async bool build_model (bool ntd_only = false) {
        var pages = new Gee.ArrayList<PageInfo> ();

        var initial_position = model == null ? 0 : model.get_selected ();

        //  It place here bacause build_steps is first async function that called in
        //  Application class and init_steps_once.
        if (!plugin_manager.steps_inited) {
            yield plugin_manager.call_init_once ();
            options_handler.fill_context (context);
        }
        var steps = plugin_manager.steps;

        if (!ntd_only) print ("Loaded steps:\n");
        for (int i = 0; i < steps.length; i++) {
            var addin = plugin_manager.get_step_addin (steps[i]);

            if (addin != null) {
                var addin_pages = yield addin.build_pages ();
                if (addin_pages.length == 0) {
                    pages.add (new PageInfo (
                        null,
                        addin
                    ));

                } else {
                    foreach (var page in addin_pages) {
                        pages.add (new PageInfo (
                            page,
                            addin
                        ));
                    }
                }
                if (!ntd_only) print ("  %s - %s\n", addin.plugin_info.module_name, addin.plugin_info.name);

            } else if (steps[i].has_prefix (PluginManager.INSTALLER_STEP_PREFIX)) {
                var installer_step = installer_plugin.steps[PluginManager.get_real_page_id (steps[i])];
                var installer_page = installer_step.build_page ();
                if (installer_page != null) {
                    pages.add (new PageInfo.pluginless (
                        installer_page,
                        installer_plugin.get_type ().name ()
                    ));
                    if (!ntd_only) print (
                        "  %s%s (from `%s`)\n",
                        PluginManager.get_real_page_id (steps[i]),
                        installer_step.name != null ? " - %s".printf (installer_step.name) : "",
                        installer_plugin.plugin_info.module_name
                    );
                } else {
                    if (!ntd_only) print ("  %s (skipped: failed to build installer page)\n", steps[i]);
                }
            } else {
                error ("Unknown step `%s`", steps[i]);
            }

            Idle.add (build_model.callback);
            yield;
        }

        if (ntd_only) {
             var res = check_nothing_to_do (pages.to_array ()) && context.mode == EXISTING_USER;
             print ("%i\n", res ? 0 : 1);
             return false;
        }

        if (context.mode == EXISTING_USER) {
            if (check_nothing_to_do (pages.to_array ())) {
                print ("There is nothing to do\n");
                return false;
            }
        }

        if (pages[0].plugin == null || !(pages[0].plugin is Welcome) || context.mode == EXISTING_USER) {
            pages.insert (0, new PageInfo.builtin (
                new WelcomePage (context.mode)
            ));
        }

        if (context.mode == INSTALLER) {
            pages.add (new PageInfo.builtin (
                new SummaryPage (context)
            ));
        }

        model = new PagesModel (pages);
        model.select_item (initial_position, true);

        return true;
    }

    bool check_nothing_to_do (PageInfo[] pages) {
        var settings = new Settings ("org.altlinux.ReadySet");
        if (!settings.get_boolean ("existing-user-mode-enabled")) {
            return true;
        }

        PageInfo[] layout_pages = {};

        foreach (var p in pages) {
            if (p.should_layout) {
                layout_pages += p;
            }
        }

        return layout_pages.length == 0;
    }

    public async bool is_ntd () {
        return yield build_model (true);
    }
}
