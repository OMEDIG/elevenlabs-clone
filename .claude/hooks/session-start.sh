#!/bin/bash
# SessionStart hook: install dependencies so linters, type-checks, and builds
# work in Claude Code on the web sessions.
set -euo pipefail

# Only run in the remote (Claude Code on the web) environment.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
FRONTEND_DIR="$PROJECT_DIR/elevenlabs-clone-frontend"

# Install Next.js / T3 frontend dependencies.
# Use `npm install` (not `npm ci`) so the cached container state is reused
# across sessions. The package.json `postinstall` runs `prisma generate`.
# Redirect install output to stderr: for SessionStart hooks, stdout is added
# to the model's context, and we don't want npm/prisma logs polluting it.
if [ -d "$FRONTEND_DIR" ]; then
  cd "$FRONTEND_DIR"
  npm install 1>&2
fi

# Allow `next build` to run without populated secrets in dev sessions.
# Only append if not already present so repeated runs stay idempotent.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  if ! grep -qE '^\s*(export\s+)?SKIP_ENV_VALIDATION=' "$CLAUDE_ENV_FILE" 2>/dev/null; then
    echo 'export SKIP_ENV_VALIDATION=1' >> "$CLAUDE_ENV_FILE"
  fi
fi
