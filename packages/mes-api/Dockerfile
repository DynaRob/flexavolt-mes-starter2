FROM node:20-alpine
WORKDIR /app
COPY package.json /app/package.json
COPY packages /app/packages
RUN npm install
WORKDIR /app/packages/mes-api
RUN npm run build
EXPOSE 8080
CMD ["npm","run","start"]
