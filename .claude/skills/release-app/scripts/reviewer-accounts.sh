#!/usr/bin/env bash
# (Re)creates the two store reviewer accounts in the hosted Supabase project,
# idempotently, with the password from ~/.config/emotely/reviewer-accounts.env
# (generated on first run). Run before every store submission: a reviewer who
# tests "Delete account" really deletes the account.
#
# Prints status lines only. Never echoes the password, the service_role key
# or any response body — the repo is public and sessions are recorded.
set -euo pipefail

PROJECT_REF="${SUPABASE_PROJECT_REF:-khfkszlujgkfjgnawdlf}"
API="https://${PROJECT_REF}.supabase.co/auth/v1/admin/users"
ENV_FILE="${REVIEWER_ACCOUNTS_ENV:-$HOME/.config/emotely/reviewer-accounts.env}"
ACCOUNTS=(google-play-review@getemotely.com app-store-review@getemotely.com)

for tool in supabase jq curl openssl; do
  command -v "$tool" >/dev/null || { echo "missing: $tool" >&2; exit 1; }
done

# --- the password: read it, or mint one and keep it (mode 600) -------------
if [[ -f "$ENV_FILE" ]]; then
  REVIEWER_PASSWORD="$(sed -n 's/^REVIEWER_PASSWORD=//p' "$ENV_FILE" | head -1)"
fi
if [[ -z "${REVIEWER_PASSWORD:-}" ]]; then
  # 24 characters that are safe to type on a phone: base64 minus +/=.
  REVIEWER_PASSWORD="$(openssl rand -base64 36 | tr -d '+/=\n' | cut -c1-24)"
  (umask 077; mkdir -p "$(dirname "$ENV_FILE")"
   printf 'REVIEWER_PASSWORD=%s\n' "$REVIEWER_PASSWORD" > "$ENV_FILE")
  echo "password: generated and written to $ENV_FILE (add it to iCloud Passwords)"
else
  echo "password: read from $ENV_FILE"
fi

# --- the service_role key, blind ------------------------------------------
SERVICE_ROLE="$(supabase projects api-keys --project-ref "$PROJECT_REF" -o json \
  | jq -r '.[] | select(.name == "service_role") | .api_key')"
[[ -n "$SERVICE_ROLE" ]] || { echo "service_role key: not found" >&2; exit 1; }
echo "service_role key: obtained (${#SERVICE_ROLE} chars)"

BODY="$(mktemp)"
trap 'rm -f "$BODY"' EXIT

# admin <method> <url> [json on stdin for POST/PUT] -> prints the status,
# leaves the body in $BODY. The key travels only in headers.
admin() {
  local data=()
  [[ "$1" == GET ]] || data=(--data-binary @-)
  # `${data[@]+...}`: macOS bash 3.2 calls an empty array unbound under -u.
  curl -sS -o "$BODY" -w '%{http_code}' -X "$1" "$2" \
    -H "apikey: $SERVICE_ROLE" -H "Authorization: Bearer $SERVICE_ROLE" \
    -H 'Content-Type: application/json' ${data[@]+"${data[@]}"}
}

for email in "${ACCOUNTS[@]}"; do
  # shellcheck disable=SC2016 # a jq program; $email/$password are jq args
  user='{email: $email, password: $password, email_confirm: true,
         app_metadata: {review_account: true}}'
  status="$(jq -n --arg email "$email" --arg password "$REVIEWER_PASSWORD" \
    "$user" | admin POST "$API")"
  if [[ "$status" == 200 ]]; then
    echo "$email: created ($status)"
    continue
  fi
  if ! jq -e '(.error_code // "") == "email_exists"
              or ((.msg // .message // "") | test("already been registered"))' \
      "$BODY" >/dev/null 2>&1; then
    echo "$email: create failed ($status)" >&2
    exit 1
  fi
  echo "$email: exists ($status), resetting the password"
  status="$(admin GET "$API?filter=$email&per_page=50")"
  [[ "$status" == 200 ]] || { echo "$email: lookup failed ($status)" >&2; exit 1; }
  id="$(jq -r --arg email "$email" \
    '.users[] | select(.email == $email) | .id' "$BODY")"
  [[ -n "$id" ]] || { echo "$email: exists but not found by lookup" >&2; exit 1; }
  status="$(jq -n --arg password "$REVIEWER_PASSWORD" \
    '{password: $password, email_confirm: true,
      app_metadata: {review_account: true}}' | admin PUT "$API/$id")"
  [[ "$status" == 200 ]] || { echo "$email: update failed ($status)" >&2; exit 1; }
  echo "$email: password set ($status)"
done
echo "done: both reviewer accounts sign in with the password in $ENV_FILE"
