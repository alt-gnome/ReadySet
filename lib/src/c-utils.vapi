[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "c-utils.h")]
namespace ReadySetC {
    [CCode (cname = "str_safe_copy", array_length = false, array_null_terminated = true)]
    internal static string[]? safe_copy ([CCode (array_length = false, array_null_terminated = true)] string[]? str_array);
}
