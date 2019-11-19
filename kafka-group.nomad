job "kafka" {
    datacenters = ["dc1"]
    
    vault {
        policies = ["kafka-server"]
       // change_mode   = "signal"
       // change_signal = "SIGUSR1"
    }

    group "cluster" {
        count = 4

        task "server" {
            driver = "docker"

            config {
                image = "confluentinc/cp-kafka:5.3.1"
                command = "sh"
                args = [
                    "-c",
                    "cp ${NOMAD_SECRETS_DIR}/*.credential /etc/kafka/secrets/.;
                    keytool -noprompt -import -alias root-ca -trustcacerts -file ${NOMAD_SECRETS_DIR}/root-ca.pem -keystore /etc/kafka/secrets/kafka-truststore.jks -storepass changeme -keypass changeme;
                    keytool -noprompt -import -alias kafka-int-ca -trustcacerts -file ${NOMAD_SECRETS_DIR}/kafka-int-ca.pem -keystore /etc/kafka/secrets/kafka-truststore.jks -storepass changeme -keypass changeme;
                    openssl pkcs12 -inkey ${NOMAD_SECRETS_DIR}/broker${NOMAD_ALLOC_INDEX}.pem -in ${NOMAD_SECRETS_DIR}/broker${NOMAD_ALLOC_INDEX}.pem -name broker${NOMAD_ALLOC_INDEX} -export -out ${NOMAD_SECRETS_DIR}/broker${NOMAD_ALLOC_INDEX}.p12 -password pass:changeme;
                    keytool -importkeystore -deststorepass changeme -destkeystore /etc/kafka/secrets/broker${NOMAD_ALLOC_INDEX}-keystore.jks  -deststoretype pkcs12 -srckeystore ${NOMAD_SECRETS_DIR}/broker${NOMAD_ALLOC_INDEX}.p12 -srcstoretype PKCS12 -srcstorepass changeme -keypass changeme;
                    /etc/confluent/docker/run"
                ]
            }

            env {
                KAFKA_BROKER_ID = "${NOMAD_ALLOC_INDEX}"
                KAFKA_ZOOKEEPER_CONNECT = "172.17.0.1:12181,172.17.0.1:22181,172.17.0.1:32181"
                KAFKA_ADVERTISED_LISTENERS = "PLAINTEXT://${NOMAD_ADDR_plaintext},SSL://${NOMAD_ADDR_ssl}"
                KAFKA_SSL_KEYSTORE_FILENAME = "broker${NOMAD_ALLOC_INDEX}-keystore.jks"
                KAFKA_SSL_KEYSTORE_CREDENTIALS = "keystore.credential"
                KAFKA_SSL_KEY_CREDENTIALS = "key.credential"
                KAFKA_SSL_TRUSTSTORE_FILENAME = "kafka-truststore.jks"
                KAFKA_SSL_TRUSTSTORE_CREDENTIALS = "truststore.credential"
                KAFKA_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM = " "
                KAFKA_SSL_CLIENT_AUTH = "requested"
                KAFKA_SECURITY_INTER_BROKER_PROTOCOL = "SSL"                
            }

            template {
                data = <<EOH
{{ with secret "root-ca/cert/ca" }}
{{ .Data.certificate }}
{{ end }}
EOH
                destination   = "${NOMAD_SECRETS_DIR}/root-ca.pem"
                change_mode   = "restart"
            }
            
            template {
                data = <<EOH
{{ with secret "kafka-int-ca/cert/ca" }}
{{ .Data.certificate }}
{{ end }}
EOH
                destination   = "${NOMAD_SECRETS_DIR}/kafka-int-ca.pem"
                change_mode   = "restart"
            }
            
            template {
                data = <<EOH
{{ with secret "kafka-int-ca/issue/kafka-server" "common_name=kafka-cluster-broker.service.consul" "alt_names=172.17.0.1" "ip_sans=172.17.0.1" "format=pem" }}
{{ .Data.certificate }}
{{ .Data.issuing_ca }}
{{ .Data.private_key }}
{{ end }}
EOH
                destination   = "${NOMAD_SECRETS_DIR}/broker${NOMAD_ALLOC_INDEX}.pem"
                change_mode   = "restart"
            }
            template {
                data = <<EOH
changeme
EOH
                destination = "${NOMAD_SECRETS_DIR}/keystore.credential"
                change_mode   = "restart"
            }
            template {
                data = <<EOH
changeme
EOH
                destination = "${NOMAD_SECRETS_DIR}/key.credential"
                change_mode   = "restart"
            }
            template {
                data = <<EOH
changeme
EOH
                destination = "${NOMAD_SECRETS_DIR}/truststore.credential"
                change_mode   = "restart"
            }

            resources {
                network {
                    mode = "bridge"
                    port "plaintext" {}
                    port "ssl" {}
                }
            }

            service {
                name = "kafka-cluster",
                port = "ssl"
                tags = [
                    "broker${NOMAD_ALLOC_INDEX}"
                ]
            }
        }
    }
}