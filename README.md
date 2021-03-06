Couchbase Cluster with docker and docker-compose
================================================

Hint: on Linux use sudo before docker.

Configure
-----------
Cluster accepts the following parameters:

- `ADMIN_LOGIN`
- `ADMIN_PASSWORD` (must be minimum 8 chars with special chars)
- `CLUSTER_RAM_QUOTA` (recommended minimum 2048)
- `INDEX_RAM_QUOTA` (recommended minimum 256)
- `MODEL_BUCKET_RAMSIZE` (recommended minimum 256)
- `FILE_BUCKET_RAMSIZE` (recommended minimum 256)

For what the couchbase memory parameters mean, see 
[Couchbase Cluster Settings documentation](http://developer.couchbase.com/documentation/server/current/settings/cluster-settings.html)

Run
---
1. ```git clone https://github.com/etops/couchbase-cluster-setup.git```
2. create ~/couchbase/node1 folders
3. ```docker-compose up -d ``` (remove the -d to see log output)
4. go to http://&lt;ip&gt;:8091 and verify running couchbase

&lt;ip&gt; can be found with 
```docker inspect couchbaseclustersetup_couchbase-init_1 | grep IPAddress | cut -d '"' -f 4```


Scale
-----
```docker-compose scale couchbase=3```
Syntaxt docker-compose scale SERVICE=#Nr

Total number of running instance is #Nr + 1


Data location
-------------

use volume in docker-compose.yml
```
volumes:
        - ~/couchbase/node1:/opt/couchbase/var
```

Problem: docker-compose scale and volumes don't work together
Workaround: 
```
couchbase1:
    build: .
    links:
        - couchbase-init:couchbase
    environment: 
        - CLUSTER_RAM_QUOTA=1024
    restart: always
    volumes:
        - ~/couchbase/node1:/opt/couchbase/var
    
couchbase2:
    build: .
    links:
        - couchbase-init:couchbase
    environment: 
        - CLUSTER_RAM_QUOTA=1024
    restart: always
    volumes:
        - ~/couchbase/node2:/opt/couchbase/var
    
couchbase3:
    build: .
    links:
        - couchbase-init:couchbase
    environment: 
        - CLUSTER_RAM_QUOTA=1024
    restart: always
    volumes:
        - ~/couchbase/node3:/opt/couchbase/var
```
    

Change Password
---------------

Password can be set in Dockerfile as environement variable.



Stop and rebuild
--------------------

stop all running containers:
```docker-compose stop```

remove images of the stoped containers:
```docker-compose rm```

force build:
```docker-compose build```

run again:
```docker-compose up```


Cluster Design Considerations
---------------------------------

[Couchbase guidance](http://blog.couchbase.com/10-things-developers-should-know-about-couchbase)
suggests keeping number of total buckets to a minimum, ideally 5 or less, never more than 10.

They recommend starting in one bucket and growing out as necessary.


example docker swarm

```
version: "3.3"

services:
  couchbase-master:
    environment:
      - TYPE=MASTER
      - CLUSTER_RAM_QUOTA=5120
      - ADMIN_LOGIN=admin
      - ADMIN_PASSWORD=<pw>
    image: etops/couchbase:4.6.2-rawdata
    ports:
      - target: 4369
        published: 4369
        protocol: tcp
        mode: host
      - target: 8091
        published: 8091
        protocol: tcp
        mode: host
      - target: 8092
        published: 8092
        protocol: tcp
        mode: host
      - target: 8093
        published: 8093
        protocol: tcp
        mode: host
      - target: 11210
        published: 11210
        protocol: tcp
        mode: host
    volumes:
      - type: bind
        source: /home/ubuntu/stack/rawdata/couchbase/data
        target: /opt/couchbase/var
    networks:
      - cbrd
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints: [node.labels.app_role == rawdata]
      restart_policy:
        condition: on-failure

  couchbase-worker:
    environment:
      - TYPE=WORKER
      - COUCHBASE_MASTER=159.100.242.154
      - ADMIN_LOGIN=admin
      - ADMIN_PASSWORD=<pw>
    image: etops/couchbase:4.6.2-rawdata
    ports:
      - target: 4369
        published: 4369
        protocol: tcp
        mode: host
      - target: 8091
        published: 8091
        protocol: tcp
        mode: host
      - target: 8092
        published: 8092
        protocol: tcp
        mode: host
      - target: 8093
        published: 8093
        protocol: tcp
        mode: host
      - target: 11210
        published: 11210
        protocol: tcp
        mode: host
    volumes:
      - type: bind
        source: /home/ubuntu/stack/rawdata/couchbase/data
        target: /opt/couchbase/var
    networks:
      - cbrd
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints: [node.labels.app_role == rawdata]
      restart_policy:
        condition: on-failure

networks:
  cbrd:
```


Minimum Requirements
---------------------------

Couchbase's published guidance [can be found here](http://developer.couchbase.com/documentation/server/current/install/pre-install.html).

Deployment Best Practices
---------------------------

[See notes here](https://hub.docker.com/r/couchbase/server/).