# Moving to Prod
---

### install docker in ubuntu
##### solution 1 ( not work for me)
https://get.docker.com/
https://docs.docker.com/engine/install/ubuntu/

```properties
curl -fsSL https://get.docker.com -o get-docker.sh
ls
sh get-docker.sh
```
###### install docker-compose
https://docs.docker.com/compose/install/
```properties
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

##### solution 2 (work for me)
https://github.com/prisma/prisma1/issues/5120#issuecomment-695755256
```properties
curl https://get.docker.com | sh  
sudo usermod -aG docker $USER  
sudo reboot  
sudo systemctl start docker  
sudo systemctl enable docker
```
### git
```properties
touch .gitignore
git init
git add .
git commit -m "first commit"
git push
```
#### docker-compose.prod.yml 
edit env
```yaml
version: '3'
services:
  nginx:
    ports:
      - '80:80'

  node-app:
    build:
      context: .
      args:
        NODE_ENV: production
    environment:
      - NODE_ENV=production
      - MONGO_USER=${MONGO_USER}
      - MONGO_PASSWORD=${MONGO_PASSWORD}
      - SESSION_SECRET=${SESSION_SECRET}  # password for your session
    command: node index.js
  mongo:
    environment:
      - MONGO_INITDB_ROOT_USERNAME=${MONGO_INITDB_ROOT_USERNAME}
      - MONGO_INITDB_ROOT_PASSWORD=${MONGO_INITDB_ROOT_PASSWORD}
```
### in ubuntu
```properties
# print variable you have
pringenv
vi .env
```

#### Set Environment Variables after reboot
##### solution 1
###### .env
```properties
NODE_ENV=development
MONGO_USER=Moo
MONGO_PASSWORD=password
SESSION_SECRET=secret
MONGO_INITDB_ROOT_USERNAME=Moo
MONGO_INITDB_ROOT_PASSWORD=password
```

###### .profile
```properties
vi .profile
```

```properties
# add this line
set -o allexport; source /root/.env; set +o allexport
```

##### solution 2
###### .profile
```properties
# add all this line at the bottom
export NODE_ENV=development
export MONGO_USER=Moo
export MONGO_PASSWORD=password
export SESSION_SECRET=secret
export MONGO_INITDB_ROOT_USERNAME=Moo
export MONGO_INITDB_ROOT_PASSWORD=password
```

### Deploying app to production server

```properties
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

- I use AWS so let EC2 instance public IP accessible from outside, add security group EC2 IP.

https://youtu.be/ukdTGVVcqE0


<img src="https://github.com/Wolowit/DockerWithNode.js-Express/blob/main/my-note/img/4.png" />

- go to Public IPv4 address and play!

#### Pushing changes the hard way
- git push on local then pull on server

```properties
git pull
# only change node-app, 
# [--no-deps] no depends_on
# [--help]
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build --no-deps node-app
```

<img src="https://github.com/Wolowit/DockerWithNode.js-Express/blob/main/my-note/img/5.png" />

#### Push docker image to docker hub
<img src="https://github.com/Wolowit/DockerWithNode.js-Express/blob/main/my-note/img/6.png" />
```properties
# in vscode
docker image ls
docker login
docker tag [image name] [name docker hub]
docker push [name docker hub]

# in server 
git pull
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

if you edit code 
```properties
# in vscode
# add [node-app] or [name] to build only that you change
docker-compose -f docker-compose.yml -f docker-compose.prod.yml build
# OR

docker-compose -f docker-compose.yml -f docker-compose.prod.yml push node-app
```

```properties
# in server
docker-compose -f docker-compose.yml -f docker-compose.prod.yml pull
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Watchtower
https://github.com/containrrr/watchtower

```properties
docker run -d --name watchtower -e WATCHTOWER_TRACE=true -e WATCHTOWER_DEBUG=true -e WATCHTOWER_POLL_INTERVAL=50 -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower

docker ps 
docker logs  
```

### Docker Swarm
```properties
# check docker swarm is open?
docker info
# check you ip
ip a
docker swarm init --advertise-addr 172.31.46.186
```

#### this is output

```
Swarm initialized: current node (zjn83li0i567epfbp6ivgk0gx) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-4h0gx1svonw4y4z741ht4t6e0qz9e9perq1bqeqqa2hy4ycts6-bgko83gcu76ftggy89f970x74 172.31.46.186:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```

```properties
docker service --help

```

https://docs.docker.com/compose/compose-file/compose-file-v3/#deploy

##### replicas
https://docs.docker.com/compose/compose-file/compose-file-v3/#max_replicas_per_node

If the service is `replicated` (which is the default), specify the number of containers that should be running at any given time.

```
version: "3.9"
services:
  worker:
    image: dockersamples/examplevotingapp_worker
    networks:
      - frontend
      - backend
    deploy:
      mode: replicated
      replicas: 6
```

##### update_config
https://docs.docker.com/compose/compose-file/compose-file-v3/#update_config
Configures how the service should be updated. Useful for configuring rolling updates.

-   `parallelism`: The number of containers to update at a time.
-   `delay`: The time to wait between updating a group of containers.
-   `failure_action`: What to do if an update fails. One of `continue`, `rollback`, or `pause` (default: `pause`).
-   `monitor`: Duration after each task update to monitor for failure `(ns|us|ms|s|m|h)` (default 5s) **Note**: Setting to 0 will use the default 5s.
-   `max_failure_ratio`: Failure rate to tolerate during an update.
-   `order`: Order of operations during updates. One of `stop-first` (old task is stopped before starting new one), or `start-first` (new task is started first, and the running tasks briefly overlap) (default `stop-first`) **Note**: Only supported for v3.4 and higher.

#### docker-compose.prod.yml (add replicas)
```yaml
version: '3'
services:
  nginx:
    ports:
      - '80:80'

  node-app:
    deploy:
      replicas: 8
    restart_policy:
      condition: any
    update_config:
      parallelism: 2 # up 2 container per time
      delay: 15s
    build:
      context: .
      args:
        NODE_ENV: production
    environment:
      - NODE_ENV=production
      - MONGO_USER=${MONGO_USER}
      - MONGO_PASSWORD=${MONGO_PASSWORD}
      - SESSION_SECRET=${SESSION_SECRET} # password for your session
    command: node index.js
  mongo:
    environment:
      - MONGO_INITDB_ROOT_USERNAME=${MONGO_INITDB_ROOT_USERNAME}
      - MONGO_INITDB_ROOT_PASSWORD=${MONGO_INITDB_ROOT_PASSWORD}
```

#### deploy docker Swarm
```properties
docker stack --help
docker stack deploy -c docker-compose.yml -c docker-compose.prod.yml myapp

docker node ls
docker stack ls
docker stack --help

# if you change code in index.js need to push to docker hub first then
#Pushing changes to Swarm stack
docker stack deploy -c docker-compose.yml -c docker-compose.prod.yml myapp
# it will update 2 container at a time ( set parallelism in docker-compose.prod.yml)
```