## Connect container (recap)

[skip recap](https://github.com/Wolowit/DockerWithNode.js-Express/blob/main/my-note/part_2-CommunicatingBettweenContainer.md#build-crud)

```properties
npm init -y
npm i express mongoose
npm i nodemon --save-dev

touch index.js .env .dockerignore docker-compose.yml docker-compose.prod.yml docker-compose.dev.yml Dockerfile

mkdir controllers models routes config

touch ./controllers/postController.js ./models/postModel.js ./routes/postRoute.js ./config/config.js
```

```javascript
"scripts": {

"start": "node index.js",

"dev": "nodemon index.js"

},
```

#### index.js

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

#### .env

```
PORT=4000
```

#### .dockerignore

```
node\_modules
Dockerfile
.dockerignore
.git
.gitignore
docker-compose\*
```

#### docker-compose.yml

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

#### docker-compose.prod.yml

```yaml
version: '3'
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

#### docker-compose.dev.yml

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

#### Dockerfile

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

#### ./config/config.js

```javascript
module.exports = {
  MONGO_IP: process.env.MONGO_IP || 'mongo',
  MONGO_PORT: process.env.MONGO_PORT || 27017,
  MONGO_USER: process.env.MONGO_USER,
  MONGO_PASSWORD: process.env.MONGO_PASSWORD,
}
```

---

## Build CRUD

#### ./controllers/postController.js

```javascript
const Post = require('../models/postModel')

exports.getAllPost = async (req, res, next) => {
  try {
    const post = await Post.find()
    res.status(200).json({
      status: 'success alot post',
      results: post.length,
      data: {
        post,
      },
    })
  } catch (e) {
    console.log(e)
    res.status(400).json({
      status: 'error',
    })
  }
}
// localhost:3000/post/:id

exports.getOnePost = async (req, res, next) => {
  try {
    const post = await Post.findById(req.params.id)
    res.status(200).json({
      status: 'success one post',
      data: {
        post,
      },
    })
  } catch (e) {
    console.log(e)
    res.status(400).json({
      status: 'error',
    })
  }
}

exports.createPost = async (req, res, next) => {
  try {
    const post = await Post.create(req.body)
    res.status(200).json({
      status: `success create ${req.body}`,
      data: {
        post,
      },
    })
  } catch (e) {
    console.log(e)
    res.status(400).json({
      status: 'error',
    })
  }
}

exports.updatePost = async (req, res, next) => {
  try {
    const post = await Post.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    })
    res.status(200).json({
      status: 'success update',
      data: {
        post,
      },
    })
  } catch (e) {
    console.log(e)
    res.status(400).json({
      status: 'error',
    })
  }
}

exports.deletePost = async (req, res, next) => {
  try {
    const post = await Post.findByIdAndDelete(req.params.id)
    res.status(200).json({
      status: 'success delete',
    })
  } catch (e) {
    console.log(e)
    res.status(400).json({
      status: 'error',
    })
  }
}
```

#### ./models/postModels.js

```javascript
const mongoose = require('mongoose')

const postSchema = new mongoose.Schema({
  title: {
    type: String,
    require: [true, 'Post must have title'],
  },
  body: {
    type: String,
    required: [true, 'Post must have body'],
  },
})

const Post = mongoose.model('Post', postSchema)
module.exports = Post
```

#### ./routes/route.js

```javascript
const express = require('express')

const postController = require('../controllers/postController')

const router = express.Router()

// localhost:3000/
router.route('/').get(postController.getAllPost).post(postController.createPost)

router
  .route('/:id')
  .get(postController.getOnePost)
  .patch(postController.updatePost)
  .delete(postController.deletePost)

module.exports = router
```

#### index.js

add

- `const postRouter = require('./routes/postRoute')`
- `app.use(express.json())`
- `app.use('/posts', postRouter)`

```javascript
const express = require('express')
const mongoose = require('mongoose')
const {
  MONGO_USER,
  MONGO_PASSWORD,
  MONGO_IP,
  MONGO_PORT,
} = require('./config/config')

const postRouter = require('./routes/postRoute') // <<<<<

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

app.use(express.json()) // <<<<<

app.get('/', (req, res) => {
  res.send('<h1>Hi There joker ok</h1>')
})

app.use('/api/v1/posts', postRouter) // <<<<<
const port = process.env.PORT || 3000

app.listen(port, console.log('listening on port ${port}'))
// app.listen(port, () => console.log("listening on port ${port}"));
```

## Add user model

```properties
touch ./models/userModel.js ./controllers/authController.js ./routes/userRoute.js

npm i bcryptjs
```

### Regis & Login

#### userModel.js

```javascript
const mongoose = require('mongoose')

const userSchema = new mongoose.Schema({
  username: {
    type: String,
    require: [true, 'User must have a username'],
  },
  password: {
    type: String,
    require: [true, 'User must have a password'],
  },
})

