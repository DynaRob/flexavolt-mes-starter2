FROM node:20-alpine
WORKDIR /app
COPY package.json /app/package.json
COPY packages /app/packages
RUN npm install
WORKDIR /app/packages/print-agent
RUN npm run build
CMD ["npm","run","start"]
