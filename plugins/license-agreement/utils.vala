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

namespace LicenseAgreement {
    public string html_to_pango (string start_text) {
        var text = start_text.replace ("\n", " ");

        var tags = new Gee.ArrayList<TagReplacement?> ();

        TagReplacement[] plain_tags = {
            { "<\\s*head[^>]*>.*</\\s*head\\s*>", "" },
            { "<\\s*/?(body|html)[^>]*>", "" },
            { "<\\s*(b|strong)\\s*>", "<b>" },
            { "<\\s*/\\s*(b|strong)\\s*>", "</b>" },
            { "<\\s*(i|em)\\s*>", "<i>" },
            { "<\\s*/\\s*(i|em)\\s*>", "</i>" },
            { "<\\s*u\\s*>", "<u>" },
            { "<\\s*/\\s*u\\s*>", "</u>" },
            { "<\\s*p[^>]*>", "\n" },
            { "<\\s*/\\s*p\\s*>", "\n" },
            { "<li[^>]*>", "• " },
            { "</li>", "\n" },
            { "<ul[^>]*>", "\n" },
            { "</ul>", "\n" },
            { "<\\s*/?br[^>]*/?>", "\n" },
            { "<\\s*a\\s+[^>]*href\\s*=\\s*\"([^\"]+)\"[^>]*>", "<a href=\"\\1\">"},
        };

        foreach (var item in plain_tags) {
            tags.add (item);
        }

        for (int i = 1; i <= 6; i++) {
            tags.add (TagReplacement () {
                pattern = @"<\\s*h$(i.to_string())[^>]*>",
                replacement = @"\n<span size=\"$(((TextSize) i).get_size())\">",
            });

            tags.add (TagReplacement () {
                pattern = @"<\\s*/h$(i.to_string())[^>]*>",
                replacement = "</span>\n",
            });
        }

        foreach (var tag in tags) {
            try {
                var regex = new Regex (tag.pattern, RegexCompileFlags.MULTILINE | RegexCompileFlags.DOTALL);
                text = regex.replace (text, text.length, 0, tag.replacement);
            } catch (Error error) {
                message (error.message);
            }
        }

        text = text.replace ("&mdash;", "—");
        text = text.replace ("&laquo;", "«");
        text = text.replace ("&raquo;", "»");
        text = text.replace ("&nbsp;", " ");

        try {
            // \n\n
            var newlines = new Regex ("\\n{3}+", RegexCompileFlags.MULTILINE | RegexCompileFlags.DOTALL);
            text = newlines.replace (text, text.length, 0, "\n\n");
        } catch (Error error) {
            message (error.message);
        }

        try {
            // `  `
            var spaces = new Regex (" {2}+", RegexCompileFlags.MULTILINE | RegexCompileFlags.DOTALL);
            text = spaces.replace (text, text.length, 0, " ");
        } catch (Error error) {
            message (error.message);
        }

        try {
            // ` \n `
            var newlines_with_spaces = new Regex (" *\n *", RegexCompileFlags.MULTILINE | RegexCompileFlags.DOTALL);
            text = newlines_with_spaces.replace (text, text.length, 0, "\n");
        } catch (Error error) {
            message (error.message);
        }

        text = text.strip ();

        return text;
    }

    public string get_fallback_language () {
        string language = "C";

        var context = Addin.get_instance ().context;
        var fallback = context.get_string ("license-agreement-language-fallback");
        if (fallback != "") {
            return fallback;
        }

        return language;
    }

    public string get_current_language () {
        var context = Addin.get_instance ().context;
        if (context.has_key ("language-locale")) {
            return context.get_string ("language-locale");
        }

        return get_fallback_language ();
    }

    public Gee.ArrayList<string> get_language_variants (string language) {
        var variant_regex = /^([^_]+)(_[^\.]+)?(\.[^@]+)?(@.+)?$/; // vala-lint=space-before-paren

        MatchInfo match;
        if (!variant_regex.match (language, 0, out match)) {
            var variants = new Gee.ArrayList<string> ();
            variants.add (language);
            variants.add (get_fallback_language ());
            return variants;
        }

        string lang = match.fetch (1);
        string territory = match.fetch (2);
        string? encoding = match.fetch (3);
        string? modifier = match.fetch (4);

        var variants_set = new Gee.HashSet<string> ();

        bool[] ter = { false, true };
        bool[] enc = { false, true };
        bool[] mod = { false, true };

        variants_set.add (lang);

        foreach (bool incl_ter in ter) {
            foreach (bool incl_enc in enc) {
                foreach (bool incl_mod in mod) {
                    if (incl_ter && encoding == null) {
                        continue;
                    }
                    if (incl_enc && encoding == null) {
                        continue;
                    }
                    if (incl_mod && modifier == null) {
                        continue;
                    }

                    string variant = lang;
                    if (incl_ter) {
                        variant += territory;
                    }
                    if (incl_enc) {
                        variant += encoding;
                    }
                    if (incl_mod) {
                        variant += modifier;
                    }
                    variants_set.add (variant);
                }
            }
        }

        var variants = new Gee.ArrayList<string> ();
        variants.add_all (variants_set);
        variants.add (get_fallback_language ());
        return variants;
    }

    enum TextSize {
        XX_LARGE,
        X_LARGE,
        LARGE,
        MEDIUM,
        SMALL,
        X_SMALL,
        XX_SMALL;

        public string get_size () {
            switch (this) {
                case XX_LARGE:
                    return "xx-large";
                case X_LARGE:
                    return "x-large";
                case LARGE:
                    return "large";
                case MEDIUM:
                    return "medium";
                case SMALL:
                    return "small";
                case X_SMALL:
                    return "x-small";
                case XX_SMALL:
                    return "xx-small";
                default:
                    return "";
            }
        }
    }

    struct TagReplacement {
        string pattern;
        string replacement;
    }
}
