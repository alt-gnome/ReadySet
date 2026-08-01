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

public abstract class User.PagePasswordCommon : ReadySet.BasePage {

    protected bool force_true = false;

    protected abstract string get_password ();

    protected abstract void update_is_ready ();

    public override bool try_continue () {
        var password_good = password_is_correct (get_password ());

        if (password_good) {
            return true;
        }

        if (force_true) {
            return true;
        }

        var dialog = new Adw.AlertDialog (
            _("Weak password"),
            _("The entered password is not secure. Do you really want to use it?")
        );
        dialog.add_response ("no", _("_No"));
        dialog.add_response ("ok", _("_Yes"));
        dialog.set_response_appearance ("no", Adw.ResponseAppearance.SUGGESTED);
        dialog.set_default_response ("no");

        dialog.response.connect (on_bad_passwd_dialog_response);
        dialog.present (this);

        return false;
    }

    void on_bad_passwd_dialog_response (string response) {
        if (response == "ok") {
            force_true = true;
            next ();
        }
    }
}
