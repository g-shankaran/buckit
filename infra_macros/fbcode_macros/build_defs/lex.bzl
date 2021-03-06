load("@bazel_skylib//lib:shell.bzl", "shell")
load("@fbcode_macros//build_defs:custom_rule.bzl", "copy_genrule_output_file", "get_project_root_from_gen_dir")
load("@fbcode_macros//build_defs:target_utils.bzl", "target_utils")

_LEX = target_utils.ThirdPartyToolRuleTarget("flex", "flex")

_LEX_CMD = (
    "mkdir -p \"$OUT\" && " +
    "$(exe {lex}) {args} -o$OUT/{src} --header-file=$OUT/{header} $SRCS && " +
    # Remove absolute path to source repo from generated files. It's fine to keep
    # buck-out/*/gen/foo/bar in the paths.
    """perl -pi -e 's!\\Q'"\\$(realpath "$GEN_DIR/{fbcode}")"'/\\E!!'  "$OUT"/{src} "$OUT"/{header}"""
)

def lex(name, lex_flags, lex_src, platform, visibility):
    """
    Create rules to generate a C/C++ header and source from the given lex file

    Args:
        name: The base name to use when generating rules (see Outputs)
        lex_flags: A list of flags to pass to flex
        lex_src: The lex source file to operate on
        platform: The platform to use to find the lex tool
        visibility: The visibility for this rule. Note this is not modified by global
                    rules.

    Returns:
        (relative target name for header, relative target name for generated src file)

    Outputs:
        {name}={lex_src}: The genrule that actually runs flex
        {name}={lex_src}.h: The rule for the header generated by flex (slashes replaced by -)
        {name}={lex_src}.cc: The rule for the header generated by flex (slashes replaced by -)
    """

    sanitized_name = name.replace("/", "-")
    genrule_name = "{}={}".format(name.replace("/", "-"), lex_src)

    base = lex_src
    header = base + ".h"
    source = base + ".cc"

    cmd = _LEX_CMD.format(
        lex = target_utils.target_to_label(_LEX, platform = platform),
        args = " ".join([shell.quote(f) for f in lex_flags]),
        src = shell.quote(source),
        header = shell.quote(header),
        fbcode = get_project_root_from_gen_dir(),
    )

    native.genrule(
        name = genrule_name,
        visibility = visibility,
        out = base + ".d",
        srcs = [lex_src],
        cmd = cmd,
    )

    header_name = copy_genrule_output_file(
        sanitized_name,
        ":" + genrule_name,
        lex_src + ".h",
        visibility,
    )
    source_name = copy_genrule_output_file(
        sanitized_name,
        ":" + genrule_name,
        lex_src + ".cc",
        visibility,
    )

    return (":" + header_name, ":" + source_name)
