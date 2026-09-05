[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "crypt-util.h")]
namespace UserC {
    [CCode (cname = "hash_password")]
    internal string hash_password (string plain);
}
