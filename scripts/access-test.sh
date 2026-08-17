#!/usr/bin/env bash
set -euo pipefail

URL="${1:-https://secure.lax-man.in}"
EXPECTED="${EXPECTED_STATUS:-200,302,401,403}"
COOKIE_JAR="${COOKIE_JAR:-}"
ARGS=(--silent --show-error --output /dev/null --write-out '%{http_code}' --max-time 20)
[[ -n "$COOKIE_JAR" ]] && ARGS+=(--cookie "$COOKIE_JAR" --cookie-jar "$COOKIE_JAR")
CODE="$(curl "${ARGS[@]}" "$URL")"

if [[ ",$EXPECTED," == *",$CODE,"* ]]; then
  echo "$URL returned expected HTTP $CODE."
else
  echo "$URL returned HTTP $CODE; expected one of $EXPECTED." >&2
  exit 1
fi
