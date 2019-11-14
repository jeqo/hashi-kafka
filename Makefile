.PHONY: all
all:

.PHONY: ca-root
ca-root:
	vault secrets enable -path root-ca pki
	vault secrets tune -max-lease-ttl=8760h root-ca

.PHONY: ca-root-pem
ca-root-pem:
	vault write -field certificate root-ca/root/generate/internal \
    	common_name="Acme Root CA" \
    	ttl=8760h > root-ca.pem

.PHONY: ca-root-crl
ca-root-crl:
	vault write root-ca/config/urls \
 	   issuing_certificates="${VAULT_ADDR}/v1/root-ca/ca" \
 	   crl_distribution_points="${VAULT_ADDR}/v1/root-ca/crl"

.PHONY: ca-int-kafka
ca-int-kafka:
	vault secrets enable -path kafka-int-ca pki
	vault secrets tune -max-lease-ttl=8760h kafka-int-ca

.PHONY: ca-int-kafka-csr
ca-int-kafka-csr:
	vault write -field=csr kafka-int-ca/intermediate/generate/internal \
 	   common_name="Acme Kafka Intermediate CA" ttl=43800h > kafka-int-ca.csr

.PHONY: ca-root-sign-int-kafka
ca-root-sign-int-kafka:
	vault write -field=certificate root-ca/root/sign-intermediate csr=@kafka-int-ca.csr \
 	   format=pem_bundle ttl=43800h > kafka-int-ca.pem

.PHONY: ca-int-kafka-set-signed
ca-int-kafka-set-signed:
	vault write kafka-int-ca/intermediate/set-signed certificate=@kafka-int-ca.pem

.PHONY: ca-int-kafka-crl
ca-int-kafka-crl:
	vault write kafka-int-ca/config/urls issuing_certificates="${VAULT_ADDR}/v1/kafka-int-ca/ca" \
 	   crl_distribution_points="${VAULT_ADDR}/v1/kafka-int-ca/crl"

# up to this point CAs should be up and running

## PKI roles

.PHONY: pki-role-kafka-client
pki-role-kafka-client:
	vault write kafka-int-ca/roles/kafka-client \
    	allowed_domains=clients.kafka.acme.com \
    	allow_subdomains=true max_ttl=72h

.PHONY: pki-role-kafka-server
pki-role-kafka-server:
	vault write kafka-int-ca/roles/kafka-server \
	    allowed_domains=servers.kafka.acme.com \
	    allow_subdomains=true max_ttl=72h

.PHONY: vault-policy-kafka-client
vault-policy-kafka-client:
	vault policy write kafka-client vault/kafka-client.hcl
	vault write auth/token/roles/kafka-client \
 	   allowed_policies=kafka-client period=24h

.PHONY: vault-policy-kafka-server
vault-policy-kafka-server:
	vault policy write kafka-server vault/kafka-server.hcl
	vault write auth/token/roles/kafka-server \
 	   allowed_policies=kafka-server period=24h

## Java security configuration

.PHONY: kafka-server-token
kafka-server-token:
	VAULT_TOKEN=$(vault token create -role kafka-server) \
	vault write -field certificate kafka-int-ca/issue/kafka-server \
 		common_name=node-1.servers.kafka.acme.com alt_names=localhost \
    	format=pem_bundle > node-1.pem