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

[CCode (cheader_filename = "passwdqc.h", cprefix = "passwdqc_", lower_case_cprefix = "passwdqc_")]
namespace PasswdQC {
    [Compact]
    [CCode (
        cname = "struct passwd",
        has_type_id = false,
        has_copy_function = false,
        has_destroy_function = false
    )]
    public struct Passwd {
        public string pw_name;
        public string pw_passwd;
        public string pw_gecos;
        public string pw_dir;
        public string pw_shell;
    }

    [Compact]
    [CCode (
        cname = "passwdqc_params_qc_t",
        has_type_id = false,
        has_copy_function = false,
        has_destroy_function = false
    )]
    public struct ParamsQC {
        //  [CCode (array_length = false, array_length_cexpr = "5")]
        //  public int[] min;
        //  public int max;
        //  public int passphrase_words;
        //  public int match_length;
        //  public int similar_deny;
        //  public int random_bits;
        //  public string wordlist;
        //  public string denylist;
        //  public string filter;

        [CCode (cname = "passwdqc_check")]
        public unowned string check (string newpass, string? oldpass = null, Passwd? pw = null);

        [CCode (cname = "passwdqc_random")]
        public string? random ();
    }

    [Compact]
    [CCode (
        cname = "passwdqc_params_pam_t",
        has_type_id = false,
        has_copy_function = false,
        has_destroy_function = false
    )]
    public struct ParamsPAM {
        public int flags;
        public int retry;
    }

    [Compact]
    [CCode (
        cname = "passwdqc_params_t",
        has_type_id = false,
        has_copy_function = false,
        has_destroy_function = false,
        free_function = "passwdqc_params_free"
    )]
    public struct Params {
        public ParamsQC qc;
        public ParamsPAM pam;

        //  [CCode (cname = "passwdqc_params_parse")]
        //  public int params_parse (out unowned string? reason, int argc, [CCode (array_length = false)] string[] argv);

        [CCode (cname = "passwdqc_params_load")]
        public int params_load (out unowned string? reason, string pathname);

        [CCode (cname = "passwdqc_params_reset")]
        public void params_reset ();
    }

    [CCode (cname = "F_ENFORCE_MASK")]
    public const int ENFORCE_MASK;
    [CCode (cname = "F_ENFORCE_USERS")]
    public const int ENFORCE_USERS;
    [CCode (cname = "F_ENFORCE_ROOT")]
    public const int ENFORCE_ROOT;
    [CCode (cname = "F_ENFORCE_EVERYONE")]
    public const int ENFORCE_EVERYONE;
    [CCode (cname = "F_NON_UNIX")]
    public const int NON_UNIX;
    [CCode (cname = "F_ASK_OLDAUTHTOK_MASK")]
    public const int ASK_OLDAUTHTOK_MASK;
    [CCode (cname = "F_ASK_OLDAUTHTOK_PRELIM")]
    public const int ASK_OLDAUTHTOK_PRELIM;
    [CCode (cname = "F_ASK_OLDAUTHTOK_UPDATE")]
    public const int ASK_OLDAUTHTOK_UPDATE;
    [CCode (cname = "F_CHECK_OLDAUTHTOK")]
    public const int CHECK_OLDAUTHTOK;
    [CCode (cname = "F_USE_FIRST_PASS")]
    public const int USE_FIRST_PASS;
    [CCode (cname = "F_USE_AUTHTOK")]
    public const int USE_AUTHTOK;
    [CCode (cname = "F_NO_AUDIT")]
    public const int NO_AUDIT;

    [CCode (cname = "PASSWDQC_VERSION")]
    public const string VERSION;

    [CCode (cname = "_passwdqc_memzero", has_target = false)]
    public delegate void MemZeroFunc (void* data, size_t size);
}
