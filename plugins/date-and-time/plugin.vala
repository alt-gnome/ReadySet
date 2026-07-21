/*
 * Copyright (C) 2026 David Sultaniiazov <x1z53@alt-gnome.ru>
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

public class DateAndTime.Addin : ReadySet.StepAddin {

    static Addin instance;

    public override bool existing_user {
        get {
            return true;
        }
    }

    protected override string? resource_base_path {
        get {
            return "/org/altlinux/ReadySet/Plugin/DateAndTime/";
        }
    }

    construct {
        instance = this;
    }

    public async override ReadySet.BasePage[] build_pages () {
        return {
            new DateAndTime.Page (),
        };
    }

    internal static Addin get_instance () {
        return instance;
    }

    public override HashTable<string, ReadySet.ContextVarInfo> get_context_vars () {
        var vars = base.get_context_vars ();
        vars["automatic-timezone"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.BOOLEAN, true);
        vars["automatic-datetime"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.BOOLEAN, true);
        vars["timezone"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.STRING);
        vars["datetime"] = new ReadySet.ContextVarInfo (ReadySet.ContextType.INT);
        return vars;
    }

    public async override void apply (ReadySet.ProgressData progress_data) throws ReadySet.ApplyError {
        DateAndTime.Timedate1 proxy;
        try {
            proxy = yield get_timedate_proxy ();
        } catch (Error e) {
            throw ReadySet.ApplyError.build_error (_("Failed to connect to timedate service"), e.message);
        }

        var automatic_timezone = context.get_boolean ("date-and-time.automatic-timezone");
        var automatic_datetime = context.get_boolean ("date-and-time.automatic-datetime");

        Settings datetime_settings = new Settings ("org.gnome.desktop.datetime");
        datetime_settings.set_boolean ("automatic-timezone", automatic_timezone);

        if (!automatic_timezone) {
            try {
                var timezone = context.get_string ("date-and-time.timezone");
                yield proxy.set_timezone (timezone);
            } catch (Error e) {
                throw ReadySet.ApplyError.build_error (_("Error when setting timezone"), e.message);
            }
        }

        try {
            yield proxy.set_ntp (automatic_datetime);
        } catch (Error e) {
            throw ReadySet.ApplyError.build_error (_("Error when setting NTP"), e.message);
        }

        if (!automatic_datetime) {
            try {
                var datetime = context.get_int ("date-and-time.datetime");
                yield proxy.set_time (datetime * 1000000);
            } catch (Error e) {
                throw ReadySet.ApplyError.build_error (_("Error when setting time"), e.message);
            }
        }
    }
}

public void peas_register_types (TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type (typeof (ReadySet.StepAddin), typeof (DateAndTime.Addin));
}
