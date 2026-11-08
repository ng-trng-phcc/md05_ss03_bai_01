#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Error: setup-workspace.sh must be run as root." >&2
  exit 1
fi

GROUP_NAME="rikkeilms"
USER_NAME="rikkeilms"
WORKSPACE="/opt/rikkei/course-service"

if getent group "$GROUP_NAME" >/dev/null 2>&1; then
  echo "Group already exists: $GROUP_NAME"
else
  groupadd "$GROUP_NAME"
  echo "Created group: $GROUP_NAME"
fi

if id -u "$USER_NAME" >/dev/null 2>&1; then
  echo "User already exists: $USER_NAME"
else
  useradd --create-home --gid "$GROUP_NAME" --shell /bin/bash "$USER_NAME"
  echo "Created user: $USER_NAME"
fi

PRIMARY_GROUP="$(id -gn "$USER_NAME")"
if [[ "$PRIMARY_GROUP" != "$GROUP_NAME" ]]; then
  usermod --gid "$GROUP_NAME" "$USER_NAME"
  echo "Updated primary group for $USER_NAME to $GROUP_NAME"
else
  echo "Primary group already correct: $USER_NAME -> $GROUP_NAME"
fi

mkdir -p "$WORKSPACE"
chown "$USER_NAME:$GROUP_NAME" "$WORKSPACE"
chmod 755 "$WORKSPACE"

OWNER="$(stat -c '%U' "$WORKSPACE")"
GROUP="$(stat -c '%G' "$WORKSPACE")"
PERMS="$(stat -c '%a' "$WORKSPACE")"

echo "Workspace: $WORKSPACE"
echo "Owner: $OWNER"
echo "Group: $GROUP"
echo "Permissions: $PERMS"

if [[ "$OWNER" != "$USER_NAME" || "$GROUP" != "$GROUP_NAME" || "$PERMS" != "755" ]]; then
  echo "Error: workspace verification failed; expected $USER_NAME $GROUP_NAME 755." >&2
  exit 1
fi

if (( (8#$PERMS & 8#200) == 0 )); then
  echo "Error: owner does not have write permission." >&2
  exit 1
fi

if (( (8#$PERMS & 8#022) != 0 )); then
  echo "Error: group or others have write permission." >&2
  exit 1
fi

echo "Verification successful: $OWNER $GROUP $PERMS"
