
## Install vault token for gateways

```
export VAULT_CONTAINER=$(docker ps | grep vault | awk '{print $NF}')
docker cp ./config/vault/gateway_policy.hcl $(VAULT_CONTAINER):/ && vault policy write bitzlato-gateways /gateway_policy.hcl && vault policy read bitzlato-gateways
docker exec -it $(VAULT_CONTAINER) vault token create -policy=bitzlato-gateways -period=240h
```

## Import private keys


```
rake import:private_key\['private_key_file_path','secret'\]                                                                     
rake import:primate_keys\['private_keys_dir_path'\]
```
