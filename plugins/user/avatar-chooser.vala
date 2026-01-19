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

[GtkTemplate (ui = "/org/altlinux/ReadySet/Plugin/User/ui/avatar-chooser.ui")]
public sealed class User.AvatarChooser : Adw.Dialog {

    [GtkChild]
    unowned Gtk.FlowBox flowbox;

    ListStore faces;

    public string? avatar_filename { get; private set; default = null; }

    construct {
        faces = new ListStore (typeof (File));
        flowbox.bind_model (faces, create_face_widget);

        flowbox.child_activated.connect (face_widget_activated);

        var facesdirs = get_context_facesdirs ();
        var added_faces = add_faces_from_dirs (faces, facesdirs, true);

        if (!added_faces) {
            facesdirs = get_settings_facesdirs ();
            added_faces = add_faces_from_dirs (faces, facesdirs, true);

            if (!added_faces) {
                facesdirs = get_system_facesdirs ();
                added_faces = add_faces_from_dirs (faces, facesdirs, false);
            }
        }
    }

    bool add_faces_from_dirs (ListStore faces, string[] facesdirs, bool add_all) {
        bool added_faces = false;

        foreach (var facesdir in facesdirs) {
            try {
                var dir = File.new_for_path (facesdir);
                var enumerator = dir.enumerate_children (
                    "%s,%s,%s,%s".printf (
                        FileAttribute.STANDARD_NAME,
                        FileAttribute.STANDARD_TYPE,
                        FileAttribute.STANDARD_IS_SYMLINK,
                        FileAttribute.STANDARD_SYMLINK_TARGET
                    ),
                    NONE
                );

                if (enumerator == null) {
                    continue;
                }

                FileInfo? info;
                while ((info = enumerator.next_file ()) != null) {
                    var type_ = info.get_file_type ();
                    if (type_ != FileType.REGULAR && type_ != FileType.SYMBOLIC_LINK) {
                        continue;
                    }

                    var target = info.get_attribute_byte_string (FileAttribute.STANDARD_SYMLINK_TARGET);
                    if (target != null && target.has_prefix ("legacy/")) {
                        continue;
                    }

                    var face_file = dir.get_child (info.get_name ());
                    faces.append (face_file);
                    added_faces = true;
                }

                enumerator.close ();

                if (added_faces && !add_all) {
                    break;
                }
            } catch (Error e) {
                continue;
            }
        }

        return added_faces;
    }

    Gtk.Widget create_face_widget (Object item) {
        var file = (File) item;
        var path = file.get_path ();

        var image = new Adw.Avatar (72, null, true);

        try {
            image.set_custom_image (Gdk.Texture.from_file (file));
        } catch (Error e) {
            warning (e.message);
            image.set_icon_name ("system-users-symbolic");
        }

        image.text = path;

        return image;
    }

    void face_widget_activated (Gtk.FlowBoxChild child) {
        var image = (Adw.Avatar) child.get_child ();

        avatar_filename = image.text;

        close ();
    }
}
