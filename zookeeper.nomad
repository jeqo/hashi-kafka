# Tested locally:
## sudo consul agent -dev -client 172.17.0.1 -dns-port 53
## sudo nomad agent -dev -consul-address=172.17.0.1:8500 -bind=172.17.0.1 -network-interface=docker0
job "kafka" {
    datacenters = ["dc1"]
    
    group "zookeeper1" {

        task "node" {
            driver = "docker"

            config {
                image = "confluentinc/cp-zookeeper:5.3.1"

                dns_servers = [
                    "172.17.0.1"
                ]
            }
      
            env {
                ZOOKEEPER_SERVER_ID = 1
                ZOOKEEPER_CLIENT_PORT = "${NOMAD_PORT_client}"
                ZOOKEEPER_TICK_TIME = 2000
                ZOOKEEPER_INIT_LIMIT = 5
                ZOOKEEPER_SYNC_LIMIT = 2
                # for some reason this is not working check #1
                ZOOKEEPER_SERVERS = "kafka-zookeeper1-node.service.consul:${NOMAD_PORT_quorum}:${NOMAD_PORT_election};kafka-zookeeper2-node.service.consul:22888:23888"
            }

            resources {
                network {
                    mode = "bridge"
                    port "client" {
                    }
                    # Static ports to map zookeeper.servers
                    port "quorum" {
                        static = 12888
                    }
                    port "election" {
                        static = 13888
                    }
                }
            }

            service {
                port = "client"
                tags = ["zookeeper", "zk", "client"]
            }
        }
    }
    
    group "zookeeper2" {
        
        task "node" {
            driver = "docker"

            config {
                image = "confluentinc/cp-zookeeper:5.3.1"
                dns_servers = [
                    "172.17.0.1"
                ]
            }
      
            env {
                ZOOKEEPER_SERVER_ID = 2
                ZOOKEEPER_CLIENT_PORT = "${NOMAD_PORT_client}"
                ZOOKEEPER_TICK_TIME = 2000
                ZOOKEEPER_INIT_LIMIT = 5
                ZOOKEEPER_SYNC_LIMIT = 2
                ZOOKEEPER_SERVERS = "kafka-zookeeper1-node.service.consul:12888:13888;kafka-zookeeper2-node.service.consul:${NOMAD_PORT_quorum}:${NOMAD_PORT_election}"
            }
            
            resources { 
                network {
                    mode = "bridge"
                    port "client" {
                    }
                    # Static ports to map zookeeper.servers
                    port "quorum" {
                        static = 22888
                    }
                    port "election" {
                        static = 23888
                    }
                }
            }

            service {
                port = "client"
                tags = ["zookeeper", "zk", "client"]
            }
        }
    }
}