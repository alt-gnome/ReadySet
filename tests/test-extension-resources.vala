class TestExtension : ReadySet.ExtensionBase {
    public override string? resource_base_path {
        get {
            return "/org/altlinux/ReadySet/Tests/LateExtension/";
        }
    }
}

string bundle_path;

int main (string[] args) {
    Test.init (ref args);
    bundle_path = args[1];

    Test.add_func ("/extension-resources/late-icons", () => {
        var theme = new Gtk.IconTheme ();
        theme.set_theme_name ("hicolor");
        theme.add_resource_path ("/org/altlinux/ReadySet/icons");
        assert (!theme.has_icon ("ready-set-late-extension-symbolic"));

        try {
            var resource = Resource.load (bundle_path);
            resources_register (resource);
            assert (resources_lookup_data (
                "/org/altlinux/ReadySet/Tests/LateExtension/icons/scalable/actions/" +
                "ready-set-late-extension-symbolic.svg",
                ResourceLookupFlags.NONE
            ).get_size () > 0);
            assert (!theme.has_icon ("ready-set-late-extension-symbolic"));

            var extension = new TestExtension ();
            extension.load_icons (theme);
            assert (theme.has_icon ("ready-set-late-extension-symbolic"));
            var path_count = theme.get_resource_path ().length;
            extension.load_icons (theme);
            assert (theme.get_resource_path ().length == path_count);
            resources_unregister (resource);
        } catch (Error e) {
            Test.fail_printf ("%s", e.message);
        }
    });

    return Test.run ();
}
