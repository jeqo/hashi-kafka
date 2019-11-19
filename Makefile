.PHONY: all
all:

.PHONY: consul
consul:
	sudo consul agent -dev -client=172.17.0.1 -dns-port=53

.PHONY: vault
vault:	
	sudo vault server -dev --dev-listen-address=172.17.0.1:8200 -dev-root-token-id=root

.PHONY: nomad
nomad:
	sudo nomad agent -dev -bind=172.17.0.1 -network-interface=docker0 \
		-consul-address=172.17.0.1:8500 \
		-vault-enabled=true \
		-vault-address=http://172.17.0.1:8200 \
		-vault-token=root

# -vault-ca-path=root-ca.pem

.PHONY: run-kafka-job
run-kafka-job:
	nomad job run -address=http://172.17.0.1:4646 kafka.nomad

.PHONY: kill-kafka-job
kill-kafka-job:
	nomad job stop -purge -address=http://172.17.0.1:4646 kafka

# Demo Vault Kafka from https://opencredo.com/blogs/securing-kafka-using-vault-pki/
.PHONY: pki
pki: ca-root ca-root-pem ca-root-crl ca-int-kafka ca-int-kafka-csr ca-root-sign-int-kafka ca-int-kafka-set-signed ca-int-kafka-crl

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
.PHONY: pki-roles
pki-roles: pki-role-kafka-client pki-role-kafka-server vault-policy-kafka-client vault-policy-kafka-server

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

.PHONY: truststore
truststore:
	keytool -import -alias root-ca -trustcacerts -file root-ca.pem -keystore kafka-truststore.jks -deststorepass changeme
	keytool -import -alias kafka-int-ca -trustcacerts -file kafka-int-ca.pem -keystore kafka-truststore.jks -deststorepass changeme

# .PHONY: kafka-server-token
# kafka-server-token:
# 	VAULT_TOKEN=$(vault token create -role kafka-server) \
# 	vault write -field certificate kafka-int-ca/issue/kafka-server \
#  		common_name=node-1.servers.kafka.acme.com alt_names=localhost \
#     	format=pem_bundle > node-1.pem