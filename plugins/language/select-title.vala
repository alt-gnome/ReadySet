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

public class Language.SelectTitle : Adw.Bin {

    Gtk.Stack stack;

    construct {
        stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.SLIDE_LEFT
        };
        child = stack;

        var cur_locale = Addin.get_instance ().current_locale;

        append ();

        foreach (var lang in get_supported_languages ()) {
            var locale = fix_locale (lang);
            if (cur_locale != locale) {
                Intl.setlocale (LocaleCategory.MESSAGES, locale);
                append ();
            }
        }

        Intl.setlocale (LocaleCategory.MESSAGES, cur_locale);

        Timeout.add_seconds (3, () => {
            next ();

            return true;
        });
    }

    void append () {
        int num;
        var widget = stack.get_last_child ();

        if (widget == null) {
            num = 0;
        } else {
            num = widget.get_data<int> ("num") + 1;
        }

        var desc = new ReadySet.BasePageDesc (
            _("Hello!"),
            _("Let's start by choosing the language for the application and for your system.")
        ) {
            hexpand = true
        };

        desc.set_data<int> ("num", num);

        stack.add_named (
            desc,
            num.to_string ()
        );
    }

    void next () {
        var last_widget = stack.get_last_child ();

        if (last_widget == null) {
            return;
        }

        Gtk.Widget cur_widget = stack.visible_child;

        var last_num = last_widget.get_data<int> ("num");
        var cur_num = cur_widget.get_data<int> ("num");
        int next_num;

        if (last_num == cur_num) {
            next_num = 0;
        } else {
            next_num = cur_num + 1;
        }

        stack.set_visible_child_name (next_num.to_string ());
    }
}
