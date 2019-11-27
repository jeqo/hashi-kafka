job "countdash" {
  datacenters = ["dc1"]

  group "api" {
    network {
      mode = "bridge"
    }

    service {
      name = "count-api"
      port = "9001"

      connect {
        sidecar_service {}
      }
    }

    task "web" {
      driver = "docker"

      config {
        image = "hashicorpnomad/counter-api:v1"
      }
    }
  }

  group "dashboard" {
    network {
      mode = "bridge"

      port "http" {
        // static = 9002
        to     = -1
      }
    }

    service {
        name = "count-ui"
        port = 10000
    }

    service {
      name = "count-dashboard"
      port = "http"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "count-api"
              local_bind_port  = 8080
            }
          }
        }
      }
    }

    task "dashboard" {
      driver = "docker"

      env {
        COUNTING_SERVICE_URL = "http://${NOMAD_UPSTREAM_ADDR_count_api}"
        PORT = "${NOMAD_PORT_http}"
      }

      config {
        image = "hashicorpnomad/counter-dashboard:v1"
      }
    }
  }
}
