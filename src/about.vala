/* Copyright (C) 2024-2025 Vladimir Romanov <rirusha@altlinux.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace ReadySet {
    public Adw.AboutDialog build_about () {
        var about = new Adw.AboutDialog () {
            application_name = _("Ready Set"),
            application_icon = Config.APP_ID_DYN,
            developer_name = "ALT Linux Team",
            version = Config.VERSION,
            designers = {
                "Viktoria Zubacheva <gingercat@alt-gnome.ru>",
            },
            artists = {
                "Nina Petrova <1704.nina.petrova@gmail.com>",
            },
            developers = {
                "Vladimir Romanov <rirusha@altlinux.org>"
            },
            // Translators: NAME <EMAIL.COM> /n NAME <EMAIL.COM>
            translator_credits = _("translator-credits"),
            license_type = Gtk.License.GPL_3_0,
            copyright = "© 2024-2025 ALT Linux Team",
            release_notes_version = Config.VERSION
        };

        return about;
    }
}
