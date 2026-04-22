#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TERRAFORM_DIR="$ROOT_DIR/infra/terraform"
COMPOSE_DIR="$ROOT_DIR/infra/compose"
REMOTE_DIR="/opt/phxestimations"
IMAGE_NAME="phxestimations:latest"
IMAGE_ARCHIVE="/tmp/phxestimations.tar.gz"
ENV_FILE="$COMPOSE_DIR/.env"
ENV_EXAMPLE_FILE="$COMPOSE_DIR/.env.example"

APPLY_INFRA="false"
FORCE_REGENERATE_ENV="false"

SSH_OPTS=(
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o ConnectTimeout=5
)

usage() {
  cat <<'EOF'
Usage:
  ./infra/scripts/deploy.sh [--apply-infra] [--force-regenerate-env]

Options:
  --apply-infra           Run terraform apply before deploying
  --force-regenerate-env  Recreate infra/compose/.env from template and overwrite existing values
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --apply-infra)
    APPLY_INFRA="true"
    shift
    ;;
  --force-regenerate-env)
    FORCE_REGENERATE_ENV="true"
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
require_cmd docker
require_cmd ssh
require_cmd scp
require_cmd gzip
require_cmd openssl
require_cmd python3

if [[ ! -f "$COMPOSE_DIR/compose.yaml" ]]; then
  echo "Missing $COMPOSE_DIR/compose.yaml" >&2
  exit 1
fi

if [[ ! -f "$ENV_EXAMPLE_FILE" ]]; then
  echo "Missing $ENV_EXAMPLE_FILE" >&2
  exit 1
fi

create_env_file() {
  local secret_key_base
  secret_key_base="$(openssl rand -hex 64)"

  echo "==> Creating $ENV_FILE"
  cp "$ENV_EXAMPLE_FILE" "$ENV_FILE"

  python3 - "$ENV_FILE" "$SERVER_IP" "$secret_key_base" <<'PY'
import sys
from pathlib import Path

env_path = Path(sys.argv[1])
server_ip = sys.argv[2]
secret = sys.argv[3]

content = env_path.read_text()

replacements = {
    "PHX_HOST=YOUR_SERVER_IP": f"PHX_HOST={server_ip}",
    "SECRET_KEY_BASE=CHANGE_ME": f"SECRET_KEY_BASE={secret}",
}

for old, new in replacements.items():
    content = content.replace(old, new)

env_path.write_text(content)
PY
}

wait_for_ssh() {
  echo "==> Waiting for SSH connectivity"
  for i in {1..30}; do
    if ssh "${SSH_OPTS[@]}" -o BatchMode=yes "root@$SERVER_IP" 'echo SSH OK' >/dev/null 2>&1; then
      echo "SSH is available."
      return 0
    fi

    if [[ "$i" -eq 30 ]]; then
      echo "SSH did not become available in time." >&2
      return 1
    fi

    echo "SSH not ready yet, retrying in 5 seconds..."
    sleep 5
  done
}

if [[ "$APPLY_INFRA" == "true" ]]; then
  echo "==> Applying Terraform"
  (
    cd "$TERRAFORM_DIR"
    terraform init
    terraform apply -auto-approve
  )
fi

echo "==> Reading server IP from Terraform"
SERVER_IP="$(
  cd "$TERRAFORM_DIR" &&
    terraform output -raw server_ip
)"

if [[ -z "$SERVER_IP" ]]; then
  echo "Could not determine server IP from Terraform output." >&2
  exit 1
fi

echo "==> Server IP: $SERVER_IP"

if [[ "$FORCE_REGENERATE_ENV" == "true" ]]; then
  create_env_file
elif [[ ! -f "$ENV_FILE" ]]; then
  create_env_file
else
  echo "==> Using existing $ENV_FILE"
fi

wait_for_ssh

echo "==> Ensuring Docker is installed on server"
ssh "${SSH_OPTS[@]}" "root@$SERVER_IP" 'bash -s' <<'EOF'
set -euo pipefail

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  echo "Docker and Compose already installed."
  exit 0
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y ca-certificates curl gnupg

install -m 0755 -d /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
fi

. /etc/os-release
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $VERSION_CODENAME stable" > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable docker
systemctl start docker
docker version
docker compose version
EOF

echo "==> Building Docker image locally"
(
  cd "$ROOT_DIR"
  docker build -t "$IMAGE_NAME" .
)

echo "==> Exporting Docker image"
rm -f "$IMAGE_ARCHIVE"
docker save "$IMAGE_NAME" | gzip >"$IMAGE_ARCHIVE"

echo "==> Creating remote deploy directory"
ssh "${SSH_OPTS[@]}" "root@$SERVER_IP" "mkdir -p '$REMOTE_DIR'"

echo "==> Copying image and compose files"
scp "${SSH_OPTS[@]}" "$IMAGE_ARCHIVE" "root@$SERVER_IP:/root/phxestimations.tar.gz"
scp "${SSH_OPTS[@]}" "$COMPOSE_DIR/compose.yaml" "root@$SERVER_IP:$REMOTE_DIR/compose.yaml"
scp "${SSH_OPTS[@]}" "$ENV_FILE" "root@$SERVER_IP:$REMOTE_DIR/.env"

echo "==> Loading image and starting application"
ssh "${SSH_OPTS[@]}" "root@$SERVER_IP" 'bash -s' <<EOF
set -euo pipefail

gunzip -c /root/phxestimations.tar.gz | docker load
cd "$REMOTE_DIR"
docker compose up -d
docker compose ps
EOF

echo
echo "Deploy finished."
echo "App should be available at: http://$SERVER_IP:4000"
echo "Env file used: $ENV_FILE"
