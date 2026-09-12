#!/usr/bin/env sh
# Stores (or replaces) a secret in the linked project's Vault without the
# value touching a shell history, a terminal or an agent transcript: it comes
# on stdin, goes into a 0600 temp file for one `db query --file`, and the
# file is removed. Requires `supabase link` and the Management API token in
# the environment, like every other linked command.
#
#   pbpaste | sh supabase/scripts/vault-secret.sh resend_api_key "Resend, sending only, waitlist mail"
set -eu

name="${1:?usage: $0 <name> [description] — the secret on stdin}"
description="${2:-}"

value="$(cat)"
if [ -z "$value" ]; then
  echo "vault-secret: nothing on stdin" >&2
  exit 1
fi
case "$value$name$description" in
  # shellcheck disable=SC2016 # the literal $v$ is the point: it is the SQL dollar-quote tag below.
  *'$v$'*) echo "vault-secret: the value may not contain \$v\$" >&2; exit 1 ;;
esac

tmp="$(mktemp)"
chmod 600 "$tmp"
trap 'rm -f "$tmp"' EXIT

cat > "$tmp" <<SQL
do \$\$
declare
  existing uuid;
begin
  select id into existing from vault.secrets where name = \$v\$${name}\$v\$;
  if existing is null then
    perform vault.create_secret(\$v\$${value}\$v\$, \$v\$${name}\$v\$, \$v\$${description}\$v\$);
  else
    perform vault.update_secret(existing, \$v\$${value}\$v\$, \$v\$${name}\$v\$, \$v\$${description}\$v\$);
  end if;
end \$\$;
SQL

supabase db query --linked --file "$tmp" >/dev/null
echo "vault-secret: '$name' stored in the linked project"
