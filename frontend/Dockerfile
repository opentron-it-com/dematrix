FROM node:20-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install --legacy-peer-deps

COPY public ./public
COPY src ./src

ENV PORT=3000
ENV REACT_APP_API_URL=http://localhost:8080/api

EXPOSE 3000

CMD ["npm", "start"]
