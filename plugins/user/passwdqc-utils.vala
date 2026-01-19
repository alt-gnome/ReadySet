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

namespace User.Password {

    static PasswdQC.Params? _passwdqc_params = null;

    unowned PasswdQC.Params get_pwqc () {
        if (_passwdqc_params == null) {
            _passwdqc_params = PasswdQC.Params ();
            var passwdqc_conf_path = Addin.get_instance ().context.get_string ("passwd-conf-path");
            if (passwdqc_conf_path == "") {
                passwdqc_conf_path = "/etc/passwdqc.conf";
            }
            _passwdqc_params.params_load (null, passwdqc_conf_path);
        }

        return _passwdqc_params;
    }

    public string generate () {
        var prms = get_pwqc ();
        var res = prms.qc.random ();

        if (res == null) {
            warning (_("Failed to generate password"));
            return "";
        } else {
            return res;
        }
    }

    public Strength strength (
        string password,
        string? old_password = null,
        string? username = null
    ) {
        var prms = get_pwqc ();
        var res = prms.qc.check (password, old_password);

        if (res == null) {
            return {
                hint: "",
                strength_level: GOOD,
                value: 0.0,
                support_value: false
            };
        } else {
            return {
                hint: capital (res),
                strength_level: BAD,
                value: 0.0,
                support_value: false
            };
        }
    }
}
