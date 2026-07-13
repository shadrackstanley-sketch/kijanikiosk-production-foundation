#!/bin/sh
set -eu

OUTPUT_FILE="${1:-credential-audit.txt}"
BUILD_LOG="${2:-green-pipeline-run.txt}"

: > "${OUTPUT_FILE}"

run_check() {
    description="$1"
    command="$2"

    {
        echo "============================================================"
        echo "${description}"
        echo "============================================================"

        if sh -c "${command}"; then
            echo "RESULT: Review matches above."
        else
            echo "RESULT: PASS - no matches found."
        fi

        echo
    } >> "${OUTPUT_FILE}" 2>&1
}

run_check \
  "CHECK 1: Literal passwords, tokens, and secrets in Jenkinsfile" \
  "grep -Ein '(password|passwd|secret|token|api[_-]?key)[[:space:]]*[:=][[:space:]]*[\"'\"'][^$]' Jenkinsfile"

run_check \
  "CHECK 2: Nexus username or password values in Jenkinsfile" \
  "grep -Ein '(admin|_auth=|authorization:|basic[[:space:]])' Jenkinsfile"

run_check \
  "CHECK 3: Credential-like values in Git history" \
  "git log -p --all | grep -Ein '(password|passwd|secret|token|api[_-]?key)[[:space:]]*[:=][[:space:]]*[\"'\"'][^$]'"

run_check \
  "CHECK 4: Private keys committed to Git history" \
  "git log -p --all | grep -E 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY'"

if [ -f "${BUILD_LOG}" ]; then
    run_check \
      "CHECK 5: Credential-like values in final build log" \
      "grep -Ein '(password=|passwd=|_auth=|authorization: basic|BEGIN .*PRIVATE KEY)' '${BUILD_LOG}'"
else
    {
        echo "============================================================"
        echo "CHECK 5: Final build log"
        echo "============================================================"
        echo "RESULT: NOT RUN - ${BUILD_LOG} does not exist yet."
        echo
    } >> "${OUTPUT_FILE}"
fi

echo "Credential audit written to ${OUTPUT_FILE}"
