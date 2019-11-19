job "kafka" {
    datacenters = ["dc1"]
    
    vault {
        policies = ["kafka-server"]
       // change_mode   = "signal"
       // change_signal = "SIGUSR1"
    }

    group "broker1" {
        task "server" {
            driver = "docker"

            config {
                image = "confluentinc/cp-kafka:5.3.1"
                command = "sh"
                args = [
                    "-c",
                    "cp /local/*.credential /etc/kafka/secrets/.;
                    keytool -noprompt -import -alias root-ca -trustcacerts -file /local/root-ca.pem -keystore /etc/kafka/secrets/kafka-truststore.jks -storepass changeme -keypass changeme;
                    keytool -noprompt -import -alias kafka-int-ca -trustcacerts -file /local/kafka-int-ca.pem -keystore /etc/kafka/secrets/kafka-truststore.jks -storepass changeme -keypass changeme;
                    openssl pkcs12 -inkey /local/node-1.pem -in /local/node-1.pem -name node-1 -export -out /local/node-1.p12 -password pass:changeme;
                    keytool -importkeystore -deststorepass changeme -destkeystore /etc/kafka/secrets/node-1-keystore.jks  -deststoretype pkcs12 -srckeystore /local/node-1.p12 -srcstoretype PKCS12 -srcstorepass changeme -keypass changeme;
                    /etc/confluent/docker/run"
                ]
            }

            env {
                KAFKA_BROKER_ID = "1"
                KAFKA_ZOOKEEPER_CONNECT = "172.17.0.1:12181,172.17.0.1:22181,172.17.0.1:32181"
                KAFKA_ADVERTISED_LISTENERS = "PLAINTEXT://${NOMAD_ADDR_plaintext},SSL://${NOMAD_ADDR_ssl}"
                KAFKA_SSL_KEYSTORE_FILENAME = "node-1-keystore.jks"
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
                // destination   = "${NOMAD_SECRETS_DIR}/node-1.pem"
                destination   = "/local/root-ca.pem"
                change_mode   = "restart"
            }
            
            template {
                data = <<EOH
{{ with secret "kafka-int-ca/cert/ca" }}
{{ .Data.certificate }}
{{ end }}
EOH
                // destination   = "${NOMAD_SECRETS_DIR}/node-1.pem"
                destination   = "/local/kafka-int-ca.pem"
                change_mode   = "restart"
            }
            
            template {
                data = <<EOH
{{ with secret "kafka-int-ca/issue/kafka-server" "common_name=node-1.servers.kafka.acme.com" "alt_names=localhost" "format=pem" }}
{{ .Data.certificate }}
{{ .Data.issuing_ca }}
{{ .Data.private_key }}
{{ end }}
EOH
                // destination   = "${NOMAD_SECRETS_DIR}/node-1.pem"
                destination   = "/local/node-1.pem"
                change_mode   = "restart"
            }
            template {
                data = <<EOH
changeme
EOH
                destination = "/local/keystore.credential"
                change_mode   = "restart"
            }
            template {
                data = <<EOH
changeme
EOH
                destination = "/local/key.credential"
                change_mode   = "restart"
            }
            template {
                data = <<EOH
changeme
EOH
                destination = "/local/truststore.credential"
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
                    "broker1"
                ]
            }
        }
    }

    group "broker2" {
        task "server" {
            driver = "docker"

            config {
                image = "confluentinc/cp-kafka:5.3.1"
                command = "sh"
                args = [
                    "-c",
                    "cp /local/*.credential /etc/kafka/secrets/.;
                    keytool -noprompt -import -alias root-ca -trustcacerts -file /local/root-ca.pem -keystore /etc/kafka/secrets/kafka-truststore.jks -storepass changeme -keypass changeme;
                    keytool -noprompt -import -alias kafka-int-ca -trustcacerts -file /local/kafka-int-ca.pem -keystore /etc/kafka/secrets/kafka-truststore.jks -storepass changeme -keypass changeme;
                    openssl pkcs12 -inkey /local/node-2.pem -in /local/node-2.pem -name node-2 -export -out /local/node-2.p12 -password pass:changeme;
                    keytool -importkeystore -deststorepass changeme -destkeystore /etc/kafka/secrets/node-2-keystore.jks  -deststoretype pkcs12 -srckeystore /local/node-2.p12 -srcstoretype PKCS12 -srcstorepass changeme -keypass changeme;
                    /etc/confluent/docker/run"
                ]
            }
            
            template {
                data = <<EOH
{{ with secret "root-ca/cert/ca" }}
{{ .Data.certificate }}
{{ end }}
EOH
                // destination   = "${NOMAD_SECRETS_DIR}/node-1.pem"
                destination   = "/local/root-ca.pem"
                change_mode   = "restart"
            }
            
            template {
                data = <<EOH
{{ with secret "kafka-int-ca/cert/ca" }}
{{ .Data.certificate }}
{{ end }}
EOH
                // destination   = "${NOMAD_SECRETS_DIR}/node-1.pem"
                destination   = "/local/kafka-int-ca.pem"
                change_mode   = "restart"
            }
            
            template {
                data = <<EOH
{{ with secret "kafka-int-ca/issue/kafka-server" "common_name=node-2.servers.kafka.acme.com" "alt_names=localhost" "format=pem" }}
{{ .Data.certificate }}
{{ .Data.issuing_ca }}
{{ .Data.private_key }}
{{ end }}
EOH
                // destination   = "${NOMAD_SECRETS_DIR}/node-1.pem"
                destination   = "/local/node-2.pem"
                change_mode   = "restart"
            }

            template {
                data = <<EOH
changeme
EOH
                destination = "/local/keystore.credential"
                change_mode   = "restart"
            }
            template {
                data = <<EOH
changeme
EOH
                destination = "/local/key.credential"
                change_mode   = "restart"
            }
            template {
                data = <<EOH
changeme
EOH
                destination = "/local/truststore.credential"
                change_mode   = "restart"
            }

            env {
                KAFKA_BROKER_ID = "2"                
                KAFKA_ZOOKEEPER_CONNECT = "172.17.0.1:12181,172.17.0.1:22181,172.17.0.1:32181"
                KAFKA_ADVERTISED_LISTENERS = "PLAINTEXT://${NOMAD_ADDR_plaintext},SSL://${NOMAD_ADDR_ssl}"
                KAFKA_SSL_KEYSTORE_FILENAME = "node-2-keystore.jks"
                KAFKA_SSL_KEYSTORE_CREDENTIALS = "keystore.credential"
                KAFKA_SSL_KEY_CREDENTIALS = "key.credential"
                KAFKA_SSL_TRUSTSTORE_FILENAME = "kafka-truststore.jks"
                KAFKA_SSL_TRUSTSTORE_CREDENTIALS = "truststore.credential"
                KAFKA_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM = " "
                KAFKA_SSL_CLIENT_AUTH = "requested"
                KAFKA_SECURITY_INTER_BROKER_PROTOCOL = "SSL"
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
                    "broker2"
                ]
            }
        }
    }

    group "broker3" {
        task "server" {
            driver = "docker"

            config {
                image = "confluentinc/cp-kafka:5.3.1"
                command = "sh"
                args = [
                    "-c",
                    "cp /local/*.credential /etc/kafka/secrets/.;
                    keytool -noprompt -import -alias root-ca -trustcacerts -file /local/root-ca.pem -keystore /etc/kafka/secrets/kafka-truststore.jks -storepass changeme -keypass changeme;
                    keytool -noprompt -import -alias kafka-int-ca -trustcacerts -file /local/kafka-int-ca.pem -keystore /etc/kafka/secrets/kafka-truststore.jks -storepass changeme -keypass changeme;
                    openssl pkcs12 -inkey /local/node-3.pem -in /local/node-3.pem -name node-3 -export -out /local/node-3.p12 -password pass:changeme;
                    keytool -importkeystore -deststorepass changeme -destkeystore /etc/kafka/secrets/node-3-keystore.jks  -deststoretype pkcs12 -srckeystore /local/node-3.p12 -srcstoretype PKCS12 -srcstorepass changeme -keypass changeme;
                    /etc/confluent/docker/run"
                ]
            }
            
            template {
                data = <<EOH
{{ with secret "root-ca/cert/ca" }}
{{ .Data.certificate }}
{{ end }}
EOH
                // destination   = "${NOMAD_SECRETS_DIR}/node-1.pem"
                destination   = "/local/root-ca.pem"
                change_mode   = "restart"
            }
            
            template {
                data = <<EOH
{{ with secret "kafka-int-ca/cert/ca" }}
{{ .Data.certificate }}
{{ end }}
EOH
                // destination   = "${NOMAD_SECRETS_DIR}/node-1.pem"
                destination   = "/local/kafka-int-ca.pem"
                change_mode   = "restart"
            }
            
            template {
                data = <<EOH
{{ with secret "kafka-int-ca/issue/kafka-server" "common_name=node-3.servers.kafka.acme.com" "alt_names=localhost" "format=pem" }}
{{ .Data.certificate }}
{{ .Data.issuing_ca }}
{{ .Data.private_key }}
{{ end }}
EOH
                // destination   = "${NOMAD_SECRETS_DIR}/node-1.pem"
                destination   = "/local/node-3.pem"
                change_mode   = "restart"
            }

            template {
                data = <<EOH
changeme
EOH
                destination = "/local/keystore.credential"
                change_mode   = "restart"
            }
            template {
                data = <<EOH
changeme
EOH
                destination = "/local/key.credential"
                change_mode   = "restart"
            }
            template {
                data = <<EOH
changeme
EOH
                destination = "/local/truststore.credential"
                change_mode   = "restart"
            }

            env {
                KAFKA_BROKER_ID = "3"                
                KAFKA_ZOOKEEPER_CONNECT = "172.17.0.1:12181,172.17.0.1:22181,172.17.0.1:32181"
                KAFKA_ADVERTISED_LISTENERS = "PLAINTEXT://${NOMAD_ADDR_plaintext},SSL://${NOMAD_ADDR_ssl}"
                KAFKA_SSL_KEYSTORE_FILENAME = "node-3-keystore.jks"
                KAFKA_SSL_KEYSTORE_CREDENTIALS = "keystore.credential"
                KAFKA_SSL_KEY_CREDENTIALS = "key.credential"
                KAFKA_SSL_TRUSTSTORE_FILENAME = "kafka-truststore.jks"
                KAFKA_SSL_TRUSTSTORE_CREDENTIALS = "truststore.credential"
                KAFKA_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM = " "
                KAFKA_SSL_CLIENT_AUTH = "requested"
                KAFKA_SECURITY_INTER_BROKER_PROTOCOL = "SSL"
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
                    "broker3"
                ]
            }
        }
    }
    
    group "broker4" {
        task "server" {
            driver = "docker"

            config {
                image = "confluentinc/cp-kafka:5.3.1"
                command = "sh"
                args = [
                    "-c",
                    "cp /local/*.credential /etc/kafka/secrets/.;
                    keytool -noprompt -import -alias root-ca -trustcacerts -file /local/root-ca.pem -keystore /etc/kafka/secrets/kafka-truststore.jks -storepass changeme -keypass changeme;
                    keytool -noprompt -import -alias kafka-int-ca -trustcacerts -file /local/kafka-int-ca.pem -keystore /etc/kafka/secrets/kafka-truststore.jks -storepass changeme -keypass changeme;
                    openssl pkcs12 -inkey /local/node-4.pem -in /local/node-4.pem -name node-4 -export -out /local/node-4.p12 -password pass:changeme;
                    keytool -importkeystore -deststorepass changeme -destkeystore /etc/kafka/secrets/node-4-keystore.jks  -deststoretype pkcs12 -srckeystore /local/node-4.p12 -srcstoretype PKCS12 -srcstorepass changeme -keypass changeme;
                    /etc/confluent/docker/run"
                ]
            }
            
            template {
                data = <<EOH
{{ with secret "root-ca/cert/ca" }}
{{ .Data.certificate }}
{{ end }}
EOH
                // destination   = "${NOMAD_SECRETS_DIR}/node-1.pem"
                destination   = "/local/root-ca.pem"
                change_mode   = "restart"
            }
            
            template {
                data = <<EOH
{{ with secret "kafka-int-ca/cert/ca" }}
{{ .Data.certificate }}
{{ end }}
EOH
                // destination   = "${NOMAD_SECRETS_DIR}/node-1.pem"
                destination   = "/local/kafka-int-ca.pem"
                change_mode   = "restart"
            }
            
            template {
                data = <<EOH
{{ with secret "kafka-int-ca/issue/kafka-server" "common_name=node-4.servers.kafka.acme.com" "alt_names=localhost" "format=pem" }}
{{ .Data.certificate }}
{{ .Data.issuing_ca }}
{{ .Data.private_key }}
{{ end }}
EOH
                // destination   = "${NOMAD_SECRETS_DIR}/node-1.pem"
                destination   = "/local/node-4.pem"
                change_mode   = "restart"
            }

            template {
                data = <<EOH
changeme
EOH
                destination = "/local/keystore.credential"
                change_mode   = "restart"
            }
            template {
                data = <<EOH
changeme
EOH
                destination = "/local/key.credential"
                change_mode   = "restart"
            }
            template {
                data = <<EOH
changeme
EOH
                destination = "/local/truststore.credential"
                change_mode   = "restart"
            }

            env {
                KAFKA_BROKER_ID = "4"                
                KAFKA_ZOOKEEPER_CONNECT = "172.17.0.1:12181,172.17.0.1:22181,172.17.0.1:32181"
                KAFKA_ADVERTISED_LISTENERS = "PLAINTEXT://${NOMAD_ADDR_plaintext},SSL://${NOMAD_ADDR_ssl}"
                KAFKA_SSL_KEYSTORE_FILENAME = "node-4-keystore.jks"
                KAFKA_SSL_KEYSTORE_CREDENTIALS = "keystore.credential"
                KAFKA_SSL_KEY_CREDENTIALS = "key.credential"
                KAFKA_SSL_TRUSTSTORE_FILENAME = "kafka-truststore.jks"
                KAFKA_SSL_TRUSTSTORE_CREDENTIALS = "truststore.credential"
                KAFKA_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM = " "
                KAFKA_SSL_CLIENT_AUTH = "requested"
                KAFKA_SECURITY_INTER_BROKER_PROTOCOL = "SSL"
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
                    "broker4"
                ]
            }
        }
    }
}