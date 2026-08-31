#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=versions.env
source "${SCRIPT_DIR}/versions.env"

readonly FABRIC_SKILLS_REPOSITORY="https://github.com/microsoft/skills-for-fabric.git"
readonly FABRIC_MARKETPLACE_PARENT="${XDG_DATA_HOME:-${HOME}/.local/share}/fabric-handson-lab"
readonly FABRIC_MARKETPLACE_DIR="${FABRIC_MARKETPLACE_PARENT}/skills-for-fabric-${FABRIC_SKILLS_TAG}"

cleanup_paths=()

cleanup() {
  local path
  for path in "${cleanup_paths[@]}"; do
    if [[ -d "${path}" ]]; then
      rm -rf -- "${path}"
    fi
  done
}

trap cleanup EXIT

log() {
  printf '\n==> %s\n' "$*"
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

for required_command in npm jq curl git sudo sha256sum tar mktemp install grep; do
  require_command "${required_command}"
done

install_npm_tools() {
  local global_packages_json package_name expected_version current_version
  local needs_install=0

  global_packages_json="$(npm list --global --depth=0 --json 2>/dev/null)" || global_packages_json='{}'

  while IFS='=' read -r package_name expected_version; do
    current_version="$(
      jq -r --arg package "${package_name}" '.dependencies[$package].version // ""' \
        <<<"${global_packages_json}"
    )"
    if [[ "${current_version}" != "${expected_version}" ]]; then
      needs_install=1
    fi
  done <<EOF
@github/copilot=${COPILOT_CLI_VERSION}
@microsoft/rayfin-cli=${RAYFIN_CLI_VERSION}
@microsoft/powerbi-report-authoring-cli=${POWERBI_AUTHORING_CLI_VERSION}
EOF

  if ((needs_install == 0)); then
    log "Pinned npm CLI tools are already installed"
    return
  fi

  local npm_prefix
  npm_prefix="$(npm config get prefix)"
  [[ -w "${npm_prefix}" ]] || die "npm global prefix is not writable: ${npm_prefix}"

  log "Installing pinned npm CLI tools"
  npm install --global --no-audit --no-fund \
    "@github/copilot@${COPILOT_CLI_VERSION}" \
    "@microsoft/rayfin-cli@${RAYFIN_CLI_VERSION}" \
    "@microsoft/powerbi-report-authoring-cli@${POWERBI_AUTHORING_CLI_VERSION}"
}

install_sqlcmd() {
  local architecture asset checksum sqlcmd_temp archive

  if command -v sqlcmd >/dev/null 2>&1 &&
    sqlcmd --version 2>/dev/null | grep -Fq "Version: v${SQLCMD_VERSION}"; then
    log "go-sqlcmd v${SQLCMD_VERSION} is already installed"
    return
  fi

  architecture="$(uname -m)"
  case "${architecture}" in
    x86_64 | amd64)
      asset="sqlcmd-linux-amd64.tar.bz2"
      checksum="${SQLCMD_AMD64_SHA256}"
      ;;
    aarch64 | arm64)
      asset="sqlcmd-linux-arm64.tar.bz2"
      checksum="${SQLCMD_ARM64_SHA256}"
      ;;
    *)
      die "Unsupported CPU architecture for go-sqlcmd: ${architecture}"
      ;;
  esac

  sqlcmd_temp="$(mktemp -d)"
  cleanup_paths+=("${sqlcmd_temp}")
  archive="${sqlcmd_temp}/${asset}"

  log "Installing go-sqlcmd v${SQLCMD_VERSION} for ${architecture}"
  curl --fail --silent --show-error --location \
    "https://github.com/microsoft/go-sqlcmd/releases/download/v${SQLCMD_VERSION}/${asset}" \
    --output "${archive}"
  printf '%s  %s\n' "${checksum}" "${archive}" | sha256sum --check -
  tar -xjf "${archive}" -C "${sqlcmd_temp}" sqlcmd
  sudo install -m 0755 "${sqlcmd_temp}/sqlcmd" /usr/local/bin/sqlcmd
}

prepare_fabric_marketplace() {
  local marketplace_clone_temp actual_commit marketplace_list expected_source

  mkdir -p "${FABRIC_MARKETPLACE_PARENT}"

  if [[ ! -d "${FABRIC_MARKETPLACE_DIR}/.git" ]]; then
    [[ ! -e "${FABRIC_MARKETPLACE_DIR}" ]] ||
      die "Marketplace path exists but is not a Git checkout: ${FABRIC_MARKETPLACE_DIR}"

    marketplace_clone_temp="$(mktemp -d "${FABRIC_MARKETPLACE_PARENT}/.skills-for-fabric.XXXXXX")"
    cleanup_paths+=("${marketplace_clone_temp}")

    log "Cloning skills-for-fabric ${FABRIC_SKILLS_TAG}"
    GIT_TERMINAL_PROMPT=0 git \
      -c advice.detachedHead=false \
      -c credential.helper= \
      clone --quiet --depth 1 \
      --branch "${FABRIC_SKILLS_TAG}" \
      "${FABRIC_SKILLS_REPOSITORY}" \
      "${marketplace_clone_temp}"

    actual_commit="$(git -C "${marketplace_clone_temp}" rev-parse HEAD)"
    [[ "${actual_commit}" == "${FABRIC_SKILLS_COMMIT}" ]] ||
      die "Unexpected skills-for-fabric commit: ${actual_commit}"

    mv -- "${marketplace_clone_temp}" "${FABRIC_MARKETPLACE_DIR}"
  fi

  actual_commit="$(git -C "${FABRIC_MARKETPLACE_DIR}" rev-parse HEAD)"
  [[ "${actual_commit}" == "${FABRIC_SKILLS_COMMIT}" ]] ||
    die "Pinned marketplace commit drifted: ${actual_commit}"
  [[ -z "$(git -C "${FABRIC_MARKETPLACE_DIR}" status --porcelain)" ]] ||
    die "Pinned marketplace has local modifications: ${FABRIC_MARKETPLACE_DIR}"

  marketplace_list="$(copilot plugin marketplace list)"
  expected_source="fabric-collection (Local: ${FABRIC_MARKETPLACE_DIR})"

  if ! grep -Fq "${expected_source}" <<<"${marketplace_list}"; then
    if grep -Fq "fabric-collection (" <<<"${marketplace_list}"; then
      log "Replacing the existing fabric-collection marketplace"
      copilot plugin marketplace remove fabric-collection --force
    fi

    log "Registering the pinned Fabric marketplace"
    copilot plugin marketplace add "${FABRIC_MARKETPLACE_DIR}"
  fi

  log "Enabling pinned Fabric Copilot plugins"
  copilot plugin install fabric-skills@fabric-collection
  copilot plugin install powerbi-authoring@fabric-collection
}

install_npm_tools
install_sqlcmd
prepare_fabric_marketplace

log "Dev Container tool setup completed"
