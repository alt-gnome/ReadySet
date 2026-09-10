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

public sealed class PhrogFirstRun.Addin : ReadySet.PostActAddin {

    public override async ReadySet.PostActStatusFlags run (ReadySet.Context context) throws Error {
        var phrog_schema = SettingsSchemaSource.get_default ().lookup ("mobi.phosh.phrog", false);
        if (phrog_schema != null) {
            var phrog_settings = new Settings (phrog_schema.get_id ());
            phrog_settings.set_string ("first-run", "");
        }

        return 0;
    }
}

public void peas_register_types (TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type (typeof (ReadySet.PostActAddin), typeof (PhrogFirstRun.Addin));
}
