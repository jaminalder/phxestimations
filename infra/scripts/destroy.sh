#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TERRAFORM_DIR="$ROOT_DIR/infra/terraform"
ENV_FILE="$ROOT_DIR/infra/compose/.env"

DELETE_ENV="false"
AUTO_APPROVE="false"

usage() {
  cat <<'EOF'
Usage:
  ./infra/scripts/destroy.sh [--delete-env] [--auto-approve]

Options:
  --delete-env    Delete infra/compose/.env after destroying infrastructure
  --auto-approve  Run terraform destroy without interactive confirmation
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --delete-env)
    DELETE_ENV="true"
    shift
    ;;
  --auto-approve)
    AUTO_APPROVE="true"
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown argument: $1" >&2
    usage
    exit 1
    ;;
  esac
done

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

require_cmd terraform

if [[ ! -d "$TERRAFORM_DIR" ]]; then
  echo "Missing Terraform directory: $TERRAFORM_DIR" >&2
  exit 1
fi

echo "==> Checking current Terraform state"
if ! terraform -chdir="$TERRAFORM_DIR" state list >/dev/null 2>&1; then
  echo "Terraform state is not accessible. Run terraform init first if needed." >&2
  exit 1
fi

echo "==> Current resources in state:"
terraform -chdir="$TERRAFORM_DIR" state list || true
echo

echo "==> Planned destroy:"
terraform -chdir="$TERRAFORM_DIR" plan -destroy

echo
if [[ "$AUTO_APPROVE" == "true" ]]; then
  echo "==> Destroying infrastructure (auto-approve)"
  terraform -chdir="$TERRAFORM_DIR" destroy -auto-approve
else
  echo "==> Destroying infrastructure"
  terraform -chdir="$TERRAFORM_DIR" destroy
fi

if [[ "$DELETE_ENV" == "true" ]]; then
  if [[ -f "$ENV_FILE" ]]; then
    echo "==> Deleting $ENV_FILE"
    rm -f "$ENV_FILE"
  else
    echo "==> No .env file found at $ENV_FILE"
  fi
else
  if [[ -f "$ENV_FILE" ]]; then
    echo "==> Keeping $ENV_FILE"
    echo "    Note: PHX_HOST in it may be stale after the next reprovision."
  fi
fi

echo
echo "Destroy finished."
