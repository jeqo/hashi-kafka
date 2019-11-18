job "kafka" {
    datacenters = ["dc1"]
    
    vault {
        policies = ["kafka-server"]

       // change_mode   = "signal"
       // change_signal = "SIGUSR1"
    }

    group "broker1" {
        //TODO to be fixed
        // task "truststore" {
        //     driver = "docker"
            
        //     leader = "false"
            
        //     config {
        //         image = "openjdk:8u232-jre"
        //         command = "sh"
        //         args = [
        //             "-c",
        //             "keytool -import -alias root-ca -trustcacerts -file /local/root-ca.pem -keystore /local/kafka-truststore.jks;
        //             keytool -import -alias kafka-int-ca -trustcacerts -file /local/kafka-int-ca.pem -keystore /local/kafka-truststore.jks"
        //         ]
        //     }

        //     template {
        //         source = "root-ca.pem"
        //         // destination   = "${NOMAD_SECRETS_DIR}/node-1.pem"
        //         destination   = "/local/root-ca.pem"
        //         change_mode   = "restart"
        //     }

        //     template {
        //         source = "kafka-int-ca.pem"
        //         destination = "/local/kafka-int-ca.pem"
        //         change_mode = "restart"
        //     }
        // }

        task "keystore" {
            driver = "docker"
            
            leader = "false"
            
            config {
                image = "openjdk:8u232-jre"
                command = "sh"
                args = [
                    "-c",
                    "openssl pkcs12 -inkey /local/node-1.pem -in /local/node-1.pem -name node-1 -export -out /local/node-1.p12 -password pass:changeme;
                    keytool -importkeystore -deststorepass changeme -destkeystore /local/node-1-keystore.jks  -deststoretype pkcs12 -srckeystore /local/node-1.p12 -srcstoretype PKCS12 -srcstorepass changeme -keypass changeme"
                ]
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
        }
        
        task "server" {
            driver = "docker"

            leader = true

            config {
                image = "confluentinc/cp-kafka:5.3.1"
            }

            env {
                KAFKA_BROKER_ID = "1"
                KAFKA_ZOOKEEPER_CONNECT = "172.17.0.1:12181,172.17.0.1:22181,172.17.0.1:32181"
                KAFKA_ADVERTISED_LISTENERS = "PLAINTEXT://${NOMAD_ADDR_plaintext}"
                KAFKA_SSL_KEYSTORE_FILENAME = "/local/node-1-keystore.jks"
                KAFKA_SSL_KEYSTORE_PASSWORD = "changeme"
                KAFKA_SSL_KEY_PASSWORD = "changeme"
                KAFKA_SSL_TRUSTSTORE_FILENAME = "/local/truststore.jks"
                // KAFKA_SSL_TRUSTSTORE_PASSWORD = "changeme"
                KAFKA_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM = " "
                // KAFKA_SSL_CLIENT_AUTH = "requested"
                // KAFKA_SECURITY_INTER_BROKER_PROTOCOL = "SSL"                
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
            }

            env {
                KAFKA_BROKER_ID = "2"                
                KAFKA_ZOOKEEPER_CONNECT = "172.17.0.1:12181,172.17.0.1:22181,172.17.0.1:32181"
                KAFKA_ADVERTISED_LISTENERS = "PLAINTEXT://${NOMAD_ADDR_plaintext}"
            }
            resources {
                network {
                    mode = "bridge"
                    port "plaintext" {}
                }
            }
        }
    }
    
    group "broker3" {
        task "server" {
            driver = "docker"

            config {
                image = "confluentinc/cp-kafka:5.3.1"
            }

            env {
                KAFKA_BROKER_ID = "3"                
                KAFKA_ZOOKEEPER_CONNECT = "172.17.0.1:12181,172.17.0.1:22181,172.17.0.1:32181"
                KAFKA_ADVERTISED_LISTENERS = "PLAINTEXT://${NOMAD_ADDR_plaintext}"
            }
            resources {
                network {
                    mode = "bridge"
                    port "plaintext" {}
                }
            }
        }
    }

    group "broker4" {
        task "server" {
            driver = "docker"

            config {
                image = "confluentinc/cp-kafka:5.3.1"
            }

            env {
                KAFKA_BROKER_ID = "4"                
                KAFKA_ZOOKEEPER_CONNECT = "172.17.0.1:12181,172.17.0.1:22181,172.17.0.1:32181"
                KAFKA_ADVERTISED_LISTENERS = "PLAINTEXT://${NOMAD_ADDR_plaintext}"
            }
            resources {
                network {
                    mode = "bridge"
                    port "plaintext" {}
                }
            }
        }
    }
}