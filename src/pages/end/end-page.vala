/* Copyright 2024-2025 Vladimir Vaskov <rirusha@altlinux.org>
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

[GtkTemplate (ui = "/space/rirusha/ReadySet/ui/end-page.ui")]
public sealed class ReadySet.EndPage : BasePage {

    [GtkChild]
    unowned Gtk.Stack stack;

    public string error_title { get; set; }

    public string error_description { get; set; }

    public void start_action () {
        stack.visible_child_name = "load";

        try {
            ((ReadySet.Application) GLib.Application.get_default ()).apply_all ();
            stack.visible_child_name = "ready";
            is_ready = true;

        } catch (ApplyError error) {
            var parts = error.message.split (RSS);

            if (parts.length == 2) {
                error_title = parts[0];
                error_description = parts[1];
            } else {
                error_title = _("Something went wrong");
                error_description = error.message;
            }

            error_description = _("Error message: %s").printf (error_description);

            stack.visible_child_name = "error";
            is_ready = false;
        }
    }

    public override void apply () throws ApplyError {
        return;
    }
}
