[logo]: https://ci.nerv.com.au/userContent/antilax-3.png "AntilaX-3"
[![alt text][logo]](https://github.com/AntilaX-3/)

# AntilaX-3/dotproxy
[![](https://images.microbadger.com/badges/version/antilax3/dotproxy.svg)](https://microbadger.com/images/antilax3/dotproxy "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/antilax3/dotproxy.svg)](https://microbadger.com/images/antilax3/dotproxy "Get your own image badge on microbadger.com") [![Docker Pulls](https://img.shields.io/docker/pulls/antilax3/dotproxy.svg)](https://hub.docker.com/r/antilax3/dotproxy/) [![Docker Stars](https://img.shields.io/docker/stars/antilax3/dotproxy.svg)](https://hub.docker.com/r/antilax3/dotproxy/)

[dotproxy](https://github.com/LINKIWI/dotproxy) is a high-performance and fault-tolerant DNS-over-TLS proxy. It listens on both TCP and UDP transports and proxies DNS traffic transparently to configurable TLS-enabled upstream server(s). 
## Usage
```
docker create --name=dotproxy \
-v <path to config>:/config \
-p 7012:7012 \
-p 7012:7012/udp \
antilax3/dotproxy
```
## Parameters
The parameters are split into two halves, separated by a colon, the left hand side representing the host and the right the container side. For example with a volume -v external:internal - what this shows is the volume mapping from internal to external of the container. So -v /mnt/app/config:/config would map /config from inside the container to be accessible from /mnt/app/config on the host's filesystem.

- `-v /config` - local path for dotproxy config file
- `-p 7012` - TCP port for dotproxy
- `-p 7012/udp` - UDP port for dotproxy
- `-e LOG_LEVEL` - for setting log verbosity level, eg debug
- `-e PUID` - for UserID, see below for explanation
- `-e PGID` - for GroupID, see below for explanation
- `-e TZ` - for setting timezone information, eg Australia/Melbourne

It is based on alpine linux with s6 overlay, for shell access whilst the container is running do `docker exec -it dotproxy /bin/bash`.

## User / Group Identifiers
Sometimes when using data volumes (-v flags) permissions issues can arise between the host OS and the container. We avoid this issue by allowing you to specify the user `PUID` and group `PGID`. Ensure the data volume directory on the host is owned by the same user you specify and it will "just work".

In this instance `PUID=1001` and `PGID=1001`. To find yours use `id user` as below:
`$ id <dockeruser>`
    `uid=1001(dockeruser) gid=1001(dockergroup) groups=1001(dockergroup)`
    
## Volumes

The container uses a single volume mounted at '/config'. This volume stores the configuration file 'config.yaml'.

    config
    |-- config.yaml

## Configuration

The config.yaml is copied to the /config volume when first run.

The following table documents each field and its expected value:

|Key|Required|Description|
|-|-|-|
|`metrics.statsd.addr`|No|Address of the statsd server for metrics reporting|
|`metrics.statsd.sample_rate`|No|statsd sample rate, if enabled|
|`listener.tcp.addr`|Yes|Address to bind to for the TCP listener|
|`listener.tcp.read_timeout`|No|Time duration string for a client TCP read timeout|
|`listener.tcp.write_timeout`|No|Time duration string for a client TCP write timeout|
|`listener.udp.addr`|Yes|Address to bind to for the UDP listener|
|`listener.udp.read_timeout`|No|Time duration string for a client UDP read timeout; should generally be omitted or set to 0|
|`listener.udp.write_timeout`|No|Time duration string for a client UDP write timeout|
|`upstream.load_balacing_policy`|No|One of the `LoadBalancingPolicy` constants to control how requests are sharded among all specified upstream servers|
|`upstream.max_connection_retries`|No|Maximum number of times to retry an upstream I/O operation, per request|
|`upstream.servers[].addr`|Yes|The address of the upstream TLS-enabled DNS server|
|`upstream.servers[].server_name`|Yes|The TLS server hostname (used for server identity verification)|
|`upstream.servers[].connection_pool_size`|No|Size of the connection pool to maintain for this server; environments with high traffic and/or request concurrency will generally benefit from a larger connection pool|
|`upstream.servers[].connect_timeout`|No|Time duration string for an upstream TCP connection establishment timeout|
|`upstream.servers[].handshake_timeout`|No|Time duration string for an upstream TLS handshake timeout|
|`upstream.servers[].read_timeout`|No|Time duration string for an upstream TCP read timeout|
|`upstream.servers[].write_timeout`|No|Time duration string for an upstream TCP write timeout|
|`upstream.servers[].stale_timeout`|No|Time duration string describing the interval of time between consecutive open connection uses after which it should be considered stale and reestablished|

### Load balancing policies

When there exists more than one upstream DNS server in configuration, the `upstream.load_balancing_policy` field controls how dotproxy shards requests among the servers. The policies below are mostly stateless and protocol-agnostic.

|Policy|Description|
|-|-|
|`RoundRobin`|Select servers in [round-robin](https://en.wikipedia.org/wiki/Round-robin_scheduling), circular order. Simple, fair, but not fault tolerant.|
|`Random`|Select a server at random. Simple, fair, async-safe, but not fault tolerant.|
|`HistoricalConnections`|Select the server that has, up until the time of request, provided the fewest number of connections. Ideal if it is important that all servers share an equal amount of load, without regard to fault tolerance.|
|`Availability`|Randomly select an available server. A server is considered *available* if it is successful in providing a connection. Servers that fail to provide a connection are pulled out of the availability pool for exponentially increasing durations of time, preventing them from providing connections until their unavailability period has expired. Ideal for greatest fault tolerance while maintaining roughly equal load distribution and minimizing downstream latency impact, at the cost of running potentially expensive logic every time a connection is requested.|
|`Failover`|Prioritize a single primary server and failover to secondary server(s) only when the primary fails. Ideal if one server should serve all traffic, but there is a need for fault tolerance.|

## Version
- **17/03/19:** Initial Release