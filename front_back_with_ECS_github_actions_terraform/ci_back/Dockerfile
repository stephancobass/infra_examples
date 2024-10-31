FROM node:20-alpine

ARG BACKEND_TYPE
ENV ENV_BACKEND_TYPE=$BACKEND_TYPE

RUN [ ! -d /home/node/app ] && mkdir /home/node/app
RUN chown -R node:node /home/node/app
WORKDIR /home/node/app

COPY . .
RUN npm i
RUN npm run build
USER node

CMD node --optimize_for_size dist/$ENV_BACKEND_TYPE.js --mode run