const User = mongoose.model('User', userSchema)

module.exports = User
```

#### authController.js

```javascript
const User = require('../models/userModel')

exports.signUp = async (req, res) => {
  try {
    const newUser = await User.create(req.body)
    res.status(200).json({
      status: 'success',
      data: newUser,
    })
  } catch (e) {
    res.status(400).json({
      status: 'error',
    })
  }
}
```

#### userRoute.js

```javascript
const express = require('express')

const authController = require('../controllers/authController')

const router = express.Router()

router.post('/signup', authController.signUp)

module.exports = router
```

---

#### index.js

add

- `const userRouter = require('./routes/userRoute')`
- `app.use('/api/v1/user', userRouter)`

```javascript
const express = require('express')
const mongoose = require('mongoose')
const {
  MONGO_USER,
  MONGO_PASSWORD,
  MONGO_IP,
  MONGO_PORT,
} = require('./config/config')

const postRouter = require('./routes/postRoute')
const userRouter = require('./routes/userRoute')

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

app.use(express.json())

app.get('/', (req, res) => {
  res.send('<h1>Hi There joker ok</h1>')
})

app.use('/api/v1/posts', postRouter)
app.use('/api/v1/users', userRouter)
const port = process.env.PORT || 3000

app.listen(port, console.log('listening on port ${port}'))
// app.listen(port, () => console.log("listening on port ${port}"));
```

#### authController.js (add bcryptjs to password)

add

- const bcrypt = require('bcryptjs')
- const { username, password } = req.body
- const hashpassword = await bcrypt.hash(password, 12)
- const newUser = await User.create({
  username,
  password: hashpassword,
  })

```javascript
const User = require('../models/userModel')

const bcrypt = require('bcryptjs')

exports.signUp = async (req, res) => {
  const { username, password } = req.body
  try {
    const hashpassword = await bcrypt.hash(password, 12)
    const newUser = await User.create({
      username,
      password: hashpassword,
    })
    res.status(201).json({
      status: 'success signUp',
      data: newUser,
    })
  } catch (e) {
    console.log(e)
    res.status(400).json({
      status: 'error cant',
    })
  }
}
```

---

#### authController.js add login (compare name pass)

```javascript
const User = require('../models/userModel')

const bcrypt = require('bcryptjs')

exports.signUp = async (req, res) => {
  const { username, password } = req.body
  try {
    const hashpassword = await bcrypt.hash(password, 12)
    const newUser = await User.create({
      username,
      password: hashpassword,
    })
    res.status(201).json({
      status: 'success signUp',
      data: newUser,
    })
  } catch (e) {
    console.log(e)
    res.status(400).json({
      status: 'error cant',
    })
  }
}

exports.login = async (req, res) => {
  const { username, password } = req.body
  try {
    const user = await User.findOne({ username })
    if (!user) {
      return res.status(404).json({
        status: 'error',
        message: 'user not found',
      })
    }
    const isCorrect = await bcrypt.compare(password, user.password)
    if (isCorrect) {
      res.status(200).json({
        status: 'success isCorrect',
      })
    } else {
      res.status(400).json({
        status: 'fail',
        message: 'incorrect username or password',
      })
    }
  } catch (e) {
    console.log(e)
    res.status(400).json({
      status: 'error cant',
    })
  }
}
```

#### userRoute.js (add route to login)

```javascript
const express = require('express')
const authController = require('../controllers/authController')
const router = express.Router()
router.post('/signup', authController.signUp)
router.post('/login', authController.login)
module.exports = router
```

---

### Add Sessions & Connect-Redis

https://www.npmjs.com/package/redis
https://www.npmjs.com/package/connect-redis

#### docker-compose.yml

https://hub.docker.com/_/redis

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

  redis: # name what you want
    image: redis

volumes:
  mongo-db:
```

- docker know what change

```properties
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

```properties
npm install redis connect-redis express-session

# [-V] create brand new anonymous volume
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build -V
```

- https://www.npmjs.com/package/express-session

#### index.js ( add redis-session)

```javascript
const express = require('express')
const mongoose = require('mongoose')

const session = require('express-session') // <<---
const redis = require('redis')
let RedisStore = require('connect-redis')(session)

const {
  MONGO_USER,
  MONGO_PASSWORD,
  MONGO_IP,
  MONGO_PORT,
  REDIS_URL, // <<---
  SESSION_SECRET, // <<---
  REDIS_PORT, // <<---
} = require('./config/config')

let redisClient = redis.createClient({
  // <<---
  host: REDIS_URL,
  port: REDIS_PORT,
})

const postRouter = require('./routes/postRoute')
const userRouter = require('./routes/userRoute')

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

