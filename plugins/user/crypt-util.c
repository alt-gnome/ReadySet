/* -*- Mode: C; tab-width: 8; indent-tabs-mode: nil; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2004-2005 James M. Cape <jcape@ignore-your.tv>.
 * Copyright (C) 2007-2008 William Jon McCann <mccann@jhu.edu>
 * Copyright (c) 2023 GNOME Foundation Inc.
 *               Contributor: Adrian Vovk
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include "config.h"

#include <glib.h>

#ifdef HAVE_CRYPT_H
#include <crypt.h>
#else
#include <unistd.h>
#endif

#include "crypt-util.h"

#ifdef HAVE_LIBXCRYPT
gchar *
hash_password (const gchar *plain)
{
        gchar *hashed = NULL;
        g_autofree struct crypt_data *cd = NULL;

        cd = g_malloc0 (sizeof (struct crypt_data));

        crypt_gensalt_rn (NULL, 0, NULL, 0,
                          cd->input, sizeof (cd->input));
        hashed = g_strdup (crypt_rn (plain, cd->input,
                           cd, sizeof (struct crypt_data)));

        explicit_bzero (cd, sizeof (struct crypt_data));

        return hashed;
}
#else
static const gchar
salt_char (GRand *rand)
{
        const gchar salt[] = "ABCDEFGHIJKLMNOPQRSTUVXYZ"
                             "abcdefghijklmnopqrstuvxyz"
                             "./0123456789";

        return salt[g_rand_int_range (rand, 0, G_N_ELEMENTS (salt))];
}

static gchar *
generate_salt_for_crypt_hash (void)
{
        g_autoptr (GString) salt = NULL;
        g_autoptr (GRand) rand = NULL;
        gint i;

        rand = g_rand_new ();
        salt = g_string_sized_new (21);

        /* sha512crypt */
        g_string_append (salt, "$6$");
        for (i = 0; i < 16; i++) {
                g_string_append_c (salt, salt_char (rand));
        }
        g_string_append_c (salt, '$');

        return g_strdup (salt->str);
}

gchar *
hash_password (const gchar *plain)
{
        gchar *hashed = NULL;
        g_autofree char *salt = NULL;

        salt = generate_salt_for_crypt_hash ();

#ifdef HAVE_CRYPT_R
        g_autofree struct crypt_data *cd = NULL;

        cd = g_malloc0 (sizeof (struct crypt_data));
        hashed = g_strdup (crypt_r (plain, salt, cd));

        explicit_bzero (cd, sizeof (struct crypt_data));
#else
        hashed = g_strdup (crypt (plain, salt));

        /* Unlike struct crypt_data used with crypt_r(3), we cannot write into
           the output buffer, and have no access to the internal state of the
           crypt(3) function.  Our best effort, we can do, is to clobber both
           of them by computing a nonsense hash. */
        crypt (salt, salt);
#endif
        explicit_bzero (salt, strlen (salt));

        return hashed;
}
#endif
