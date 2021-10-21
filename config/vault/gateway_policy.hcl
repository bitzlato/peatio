# Decrypt blockchain nodes secrets
path "transit/decrypt/bitzlato_blockchain_addresses_*" {
  capabilities = ["create", "read", "update"]
}
# Encrypt blockchain nodes secrets
path "transit/encrypt/bitzlato_blockchain_addresses_*" {
  capabilities = ["create", "read", "update"]
}
# Renew tokens
path "auth/token/renew" {
  capabilities = ["update"]
}
# Lookup tokens
path "auth/token/lookup" {
  capabilities = ["update"]
}
