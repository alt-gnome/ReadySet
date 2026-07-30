/*
 * Copyright (C) 2026 Vladimir Romanov <rirusha@altlinux.org>
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

public class ReadySetSoftware.SourceBinding : Tuner.Binding {

    public Software.Source source { get; construct; }

    public weak Gtk.Widget? dialog_parent { get; set; }

    bool _active = false;
    bool _busy = false;

    public SourceBinding (Software.Source source) {
        Object (source: source);
    }

    construct {
        check_initial.begin ();
    }

    public override GLib.Type expected_type {
        get {
            return typeof (bool);
        }
    }

    public override bool get_value (ref GLib.Value value) {
        value.set_boolean (_active);
        return true;
    }

    public override void set_value (GLib.Value value) {
        if (!value.holds (typeof (bool))) {
            return;
        }

        bool new_active = value.get_boolean ();
        if (new_active == _active) {
            return;
        }

        if (_busy) {
            return;
        }

        bool old_active = _active;
        _active = new_active;
        _busy = true;

        process.begin (new_active, old_active);
    }

    public void set_state (bool active) {
        _active = active;
        emit_changed ();
    }

    async void check_initial () {
        _busy = true;

        try {
            bool res = source.check ();
            set_state (res);
        } catch (Software.SourceError e) {
            if (e.code != Software.SourceError.CANCELLED) {
                Tuner.toast (e.message);
            }
        } catch (Error e) {
            Tuner.toast (e.message);
        } finally {
            _busy = false;
        }
    }

    async void process (bool target_active, bool old_active) {
        try {
            if (target_active) {
                if (source.nonfree && dialog_parent != null) {
                    bool confirmed = yield confirm_nonfree_dialog ();
                    if (!confirmed) {
                        _active = old_active;
                        return;
                    }
                }

                yield source.apply ();
            } else {
                yield source.undo ();
            }
        } catch (Software.SourceError e) {
            if (e.code != Software.SourceError.CANCELLED) {
                Tuner.toast (e.message);
            }
            _active = old_active;
        } catch (Error e) {
            Tuner.toast (e.message);
            _active = old_active;
        }

        try {
            _active = source.check ();
        } catch (Software.SourceError e) {
            if (e.code != Software.SourceError.CANCELLED) {
                Tuner.toast (e.message);
            }
        } catch (Error e) {
            Tuner.toast (e.message);
        } finally {
            _busy = false;
            emit_changed ();
        }
    }

    async bool confirm_nonfree_dialog () {
        var dialog = new Adw.AlertDialog (_("Non-Free Repository"), _("This repository contains software with a non-free license. Pay attention to the software license restrictions before usage."));  // vala-lint=line-length

        dialog.add_response ("cancel", _("Cancel"));
        dialog.add_response ("ok", _("Ok"));
        dialog.set_default_response ("ok");
        dialog.set_close_response ("cancel");

        string response = yield dialog.choose (dialog_parent, null);
        return response == "ok";
    }
}