app.use(
  session({
    // <<---
    store: new RedisStore({ client: redisClient }),
    secret: SESSION_SECRET,
    cookie: {
      //https://www.npmjs.com/package/express-session --> ## Options
      secure: false,
      resave: false,
      saveUninitialized: false,
      httpOnly: true, // javascript can't access?
      maxAge: 30000,
    },
  })
)
// ---
app.use(express.json())

app.get('/', (req, res) => {
  res.send('<h1>Hi There joker ok</h1>')
})

app.use('/api/v1/posts', postRouter)
app.use('/api/v1/users', userRouter)
const port = process.env.PORT || 3000

app.listen(port, console.log('listening on port ${port}'))
// app.listen(port, () => console.log("listening on port ${port}"));
```

#### config.js ( config var for session)

```javascript
module.exports = {
  MONGO_IP: process.env.MONGO_IP || 'mongo',
  MONGO_PORT: process.env.MONGO_PORT || 27017,
  MONGO_USER: process.env.MONGO_USER,
  MONGO_PASSWORD: process.env.MONGO_PASSWORD,
  REDIS_URL: process.env.REDIS_URL || 'redis',
  // use name(container) 'redis' for url, process.env.REDIS_URL for future if I want to use redis db.
  REDIS_PORT: process.env.REDIS_PORT || '6379',
  SESSION_SECRET: process.env.SESSION_SECRET,
}
```

#### docker-compose.dev.yml

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
      - SESSION_SECRET=secret # password for your session
    command: npm run dev
  mongo:
    environment:
      - MONGO_INITDB_ROOT_USERNAME=Moo
      - MONGO_INITDB_ROOT_PASSWORD=password
```

#### redis cli docker

```properties
docker exec -it [redis container] redis-cli
# see what sesion we have
KEYS *
# get info that key
GET ["key"]
```

#### authController.js (send info user to redis container)

1. `req.session.user = user`
2. `req.session.user = newUser`

```javascript
const User = require('../models/userModel')

const bcrypt = require('bcryptjs')

exports.signUp = async (req, res) => {
  const { username, password } = req.body
  try {
    const hashpassword = await bcrypt.hash(password, 12)
    const newUser = await User.create({
      username,
      password: hashpassword,
    })
    req.session.user = newUser // <<<----
    res.status(201).json({
      status: 'success signUp',
      data: newUser,
    })
  } catch (e) {
    console.log(e)
    res.status(400).json({
      status: 'error cant',
    })
  }
}

exports.login = async (req, res) => {
  const { username, password } = req.body
  try {
    const user = await User.findOne({ username })
    if (!user) {
      return res.status(404).json({
        status: 'error',
        message: 'user not found',
      })
    }
    const isCorrect = await bcrypt.compare(password, user.password)
    if (isCorrect) {
      req.session.user = user // <<<----
      res.status(200).json({
        status: 'success isCorrect',
      })
    } else {
      res.status(400).json({
        status: 'fail',
        message: 'incorrect username or password',
      })
    }
  } catch (e) {
    console.log(e)
    res.status(400).json({
      status: 'error cant',
    })
  }
}
```

### MiddleWare (Check is user login)

```properties
mkdir middleware
touch ./middleware/authMiddleware.js
```

#### authMiddleware

```javascript
const protect = (req, res, next) => {
  const { user } = req.session

  if (!user) {
    return res.status(401).json({ status: 'fail', message: 'unauthrized' })
  }
  req.user = user
  next()
}

module.exports = protect
```

#### postRoute.js

- protect path you want

```javascript
const express = require('express')

const postController = require('../controllers/postController')
const protect = require('../middleware/authMiddleware') // <<<<

const router = express.Router()

// localhost:3000/
router
  .route('/')
  .get(protect, postController.getAllPost) // <<<<
  .post(protect, postController.createPost)

router
  .route('/:id')
  .get(protect, postController.getOnePost)
  .patch(protect, postController.updatePost)
  .delete(protect, postController.deletePost)

module.exports = router
```

#### connect mongo directly through container

- note: we can add port to docker-compose.yml like in our app port 3000(in this case)
  ==BUT it less security==
  <img src="https://github.com/Wolowit/DockerWithNode.js-Express/blob/main/my-note/img/1.png" />

- multi container
  ==it not good if we hace alot app==
  <img src="https://github.com/Wolowit/DockerWithNode.js-Express/blob/main/my-note/img/2.png" />

##### Nginx ( load balancer)

https://www.nginx.com/resources/glossary/load-balancing/

- use #Nginx
  <img src="https://github.com/Wolowit/DockerWithNode.js-Express/blob/main/my-note/img/3.png" />

### Add nginx

```properties
mkdir nginx
touch ./nginx/default.conf
```

#### ./nginx/default.conf

