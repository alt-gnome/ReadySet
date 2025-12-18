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

    Adw.Carousel carousel;

    construct {
        carousel = new Adw.Carousel () {
            interactive = false,
            spacing = 24
        };
        child = carousel;

        var cur_locale = get_current_language ();

        Intl.setlocale (LocaleCategory.MESSAGES, fix_locale ("en"));

        append ();

        foreach (var locale in get_supported_languages ()) {
            Intl.setlocale (LocaleCategory.MESSAGES, fix_locale (locale));

            append ();
        }

        set_current_locale (cur_locale);

        Timeout.add_seconds (3, () => {
            var cur_pos = (int) carousel.position;

            if (cur_pos == carousel.n_pages - 1) {
                carousel.scroll_to (carousel.get_nth_page (0), false);
                Idle.add_once (() => {
                    carousel.scroll_to (carousel.get_nth_page (1), true);
                });
            } else {
                carousel.scroll_to (carousel.get_nth_page (cur_pos + 1), true);
            }

            return true;
        });
    }

    void append () {
        carousel.append (new ReadySet.BasePageDesc (
            _("Hello!"),
            _("Let's start by choosing the language for the application and for your system.")
        ) {
            hexpand = true
        });
    }
}
