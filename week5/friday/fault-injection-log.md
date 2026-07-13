# Fault Injection Log

| Faulted stage | Fault introduced | Observed downstream behaviour | Green after fix? | Why this behaviour is correct |
|---|---|---|---|---|
| Lint | Introduced an undefined variable | Build, Verify, Archive, and Publish were skipped | Pending | Invalid source code should be rejected before time is spent building or testing it. |
| Build | Changed the build command to reference a missing file | Verify, Archive, and Publish were skipped | Pending | An artifact should not be tested or published when it cannot be built correctly. |
| Test | Changed the expected response status | Security Audit completed, while Archive and Publish were skipped | Pending | Parallel checks may finish independently, but publication must stop when any verification fails. |
| Security Audit | Temporarily forced the audit command to return failure | Test completed, while Archive and Publish were skipped | Pending | A package with an unacceptable security result must not enter the registry. |
| Publish | Used an invalid repository name or credential ID | All quality stages completed, but no artifact was added to Nexus | Pending | A publishing failure must preserve the verified archive while preventing a false successful release. |

## Recovery Evidence

After each fault, record:

- Build number
- Failed stage
- Stages that completed
- Stages that were skipped
- Commit that restored the pipeline
- Successful recovery build number