```properties
server {
    listen 80;

    location /api {
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        proxy_set_header Host $http_host;
        proxy_set_header X-NginX-Proxy true;
        proxy_pass http://node-app:3000;
        proxy_redirect off;

    }
}
```

#### index.js (edit this)

```javascript
app.get('/api/v1', (req, res) => {
  res.send('<h1>Hi There joker ok</h1>')
})
```

#### docker-compose.yml

```yaml
version: '3'
services:
  nginx:
    image: nginx:stable-alpine
	ports:
      - '3000:80'
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro

  node-app:
    build: .
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

  redis: # name what you want
    image: redis

volumes:
  mongo-db:
```

#### docker-compose.dev.yml

```yaml
version: '3'
services:
  nginx:
    ports:
      - '3000:80'

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
      - SESSION_SECRET=secret # password for your session
    command: npm run dev
  mongo:
    environment:
      - MONGO_INITDB_ROOT_USERNAME=Moo
      - MONGO_INITDB_ROOT_PASSWORD=password
```

#### docker-compose.prod.yml

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
    command: node index.js
```

#### Express behind proxies

https://expressjs.com/en/guide/behind-proxies.html

##### index.js

`app.enable('trust proxy')`
`console.log('yeah it ran')`

```javascript
const express = require('express')
const mongoose = require('mongoose')

const session = require('express-session')
const redis = require('redis')
let RedisStore = require('connect-redis')(session)

const {
  MONGO_USER,
  MONGO_PASSWORD,
  MONGO_IP,
  MONGO_PORT,
  REDIS_URL,
  SESSION_SECRET,
  REDIS_PORT,
} = require('./config/config')

let redisClient = redis.createClient({
  host: REDIS_URL,
  port: REDIS_PORT,
})

const postRouter = require('./routes/postRoute')
const userRouter = require('./routes/userRoute')

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

app.enable('trust proxy') // <<<<<<<

app.use(
  session({
    store: new RedisStore({ client: redisClient }),
    secret: SESSION_SECRET,
    cookie: {
      //https://www.npmjs.com/package/express-session --> ## Options
      secure: false,
      resave: false,
      saveUninitialized: false,
      httpOnly: true, // javascript can't access?
      maxAge: 30000,
    },
  })
)

app.use(express.json())

app.get('/api/v1', (req, res) => {
  res.send('<h1>Hi There joker ok</h1>')
  console.log('yeah it ran')
})

app.use('/api/v1/posts', postRouter)
app.use('/api/v1/users', userRouter)
const port = process.env.PORT || 3000

app.listen(port, console.log('listening on port ${port}'))
// app.listen(port, () => console.log("listening on port ${port}"));
```

##### test nginx

```properties
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d --scale node-app=2
```

#### cors

[==Middleware==](https://expressjs.com/en/guide/writing-middleware.html#writing-middleware-for-use-in-express-apps)

- https://expressjs.com/en/guide/using-middleware.html#using-middleware
- https://expressjs.com/en/resources/middleware/cors.html

basically just allows your frontend to run on one domain and your backend api to run on a different domain because by default let's say your front end is hosted at www.google.com right and let's say your frontend sends a request to www.yahoo.com so let's say yahoo.com it's where our api exists well these are two dofferent domains by default our api will reject that request from our frontend so to allow these to be running on different domains we have to configure cors so that different domains can access our api

```properties
npm install cors
```

`const cors = require('cors')`
`app.use(cors({}))`

##### index.js (add cors)

```javascript
const express = require('express')
const mongoose = require('mongoose')
const session = require('express-session')
const redis = require('redis')
const cors = require('cors')
let RedisStore = require('connect-redis')(session)

const {
  MONGO_USER,
  MONGO_PASSWORD,
  MONGO_IP,
  MONGO_PORT,
  REDIS_URL,
  SESSION_SECRET,
  REDIS_PORT,
} = require('./config/config')

let redisClient = redis.createClient({
  host: REDIS_URL,
  port: REDIS_PORT,
})

const postRouter = require('./routes/postRoute')
const userRouter = require('./routes/userRoute')

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

app.enable('trust proxy')
app.use(cors({}))
app.use(
  session({
    store: new RedisStore({ client: redisClient }),
    secret: SESSION_SECRET,
    cookie: {
      //https://www.npmjs.com/package/express-session --> ## Options
      secure: false,
      resave: false,
      saveUninitialized: false,
      httpOnly: true, // javascript can't access?
      maxAge: 30000,
    },
  })
)

app.use(express.json())

app.get('/api/v1', (req, res) => {
  res.send('<h1>Hi There joker ok</h1>')
  console.log('yeah it ran')
})

app.use('/api/v1/posts', postRouter)
app.use('/api/v1/users', userRouter)
const port = process.env.PORT || 3000

app.listen(port, console.log('listening on port ${port}'))
// app.listen(port, () => console.log("listening on port ${port}"));
```
