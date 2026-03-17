/*
 * Copyright (C) 2026 Vladimir Romanov <rirusha@altlinux.org>
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

[CCode (cheader_filename = "xkbcommon/xkbcommon.h", cprefix = "xkb_", lower_case_cprefix = "xkb_")]
namespace Xkb {
    [CCode (cname = "xkb_keycode_t", cheader_filename = "xkbcommon/xkbcommon.h", has_type_id = false)]
    public struct Keycode : uint32 {}

    [CCode (cname = "xkb_keysym_t", cheader_filename = "xkbcommon/xkbcommon.h", has_type_id = false)]
    public struct Keysym : uint32 {}

    [CCode (cname = "xkb_layout_index_t", cheader_filename = "xkbcommon/xkbcommon.h", has_type_id = false)]
    public struct LayoutIndex : uint32 {}

    [CCode (cname = "xkb_level_t", cheader_filename = "xkbcommon/xkbcommon.h", has_type_id = false)]
    public struct Level : uint32 {}

    [CCode (cname = "struct xkb_rule_names", has_type_id = false, destroy_function = "")]
    public struct RulesNames {
        public unowned string? rules;
        public unowned string? model;
        public unowned string? layout;
        public unowned string? variant;
        public unowned string? options;
    }

    [CCode (cname = "struct xkb_context", ref_function = "xkb_context_ref", unref_function = "xkb_context_unref", has_type_id = false)]
    [Compact]
    public class Context {
        [CCode (cname = "xkb_context_new")]
        public Context (Xkb.ContextFlags flags);
    }

    [CCode (cname = "struct xkb_keymap", ref_function = "xkb_keymap_ref", unref_function = "xkb_keymap_unref", has_type_id = false)]
    [Compact]
    public class Keymap {
        [CCode (cname = "xkb_keymap_new_from_names")]
        public static Xkb.Keymap? new_from_names (
            owned Xkb.Context context,
            Xkb.RulesNames? names,
            Xkb.KeymapCompileFlags flags
        );

        [CCode (cname = "xkb_keymap_key_for_each")]
        public void key_for_each (Xkb.KeymapKeyForKeyEachFn fn, void* data);

        [CCode (cname = "xkb_keymap_key_get_syms_by_level")]
        public int key_get_syms_by_level (Xkb.Keycode key, Xkb.LayoutIndex layout, Xkb.Level level, out unowned Xkb.Keysym[] syms);

        [CCode (cname = "xkb_keymap_num_layouts_for_key")]
        public Xkb.LayoutIndex num_layouts_for_key (Xkb.Keycode key);
    }

    [CCode (cname = "struct xkb_state", ref_function = "xkb_state_ref", unref_function = "xkb_state_unref", has_type_id = false)]
    [Compact]
    public class State {
        [CCode (cname = "xkb_state_new")]
        public State (Xkb.Keymap keymap);

        [CCode (cname = "xkb_state_key_get_one_sym")]
        public Xkb.Keysym key_get_one_sym (Xkb.Keycode key);
    }

    [CCode (cname = "enum xkb_context_flags", cprefix = "XKB_CONTEXT_", has_type_id = false)]
    [Flags]
    public enum ContextFlags {
        NO_FLAGS,
        NO_DEFAULT_INCLUDES
    }

    [CCode (cname = "enum xkb_keymap_compile_flags", cprefix = "XKB_KEYMAP_COMPILE_", has_type_id = false)]
    [Flags]
    public enum KeymapCompileFlags {
        NO_FLAGS
    }

    [CCode (has_target = false)]
    public delegate void KeymapKeyForKeyEachFn (Xkb.Keymap keymap, Xkb.Keycode key, void* data);
}
