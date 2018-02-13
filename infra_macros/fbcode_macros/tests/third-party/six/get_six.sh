#!/bin/bash

# Get the six whl for py2/py3 compatibility in tests
set -e

filename="six-1.11.0-py2.py3-none-any.whl"
unverified_filename="${filename}.unverified"
expected_hash="fa2683a24d4a7422add33400048fc375b2afe57b"

trap "rm -f \"$unverified_filename\"" EXIT

curl "https://pypi.python.org/packages/67/4b/141a581104b1f6397bfa78ac9d43d8ad29a7ca43ea90a2d863fe3056e86a/six-1.11.0-py2.py3-none-any.whl#md5=866ab722be6bdfed6830f3179af65468" > "$unverified_filename"
sha=$(sha1sum "$filename" | awk {'print $1'})

if [ "$sha" != "$expected_hash" ]; then
  echo "Invalid sha detected for $unverified_filename Expected $expected_hash , got $sha"
  exit 1
fi
mv "$unverified_filename" "$filename"

cat > BUCK <<EOF
# Generated by get_six.sh

prebuilt_python_library(
    name = "six",
    binary_src = "$filename",
    visibility = ["//tests/..."],
)
EOF