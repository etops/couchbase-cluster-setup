Couchbase Cluster with docker and docker-compose
================================================

Hint: on Linux use sudo before docker.

Run
---
1. ```git clone https://github.com/etops/couchbase-cluster-setup.git```
2. create ~/couchbase/node1 folders
3. ```docker-compose up -d ``` (remove the -d to see log output)
4. go to http://<ip>:8091 and verify running couchbase

<ip> can be found with 
```docker inspect couchbasesetup_couchbase-init_1 | grep IPAddress | cut -d '"' -f 4```


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



