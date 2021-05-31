# Docker with Node.Js & Express

---

### idea

---

### Docker and Node.Js

```properties
npm init
npm i express
touch index.js
```

---

##### index.js

set up

```javascript
const express = require('express')
const app = express()

app.get('/', (req, res) => {
  res.send('<h1>Hi There joker</h1>')
})

const port = process.env.port || 3000

app.listen(port, console.log('listening on port ${port}'))
// app.listen(port, () => console.log("listening on port ${port}"));
```

- [process.env](https://nodejs.org/dist/latest-v8.x/docs/api/process.html#process_process_env)

```properties
node index.js
```

now you go localhost to see

---

##### Dockerfile

```properties
touch Dockerfile
```

```docker
FROM node
#1 set working dir to ./app
WORKDIR /app
#2 copy package.json to node container
COPY package.json .
#3 install npm from package.json
RUN npm install
# copy everything to node container
COPY . ./
# on port 3000
ENV PORT 3000
EXPOSE $PORT
# run command `node index.js`
CMD ["node", "index.js"]

```

- Note: If step-3 package.json change, Docker will re-run install by check from cache

```properties
# [-t] build with name
docker build -t node-app-image .
# [docker image ls]
# [docker logs node-app]
# dot mean build in current directory

# [-d] run in detach mode
# [-p] port to connect local:cotainer
# [--no-cache] not run from cache
docker run -p 3000:3000 -d --name node-app node-app-image
# [-a] show container all
docker ps -a
# force to rm
docker rm node-app -f
# go in container
docker exec -it node-app bash
```

##### .dockerignore

make sure not to copy these file to container

```ignoer
node_modules
Dockerfile
.dockerignore
.git
.gitignore
docker-compose*
```

- note: \* file that start with this name will ignore

##### sync source code

- can't delete local node_moldule directory because it sync two way
- ex. delete file from container will delete in local

```properties
# to sync add [-v pathfolderonlocation:pathtofolderoncontainer]
# [:ro] mean read only ->
# for container can't change file in local while sync
docker run -v $(pwd):/app:ro -p 3000:3000 -d --name node-app node-app-image
# [$(pwd):/app:ro] on mac
# [%cd%:/app:ro] on cmd shell windows
# [${pwd}/app:ro] on power shell
```

- Why code not sync yet => you need nodemon

```properties
# [--save-dev] install in dev side
npm i nodemon --save-dev
```

###### package.json

```json
// if you in windows nodemon no restart add [-L]
// "dev": "nodemon -L index.js"
"scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js"
  },
```

###### Dockerfile change CMD

```docker
# change line to run dev mode
CMD["npm", "run", "dev"]
```

- fix sync can delete local not gonna effect in container

```properties
# add [-v /app/node_modules] , it anonymous volume
docker run -v $(pwd):/app:ro -v /app/node_modules -p 3000:3000 -d --name node-app node-app-image

# add [--env PORT=4000] -> pass env to change port to 3000:4000
docker run -v $(pwd):/app:ro -v /app/node_modules --env PORT=4000 -p 3000:4000 -d --name node-app node-app-image
# in docker exec [printenv] to see env that we pass
printenv
```

###### .env file

- if you have many variable, you can put in file

```docker
PORT=4000
```

```properties
# [--env-file ./.env]
docker run -v $(pwd):/app:ro -v /app/node_modules --env-file ./.env -p 3000:4000 -d --name node-app node-app-image

# delete image we not use (anonymous?)
docker image prune
docker volume prune
# or when you delete add [-v]
docker rm [name] -fv
```

### Docker compose

#### docker-compose.yml

```yaml
version: "3"
services:
  node-app: # name what you want
    build: . # build from current file location (Dockerfile)
    ports:
      - "3000:3000"
    volumes:
      - ./:/app:ro
      - /app/node_modules
	environment:
      - PORT=3000
	env_file:
      - ./.env
```

```properties
# add [--build] build new image not from cache
docker-compose up -d
docker-compose down -v
```

- same as command before

```properties
docker run -v $(pwd):/app:ro -v /app/node_modules --env-file ./.env -p 3000:3000 -d --name node-app node-app-image
```

#### compose for dev or production

production can't change code

##### docker-compose.yml base

```yaml
version: '3'
services:
  node-app:
    build: .
    ports:
      - '3000:3000'
    environment:
      - PORT=3000
```

##### Dockerfile

```docker
FROM node
WORKDIR /app
COPY package.json .
RUN npm install
ARG NODE_ENV
COPY . ./
ENV PORT 3000
EXPOSE $PORT
CMD ["node", "index.js"] # can overwrite it in any composefile
```

##### docker-compose.dev.yml

```yaml
version: '3'
services:
  node-app:
    volumes:
      - ./:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
    command: npm run dev # from package.json -> scipt
```

##### docker-compose.prod.yml

- this still have nodemon in container

```yaml
version: '3'
services:
  node-app:
    environment:
      - NODE_ENV=production
    command: node index.js
```

- run 2 compose

```properties
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
```

#### Dockerfile add if select mode

fix nodemon to not install in production mode

```docker
FROM node
WORKDIR /app
COPY package.json .
# RUN npm install
ARG NODE_ENV
RUN if [ "$NODE_ENV" = "development" ]; \
    then npm install; \
    else npm install --only=production; \
    fi
COPY . ./
ENV PORT 3000
EXPOSE $PORT
CMD ["node", "index.js"]
```

##### docker-compose.dev.yml

```yaml
version: "3"
services:
  node-app:
  	build:
      context: . # specify location Dockerfile
      args:
        NODE_ENV: development
    volumes:
      - ./:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
    command: npm run dev # from package.json -> scipt
```

##### docker-compose.prod.yml

```yaml
version: "3"
services:
  node-app:
  	build:
      context: .
      args:
        NODE_ENV: production
    environment:
      - NODE_ENV=production
    command: node index.js

```

```properties
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build
```

#### Add MongoDB to compose

https://hub.docker.com/_/mongo

##### docker-compose.yml (add Mongo image)

```yaml
version: '3'
services:
  node-app:
    build: .
    ports:
      - '3000:3000'
    environment:
      - PORT=3000
    depends_on: # run mongo first
      - mongo

  mongo: # can use this name for ip address
    image: mongo
    environment:
      - MONGO_INITDB_ROOT_USERNAME=Moo
      - MONGO_INITDB_ROOT_PASSWORD=password
    volumes: # /my/own/datadir:/data/db
      - mongo-db:/data/db # ref in doc -> "Where to Store Data"

volumes: # provide volume not let another container use
  mongo-db:
```

exec to mongo bash then login

```properties
docker exec -it node-docker_mongo_1 bash
> mongo -u "Moo" -p "password"
```

or no exec

```properties
docker exec -it node-docker_mongo_1 mongo -u "Moo" -p "password"
```

remove volume not use (run what we use first)

```properties
docker volume prune
```

#### Communicating between containers

https://www.npmjs.com/package/mongoose

```properties
npm i mongoose
```

```javascript
const mongoose = require('mongoose')
```

https://mongoosejs.com/docs/connections.html

```javascript
mongoose.connect('mongodb://username:password@host:port/database?options...', {
  useNewUrlParser: true,
})
// port 27017
```

- Whai is my IP?

```properties
docker inspect [name]
```

- looking for "Networks" -> "IPAddress"
- or check in exec `ping mongo`
  this not good if ip change

```properties
docker network ls
```

- use name instead

```javascript
mongoose
  .connect('mongodb://Moo:password@mongo:27017/?authSource=admin')
  .then(() => console.log('succesfully connected'))
  .catch((e) => console.log(e))
```

```properties
docker logs [name] -f
```

- store id & pass somewhere else

```properties
mkdir config
cd config
touch config.js
```

#### config.js (store connect info)

```javascript
module.exports = {
  MONGO_IP: process.env.MONGO_IP || 'mongo',
  MONGO_PORT: process.env.MONGO_PORT || 27017,
  MONGO_USER: process.env.MONGO_USER,
  MONGO_PASSWORD: process.env.MONGO_PASSWORD,
}
```

#### index.js (connect to Mongo)

```javascript
const express = require('express')
const mongoose = require('mongoose')
const {
  MONGO_USER,
  MONGO_PASSWORD,
  MONGO_IP,
  MONGO_PORT,
} = require('./config/config')

const app = express()

const mongoURL = `mongodb://${MONGO_USER}:${MONGO_PASSWORD}@${MONGO_IP}:${MONGO_PORT}/?authSource=admin`

const connectWithRetry = () => {
  // wait mongo to run first
  mongoose
    .connect(mongoURL, {
      // remove warning
      useNewUrlParser: true,
      useUnifiedTopology: true,
      useFindAndModify: false,
    })
    .then(() => console.log('successfully connected to db'))
    .catch((e) => {
      console.log(e)
      setTimeout(connectWithRetry, 5000)
    })
}

connectWithRetry()

app.get('/', (req, res) => {
  res.send('<h1>Hi There joker ok</h1>')
})

const port = process.env.PORT || 3000

app.listen(port, console.log('listening on port ${port}'))
// app.listen(port, () => console.log("listening on port ${port}"));
```

#### docker-compose add add id & pass to connect Mongo

##### docker-compose.yml (add id & pass)

```yaml
version: '3'
services:
  node-app:
    build: .
    ports:
      - '3000:3000'
    environment:
      - PORT=3000
    depends_on:
      - mongo

  mongo:
    image: mongo
    environment:
      - MONGO_INITDB_ROOT_USERNAME=Moo
      - MONGO_INITDB_ROOT_PASSWORD=password
    volumes:
      - mongo-db:/data/db

volumes:
  mongo-db:
```

##### docker-compose.dev.yml (add id & pass)

```yaml
version: '3'
services:
  node-app:
    build:
      context: .
      args:
        NODE_ENV: development
    volumes:
      - ./:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
      - MONGO_USER=Moo
      - MONGO_PASSWORD=password
    command: npm run dev
  mongo:
    environment:
      - MONGO_INITDB_ROOT_USERNAME=Moo
      - MONGO_INITDB_ROOT_PASSWORD=password
```
