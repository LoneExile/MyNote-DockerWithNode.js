FROM node
WORKDIR /app
COPY package.json . 
RUN npm install
ARG NODE_ENV
COPY . ./
ENV PORT 3000
EXPOSE $PORT
CMD ["node", "index.js"] # can overwrite it in any composefile