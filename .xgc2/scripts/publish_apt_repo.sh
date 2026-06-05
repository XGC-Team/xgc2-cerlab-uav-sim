#!/usr/bin/env bash
set -euo pipefail

DEB_DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --deb-dir)
      DEB_DIR="$2"
      shift 2
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${DEB_DIR}" ]]; then
  echo "--deb-dir is required" >&2
  exit 1
fi

if [[ -z "${APT_REPO_HOST:-}" || -z "${APT_REPO_PORT:-}" || -z "${APT_REPO_SSH_KEY:-}" || -z "${APT_REPO_KNOWN_HOSTS:-}" ]]; then
  echo "APT repository secrets are not configured; skipping publish"
  exit 0
fi

tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmpdir}"
}
trap cleanup EXIT

key_file="${tmpdir}/apt_repo_key"
known_hosts_file="${tmpdir}/known_hosts"
printf '%s\n' "${APT_REPO_SSH_KEY}" > "${key_file}"
printf '%s\n' "${APT_REPO_KNOWN_HOSTS}" > "${known_hosts_file}"
chmod 0600 "${key_file}" "${known_hosts_file}"

rsync -av \
  -e "ssh -i ${key_file} -p ${APT_REPO_PORT} -o UserKnownHostsFile=${known_hosts_file}" \
  "${DEB_DIR}/" \
  "${APT_REPO_HOST}:incoming/"
