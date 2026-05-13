#!/bin/bash
# Make /workspace world-accessible so the host user can read findings,
# reports, and engagement files without sudo.
# Security boundary is the container itself, not file permissions.
chmod -R 777 /workspace 2>/dev/null || true
# Ensure all NEW files are also world-readable/writable
umask 0000
exec "$@"
