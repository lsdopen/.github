# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this module, please report it
privately. Do **not** open a public GitHub issue for security problems.

- **Preferred**: open a [GitHub Security Advisory](../../security/advisories/new)
  on this repository.
- **Alternative**: email the maintainers at security@lsdopen.io.

Please include enough detail to reproduce the issue — the module version, the
Terraform and provider versions, and the affected configuration.

We aim to acknowledge a report within 3 business days and to provide a
remediation timeline after triage.

## Supported Versions

Security fixes are released against the latest published version of this module.
Pin to a released tag and upgrade to pick up fixes.

## Security Scanning

This module is scanned in CI by the shared reusable workflow
`lsdopen/.github/.github/workflows/terraform-module-continuous-integration.yaml`:

- **TFLint** validates the configuration against AWS best practices.
- **Trivy** (config/IaC mode) scans for misconfigurations, uploads findings to
  the GitHub Security tab as SARIF, and fails the build on HIGH/CRITICAL.

Because scanning lives in the shared workflow, every module inherits the same
gate; there is no per-repo security job.

To reproduce the scans locally:

```bash
terraform init -backend=false
terraform validate
terraform fmt -check -recursive
tflint --init && tflint
trivy config .
```
