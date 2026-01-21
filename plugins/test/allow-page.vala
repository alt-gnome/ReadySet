/* Copyright (C) 2026 Vladimir Romanov <rirusha@altlinux.org>
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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/Test/ui/allow-page.ui")]
public sealed class Test.AllowPage : ReadySet.BaseBarePage {

    bool _accessible = true;
    public override bool accessible {
        get {
            return _accessible;
        }
        protected set {
            _accessible = value;
        }
    }

    construct {
        Addin.get_instance ().context.data_changed.connect ((key) => {
            if (key == "test-accessible") {
                accessible = Addin.get_instance ().context.get_boolean ("test-accessible");
            }
        });
        accessible = Addin.get_instance ().context.get_boolean ("test-accessible");
    }
}
