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

public class Test.Addin : ReadySet.Addin {

    static Addin instance;

    protected override string? resource_base_path {
        get {
            return "/org/altlinux/ReadySet/Plugin/Test/";
        }
    }

    construct {
        instance = this;
    }

    public override ReadySet.BasePage[] build_pages () {
        return {
            new Test.Page (),
            new Test.ErrorPage ()
        };
    }

    internal static Addin get_instance () {
        return instance;
    }

    public override async void apply () throws ReadySet.ApplyError {
        message ("Tests DONE");
    }
}

public void peas_register_types (TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type (typeof (ReadySet.Addin), typeof (Test.Addin));
}
