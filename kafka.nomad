job "kafka" {
    datacenters = ["dc1"]

    group "broker1" {
        task "server" {
            driver = "docker"

            config {
                image = "confluentinc/cp-kafka:5.3.1"
            }

            env {
                KAFKA_BROKER_ID = "1"
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