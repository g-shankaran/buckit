"""
Wrappers to native buck rules.

These generally are only allowed to be used by certain pre-configured targets
"""

load(
    "@fbcode_macros//build_defs/config:read_configs.bzl",
    "read_boolean",
    "read_string",
)
load(
    "@fbcode_macros//build_defs:visibility.bzl",
    "get_visibility",
)
load(
    "@fbcode_macros//build_defs:python_typing.bzl",
    "gen_typing_config",
    "get_typing_config_target",
)

_FBCODE_UI_MESSAGE = (
    "Unsupported access to Buck rules! " +
    "Please use supported fbcode rules (https://fburl.com/fbcode-targets) " +
    "instead."
)

def _get_forbid_raw_buck_rules():
    """
    Whether to forbid raw buck rules that are not in whitelisted_raw_buck_rules
    """
    return read_boolean("fbcode", "forbid_raw_buck_rules", False)

def _get_whitelisted_raw_buck_rules():
    """
    A list of rules that are allowed to use each type of raw buck rule.

    This is a list of buck rule types to path:target that should be allowed to
    use raw buck rules. e.g. cxx_library=watchman:headers

    Returns:
        dictionary of rule type to list of tuples of base path / rule name
    """
    whitelisted_raw_buck_rules_str = read_string(
        "fbcode",
        "whitelisted_raw_buck_rules",
        "",
    )
    whitelisted_raw_buck_rules = {}
    for rule_group in whitelisted_raw_buck_rules_str.strip().split(","):
        if not rule_group:
            continue
        rule_type, rule = rule_group.strip().split("=", 1)
        if rule_type not in whitelisted_raw_buck_rules:
            whitelisted_raw_buck_rules[rule_type] = []
        whitelisted_raw_buck_rules[rule_type].append(tuple(rule.split(":", 1)))
    return whitelisted_raw_buck_rules

def _verify_whitelisted_rule(rule_type, package_name, target_name):
    """
    Verifies that a rule is whitelisted to use native rules. If not, fail
    """
    if _get_forbid_raw_buck_rules():
        whitelist = _get_whitelisted_raw_buck_rules().get(rule_type, {})
        if (package_name, target_name) not in whitelist:
            fail(
                "{}\n{}(): native rule {}:{} is not whitelisted".format(
                    _FBCODE_UI_MESSAGE,
                    rule_type,
                    package_name,
                    target_name,
                ),
            )

def buck_command_alias(*args, **kwargs):
    """ Wrapper to access Buck's native command_alias rule """
    native.command_alias(*args, **kwargs)

def cxx_genrule(*args, **kwargs):
    """ Wrapper to access Buck's native cxx_genrule rule """
    native.cxx_genrule(*args, **kwargs)

def buck_genrule(*args, **kwargs):
    """ Wrapper to access Buck's native genrule rule """
    native.genrule(*args, **kwargs)

def buck_python_binary(*args, **kwargs):
    """ Wrapper to access Buck's native python_binary rule """
    native.python_binary(*args, **kwargs)

def buck_python_library(name, *args, **kwargs):
    """ Wrapper to access Buck's native python_library rule """
    if get_typing_config_target():
        gen_typing_config(name)
    native.python_library(name = name, *args, **kwargs)

def remote_file(*args, **kwargs):
    """ Wrapper to access Buck's native remote_file rule """
    native.remote_file(*args, **kwargs)

def buck_sh_binary(name, main = None, *args, **kwargs):
    """
    Wrapper to access Buck's native sh_binary rule

    Args:
        name: The name of the rule
        main: The name of the script. If not provided, `name` will be used
        *args: Rest of args to pass to sh_binary
        **kwargs: Rest of kwargs to pass to sh_binary
    """
    main = main or name
    native.sh_binary(name = name, main = main, *args, **kwargs)

def buck_sh_test(*args, **kwargs):
    """ Wrapper to access Buck's native sh_test rule """
    native.sh_test(*args, **kwargs)

def versioned_alias(*args, **kwargs):
    """ Wrapper to access Buck's native versioned_alias rule """
    native.versioned_alias(*args, **kwargs)

def buck_cxx_binary(name, **kwargs):
    """ Wrapper to access Buck's native cxx_binary rule """
    _verify_whitelisted_rule("cxx_binary", native.package_name(), name)
    native.cxx_binary(name = name, **kwargs)

def buck_cxx_library(name, **kwargs):
    """ Wrapper to access Buck's native cxx_library rule """
    _verify_whitelisted_rule("cxx_library", native.package_name(), name)
    native.cxx_library(name = name, **kwargs)

def buck_cxx_test(name, **kwargs):
    """ Wrapper to access Buck's native cxx_test rule """
    _verify_whitelisted_rule("cxx_test", native.package_name(), name)
    native.cxx_test(name = name, **kwargs)

def buck_filegroup(*args, **kwargs):
    """ Wrapper to access Buck's native filegroup rule """
    native.filegroup(*args, **kwargs)

def buck_zip_file(**kwargs):
    """ Wrapper ot access Buck's native zip_file rule """
    native.zip_file(**kwargs)

def test_suite(name, visibility = None, *args, **kwargs):
    """ Wrapper to access Buck's native test_suite rule """
    native.test_suite(
        name = name,
        visibility = get_visibility(visibility, name),
        *args,
        **kwargs
    )
