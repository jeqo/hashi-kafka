# Kafka deployment on top of Hashicorp stack

## Prepare local environment

```bash
make vault
make consul
make nomad
```

> `172.17.0.1` is `docker0` network interface IP.

## Zookeeper

> Currently there are some issues on Zookeeper to form a quorum (#1).
>
> Provisionally, a `docker-compose.yml` is provided to test Kafka brokers.

3 node cluster.

## Kafka

4 broker cluster.

### Single group, 4 instances.

[nomad config](./kafka-group.nomad)

Steps to reproduce:

* Check `vault`, `consul`, and `nomad` are running.
* Prepare `vault`:

```bash
source .env
make pki
make pki-roles
```

* Run job: `nomad job run kafka-group.nomad`
* Once cluster is running, create a topic:

```bash
$KAFKA_HOME/bin/kafka-topics.sh --zookeeper 172.17.0.1:12181 --create --topic test --replication-factor 3 --partitions 4
```

* Generate a client truststore and keystore:

```bash
make truststore
```

```bash
vault token create -role kafka-client
export VAULT_TOKEN=(server vault token)
make client-keystore
```

* Run a producer:

```bash
$KAFKA_HOME/bin/kafka-console-producer.sh --broker-list <one of consul instances> --topic test --producer.config producer.properties
```

```bash
$KAFKA_HOME/bin/kafka-console-consumer.sh --bootstrap-server <one of consul instances> --topic test --consumer.config consumer.properties --from-beginning
```
### Validate (verify)
for con in `docker ps -q --filter "ancestor=zookeeper:3.5.5"` ; \
    do echo "$con" && docker exec $con /bin/bash -c "/apache-zookeeper-3.5.5-bin/bin/zkServer.sh status"; \
    done

```
ea9b728496c1
ZooKeeper JMX enabled by default
Using config: /conf/zoo.cfg
Client port not found in static config file. Looking in dynamic config file.
Client port found: 30285. Client address: 0.0.0.0.
Mode: follower
60dde5c715a0
ZooKeeper JMX enabled by default
Using config: /conf/zoo.cfg
Client port not found in static config file. Looking in dynamic config file.
Client port found: 26926. Client address: 0.0.0.0.
Mode: follower
bbdb4006bc2e
ZooKeeper JMX enabled by default
Using config: /conf/zoo.cfg
Client port not found in static config file. Looking in dynamic config file.
Client port found: 21097. Client address: 0.0.0.0.
Mode: leader
```

## Next steps

* [ ] Volumes for data
* [ ] Vault secrets for credentials
...