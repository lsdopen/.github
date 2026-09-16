#!/usr/bin/env bash
# Shared file generation script for all Terraform modules.
# Source: https://raw.githubusercontent.com/lsdopen/.github/main/.github/terraform/generate-files.sh
#
# Generates README.md from docs/README.yaml + terraform-docs, and drops the
# canonical LICENSE and CONTRIBUTING.md into the module repo so every repo
# carries them as dedicated files (single source of truth in .github/terraform/).
#
# Override: Place a custom docs/generate-files.sh in your module repo to use instead.
set -euo pipefail

MODULE_DIR="${1:-.}"
cd "$MODULE_DIR"

DOCS_DIR="./docs"

# Detect latest version from git tags
export MODULE_VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "1.0.0")

# Generate terraform-docs JSON
tf_json=$(terraform-docs json .)

# Build required inputs table
required=$(echo "$tf_json" | jq -r '
  .inputs | map(select(.required == true)) |
  if length > 0 then
    "### Required Inputs\n\n| Name | Description | Type |\n| ---- | ----------- | ---- |\n" +
    (map("| <a name=\"input_\(.name)\"></a> [\(.name | gsub("_"; "\\_"))](\\#input\\_\(.name)) | \(.description | gsub("\n"; " ")) | `\(.type | gsub("\n"; ""))` |") | join("\n"))
  else "" end
')

# Build optional inputs table
optional=$(echo "$tf_json" | jq -r '
  .inputs | map(select(.required == false)) |
  if length > 0 then
    "### Optional Inputs\n\n| Name | Description | Type | Default |\n| ---- | ----------- | ---- | ------- |\n" +
    (map("| <a name=\"input_\(.name)\"></a> [\(.name | gsub("_"; "\\_"))](\\#input\\_\(.name)) | \(.description | gsub("\n"; " ")) | `\(.type | gsub("\n"; ""))` | `\(.default | tostring | gsub("\n"; ""))` |") | join("\n"))
  else "" end
')

# Build outputs table
outputs=$(echo "$tf_json" | jq -r '
  .outputs |
  if length > 0 then
    "## Outputs\n\n| Name | Description |\n| ---- | ----------- |\n" +
    (map("| <a name=\"output_\(.name)\"></a> [\(.name | gsub("_"; "\\_"))](\\#output\\_\(.name)) | \(.description | gsub("\n"; " ")) |") | join("\n"))
  else "" end
')

# Build providers table
providers=$(echo "$tf_json" | jq -r '
  .providers |
  if length > 0 then
    "## Providers\n\n| Name | Version |\n| ---- | ------- |\n" +
    (map("| \(.name) | \(.version // "n/a") |") | join("\n"))
  else "" end
')

# Build requirements table
requirements=$(echo "$tf_json" | jq -r '
  .requirements |
  if length > 0 then
    "## Requirements\n\n| Name | Version |\n| ---- | ------- |\n" +
    (map("| \(.name) | \(.version // "n/a") |") | join("\n"))
  else "" end
')

# Build resources table
resources=$(echo "$tf_json" | jq -r '
  .resources |
  if length > 0 then
    "## Resources\n\n| Name | Type |\n| ---- | ---- |\n" +
    (map("| \(.type).\(.name) | \(.mode) |") | join("\n"))
  else "" end
')

export TERRAFORM_REQUIREMENTS="$requirements"
export TERRAFORM_PROVIDERS="$providers"
export TERRAFORM_RESOURCES="$resources"
export TERRAFORM_REQUIRED_INPUTS="$required"
export TERRAFORM_OPTIONAL_INPUTS="$optional"
export TERRAFORM_OUTPUTS="$outputs"

# Use local template if it exists, otherwise download shared one
if [ -f "$DOCS_DIR/README.md.gotmpl" ]; then
  TEMPLATE="$DOCS_DIR/README.md.gotmpl"
else
  TEMPLATE=$(mktemp)
  curl -sL https://raw.githubusercontent.com/lsdopen/.github/main/.github/terraform/README.md.gotmpl -o "$TEMPLATE"
fi

export README_YAML="$DOCS_DIR/README.yaml"
gomplate -d config="$DOCS_DIR/README.yaml" -f "$TEMPLATE" -o "./README.md"

# Replace version placeholder (compatible with both macOS and Linux sed)
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s/__VERSION__/$MODULE_VERSION/g" "./README.md"
else
  sed -i "s/__VERSION__/$MODULE_VERSION/g" "./README.md"
fi

# Drop the canonical LICENSE, CONTRIBUTING.md and SECURITY.md into the repo.
# These are org canonical files (single source of truth in .github/terraform/),
# so they are fetched unconditionally to keep every repo in sync — a repo
# needing a variant should diverge deliberately by pinning its own copy and
# removing this sync.
BASE_URL="https://raw.githubusercontent.com/lsdopen/.github/main/.github/terraform"
curl -sL "$BASE_URL/LICENSE" -o "./LICENSE"
curl -sL "$BASE_URL/CONTRIBUTING.md" -o "./CONTRIBUTING.md"
curl -sL "$BASE_URL/SECURITY.md" -o "./SECURITY.md"
