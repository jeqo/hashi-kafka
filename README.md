# Kafka deployment on top of Hashicorp stack

## Prepare local environment

```bash
sudo consul agent -dev -client 172.17.0.1 -dns-port 53
# other terminal
sudo nomad agent -dev -consul-address=172.17.0.1:8500 -bind=172.17.0.1 -network-interface=docker0
```
> `172.17.0.1` is `docker0` network interface IP.

## Zookeeper

> Currently there are some issues on Zookeeper to form a quorum (#1).
>
> Provisionally, a `docker-compose.yml` is provided to test Kafka brokers.

3 node cluster.

## Kafka

4 broker cluster.