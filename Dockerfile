FROM golang:1.22 AS api-builder

WORKDIR /src

COPY ./rogueserver/go.mod /src/
COPY ./rogueserver/go.sum /src/

RUN go mod download && go mod verify

COPY ./rogueserver /src/

RUN CGO_ENABLED=0 go build -o rogueserver

# ---------------------------------------------

FROM node:20 AS web-builder

WORKDIR /src

COPY ./pokerogue/package.json /src/
COPY ./pokerogue/package-lock.json /src/

RUN npm install

COPY ./pokerogue /src/

RUN npm run build

# ---------------------------------------------

FROM ghcr.io/thedevminertv/gostatic AS web-server

# ---------------------------------------------

FROM alpine:3.19
WORKDIR /home/container

COPY --from=web-builder /src/dist /usr/share/pokerogue
COPY --from=api-builder /src/rogueserver /bin
COPY --from=web-server /bin/gostatic /bin

COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]
