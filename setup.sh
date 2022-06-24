#!/usr/bin/env bash 
set -e

backend="${1:secrets}"

# add some color
GREEN='\033[0;32m'
BOLD='\033[1m'
DEFAULT='\033[0m' # No Color

# enable app role authentication
if [[ ! $(vault auth list --format json | jq '. | keys |  contains(["approle/"])') == "true" ]] ; then
  vault auth enable approle
fi

# prepare vault
if [[ ! $(vault secrets list --format json | jq '. | keys |  contains(["outsystems/"])') == "true" ]] ; then
  vault secrets enable -version=2 -path=outsystems kv
fi

vault policy write outsystems <(cat <<POLICY
path "outsystems/*" {
    policy = "read"
}
POLICY
)

if ! vault read auth/approle/role/outsystems/role-id > /dev/null ; then
  vault write auth/approle/role/outsystems policies=outsystems period=1h
fi

ROLE_ID=$(vault read --format json auth/approle/role/outsystems/role-id | jq -r .data.role_id)
SECRET_ID=$(vault write --format json -f auth/approle/role/outsystems/secret-id | jq -r .data.secret_id)

echo -e "${GREEN}Vault enabled${DEFAULT}"
echo -e "Set ${BOLD}Site.VaultRoleId${DEFAULT} to ${BOLD}${ROLE_ID}${DEFAULT}"
echo -e "Set ${BOLD}Site.VaultSecretId${DEFAULT} to ${BOLD}${SECRET_ID}${DEFAULT}"
