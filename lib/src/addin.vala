/*
 * Copyright (C) 2025 Vladimir Romanov <rirusha@altlinux.org>
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

public abstract class ReadySet.Addin : Peas.ExtensionBase, Applyable {

    public string start_apply_message { get; set; default = _("Applying changes…"); }

    protected virtual string? resource_base_path {
        get {
            return null;
        }
    }

    public virtual bool accessible {
        get {
            return true;
        }
        protected set {
            return;
        }
    }

    public Context context { get; set; default = new Context (true); }

    public void load_css_for_display (Gdk.Display display) {
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/org/altlinux/ReadySet/Lib/style.css");
        Gtk.StyleContext.add_provider_for_display (display, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

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

    public async virtual void apply (ReadySet.ProgressData progres_data) throws ReadySet.ApplyError {
        return;
    }

    public abstract BaseBarePage[] build_pages ();

    //  After context set action. Calls once. Calls before init
    public virtual void init_once () {
        return;
    }

    //  For plugins better to use base.get_context_vars for getting empty HashTable.
    public virtual HashTable<string, ContextVarInfo> get_context_vars () {
        var vars = new HashTable<string, ContextVarInfo> (str_hash, str_equal);
        return vars;
    }
}
