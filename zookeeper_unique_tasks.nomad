# Zookeeper

job "kafka-zookeeper" {
  datacenters = [ "dc1"]
  type = "service"
  update { max_parallel = 1 }

  group "zk" {
    count = 1
    restart {
      attempts = 2
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }
    ephemeral_disk {
      migrate = true
      size    = "500"
      sticky  = true
    }

    task "zk1" {
      driver = "docker"
      //ID
      template {
        destination = "local/data/myid"
        change_mode = "noop"
        data = <<EOF
1
EOF
      }
      //default config
      template {
        destination = "local/conf/zoo.cfg"
        change_mode = "restart"
        splay = "1m"
        data = <<EOF
tickTime=2000
initLimit=5
syncLimit=2
standaloneEnabled=false
reconfigEnabled=true
skipACL=true
zookeeper.datadir.autocreate=true
dataDir=/data
dynamicConfigFile=/conf/zoo.cfg.dynamic
EOF
      }
      //dynamic config
      template {
        destination = "local/conf/zoo.cfg.dynamic"
        change_mode = "restart"
        splay = "1m"
        data = <<EOF
server.1={{ env "NOMAD_IP_client" }}:{{ env "NOMAD_HOST_PORT_peer1" }}:{{ env "NOMAD_HOST_PORT_peer2" }};{{ env "NOMAD_HOST_PORT_client" }}
server.2={{ env "NOMAD_IP_zk2_client" }}:{{ env "NOMAD_PORT_zk2_peer1" }}:{{ env "NOMAD_PORT_zk2_peer2" }};{{ env "NOMAD_PORT_zk2_client" }}
server.3={{ env "NOMAD_IP_zk3_client" }}:{{ env "NOMAD_PORT_zk3_peer1" }}:{{ env "NOMAD_PORT_zk3_peer2" }};{{ env "NOMAD_PORT_zk3_client" }}
EOF
      }
      //logger appender
      template {
        destination = "local/conf/log4j.properties"
        change_mode = "noop"
        data = <<EOF
# Define some default values that can be overridden by system properties
zookeeper.root.logger=INFO, CONSOLE, ROLLINGFILE
zookeeper.console.threshold=INFO
zookeeper.log.dir=/zookeeper/log
zookeeper.log.file=zookeeper.log
zookeeper.log.threshold=INFO
zookeeper.tracelog.dir=/zookeeper/log
zookeeper.tracelog.file=zookeeper_trace.log

# ZooKeeper Logging Configuration
log4j.rootLogger=${zookeeper.root.logger}

# Log INFO level and above messages to the console
log4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender
log4j.appender.CONSOLE.Threshold=${zookeeper.console.threshold}
log4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout
log4j.appender.CONSOLE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n

# Add ROLLINGFILE to rootLogger to get log file output
log4j.appender.ROLLINGFILE=org.apache.log4j.RollingFileAppender
log4j.appender.ROLLINGFILE.Threshold=${zookeeper.log.threshold}
log4j.appender.ROLLINGFILE.File=${zookeeper.log.dir}/${zookeeper.log.file}

# Max log file size of 10MB
log4j.appender.ROLLINGFILE.MaxFileSize=10MB
# uncomment the next line to limit number of backup files
log4j.appender.ROLLINGFILE.MaxBackupIndex=5
log4j.appender.ROLLINGFILE.layout=org.apache.log4j.PatternLayout
log4j.appender.ROLLINGFILE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n
EOF
      }
      config {
        image = "zookeeper:3.5.5"
        labels { group = "zk-docker" }
        network_mode = "host"
        port_map {
            client = 2181
            peer1 = 2888
            peer2 = 3888
            httpBind = 8080
        }
        volumes = [
          "local/conf:/conf",
          "local/data:/data",
          "local/logs:/logs"
        ]
      }
      env { ZOO_LOG4J_PROP="INFO,CONSOLE" }
      resources {
        cpu = 100
        memory = 128
        network {
          mbits = 10
          port "client" {}
          port "peer1" {}
          port "peer2" {}
          port "httpBind" {}
        }
      }
      service {
        port = "client"
        tags = [
          "kafka-zookeeper-client"
        ]
      }
      service {
        port = "peer1"
        tags = [
          "kafka-zookeeper-peer1"
        ]
      }
      service {
        port = "peer2"
        tags = [
          "kafka-zookeeper-peer2"
        ]
      }
    }


    task "zk2" {
      driver = "docker"
      template {
        destination = "local/data/myid"
        change_mode = "noop"
        data = <<EOF
2
EOF
      }
      template {
        destination = "local/conf/zoo.cfg"
        change_mode = "restart"
        splay = "1m"
        data = <<EOF
tickTime=2000
initLimit=5
syncLimit=2
standaloneEnabled=false
reconfigEnabled=true
skipACL=true
zookeeper.datadir.autocreate=true
dataDir=/data
dynamicConfigFile=/conf/zoo.cfg.dynamic
EOF
      }
      template {
        destination = "local/conf/zoo.cfg.dynamic"
        change_mode = "restart"
        splay = "1m"
        data = <<EOF
server.1={{ env "NOMAD_IP_zk1_client" }}:{{ env "NOMAD_PORT_zk1_peer1" }}:{{ env "NOMAD_PORT_zk1_peer2" }};{{ env "NOMAD_PORT_zk1_client" }}
server.2={{ env "NOMAD_IP_client" }}:{{ env "NOMAD_HOST_PORT_peer1" }}:{{ env "NOMAD_HOST_PORT_peer2" }};{{ env "NOMAD_HOST_PORT_client" }}
server.3={{ env "NOMAD_IP_zk3_client" }}:{{ env "NOMAD_PORT_zk3_peer1" }}:{{ env "NOMAD_PORT_zk3_peer2" }};{{ env "NOMAD_PORT_zk3_client" }}
EOF
      }
      template {
        destination = "local/conf/log4j.properties"
        change_mode = "noop"
        data = <<EOF
# Define some default values that can be overridden by system properties
zookeeper.root.logger=INFO, CONSOLE, ROLLINGFILE
zookeeper.console.threshold=INFO
zookeeper.log.dir=/zookeeper/log
zookeeper.log.file=zookeeper.log
zookeeper.log.threshold=INFO
zookeeper.tracelog.dir=/zookeeper/log
zookeeper.tracelog.file=zookeeper_trace.log

# ZooKeeper Logging Configuration
log4j.rootLogger=${zookeeper.root.logger}

# Log INFO level and above messages to the console
log4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender
log4j.appender.CONSOLE.Threshold=${zookeeper.console.threshold}
log4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout
log4j.appender.CONSOLE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n

# Add ROLLINGFILE to rootLogger to get log file output
log4j.appender.ROLLINGFILE=org.apache.log4j.RollingFileAppender
log4j.appender.ROLLINGFILE.Threshold=${zookeeper.log.threshold}
log4j.appender.ROLLINGFILE.File=${zookeeper.log.dir}/${zookeeper.log.file}

# Max log file size of 10MB
log4j.appender.ROLLINGFILE.MaxFileSize=10MB
# uncomment the next line to limit number of backup files
log4j.appender.ROLLINGFILE.MaxBackupIndex=5
log4j.appender.ROLLINGFILE.layout=org.apache.log4j.PatternLayout
log4j.appender.ROLLINGFILE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n
EOF
      }
      config {
        image = "zookeeper:3.5.5"
        labels {
          group = "zk-docker"
        }
        network_mode = "host"
        port_map {
          client = 2181
          peer1 = 2888
          peer2 = 3888
          httpBind = 8080
        }
        volumes = [
          "local/conf:/conf",
          "local/data:/data",
          "local/logs:/logs"
        ]
      }
      env {
        ZOO_LOG4J_PROP="INFO,CONSOLE"
      }
      resources {
        cpu = 100
        memory = 128
        network {
          mbits = 10
          port "client" {}
          port "peer1" {}
          port "peer2" {}
          port "httpBind" {}
        }
      }
      service {
        port = "client"
        tags = [
          "kafka-zookeeper-client"
        ]
      }
      service {
        port = "peer1"
        tags = [
          "kafka-zookeeper-peer1"
        ]
      }
      service {
        port = "peer2"
        tags = [
          "kafka-zookeeper-peer2"
        ]
      }
    }

    task "zk3" {
      driver = "docker"
      template {
        destination = "local/data/myid"
        change_mode = "noop"
        data = <<EOF
3
EOF
      }
      template {
        destination = "local/conf/zoo.cfg"
        change_mode = "restart"
        splay = "1m"
        data = <<EOF
tickTime=2000
initLimit=5
syncLimit=2
standaloneEnabled=false
reconfigEnabled=true
skipACL=true
zookeeper.datadir.autocreate=true
dataDir=/data
dynamicConfigFile=/conf/zoo.cfg.dynamic
EOF
      }
      template {
        destination = "local/conf/zoo.cfg.dynamic"
        change_mode = "restart"
        splay = "1m"
        data = <<EOF
server.1={{ env "NOMAD_IP_zk1_client" }}:{{ env "NOMAD_PORT_zk1_peer1" }}:{{ env "NOMAD_PORT_zk1_peer2" }};{{ env "NOMAD_PORT_zk1_client" }}
server.2={{ env "NOMAD_IP_zk2_client" }}:{{ env "NOMAD_PORT_zk2_peer1" }}:{{ env "NOMAD_PORT_zk2_peer2" }};{{ env "NOMAD_PORT_zk2_client" }}
server.3={{ env "NOMAD_IP_client" }}:{{ env "NOMAD_HOST_PORT_peer1" }}:{{ env "NOMAD_HOST_PORT_peer2" }};{{ env "NOMAD_HOST_PORT_client" }}
EOF
      }
      template {
        destination = "local/conf/log4j.properties"
        change_mode = "noop"
        data = <<EOF
# Define some default values that can be overridden by system properties
zookeeper.root.logger=INFO, CONSOLE, ROLLINGFILE
zookeeper.console.threshold=INFO
zookeeper.log.dir=/zookeeper/log
zookeeper.log.file=zookeeper.log
zookeeper.log.threshold=INFO
zookeeper.tracelog.dir=/zookeeper/log
zookeeper.tracelog.file=zookeeper_trace.log

# ZooKeeper Logging Configuration
log4j.rootLogger=${zookeeper.root.logger}

# Log INFO level and above messages to the console
log4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender
log4j.appender.CONSOLE.Threshold=${zookeeper.console.threshold}
log4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout
log4j.appender.CONSOLE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n

# Add ROLLINGFILE to rootLogger to get log file output
log4j.appender.ROLLINGFILE=org.apache.log4j.RollingFileAppender
log4j.appender.ROLLINGFILE.Threshold=${zookeeper.log.threshold}
log4j.appender.ROLLINGFILE.File=${zookeeper.log.dir}/${zookeeper.log.file}

# Max log file size of 10MB
log4j.appender.ROLLINGFILE.MaxFileSize=10MB
# uncomment the next line to limit number of backup files
log4j.appender.ROLLINGFILE.MaxBackupIndex=5
log4j.appender.ROLLINGFILE.layout=org.apache.log4j.PatternLayout
log4j.appender.ROLLINGFILE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n
EOF
      }
      config {
        image = "zookeeper:3.5.5"
        labels {
            group = "zk-docker"
        }
        network_mode = "host"
        port_map {
            client = 2181
            peer1 = 2888
            peer2 = 3888
            httpBind = 8080
        }
        volumes = [
          "local/conf:/conf",
          "local/data:/data",
          "local/logs:/logs"
        ]
      }
      env {
        ZOO_LOG4J_PROP="INFO,CONSOLE"
      }
      resources {
        cpu = 100
        memory = 128
        network {
          mbits = 10
          port "client" {}
          port "peer1" {}
          port "peer2" {}
          port "httpBind" {}
        }
      }
      service {
        port = "client"
        tags = [
          "kafka-zookeeper-client"
        ]
      }
      service {
        port = "peer1"
        tags = [
          "kafka-zookeeper-peer1"
        ]
      }
      service {
        port = "peer2"
        tags = [
          "kafka-zookeeper-peer2"
        ]
      }
    }
  }
}
