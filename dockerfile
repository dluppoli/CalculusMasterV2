FROM node:18-alpine3.18
RUN mkdir -p /opt/app
WORKDIR /opt/app
COPY ./ .
RUN npm install
CMD [ "npm", "start"]

