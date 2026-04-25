# syntax=docker/dockerfile:1

FROM node:22-alpine AS assets
WORKDIR /app

COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile

COPY src ./src
COPY public ./public
RUN pnpm exec tailwindcss -i ./src/style.css -o ./public/css/tailwind.css --minify

FROM crystallang/crystal:1.20-alpine AS builder
WORKDIR /app
ENV CRYSTAL_PATH=src:lib:/usr/bin/../share/crystal/src

RUN apk add --no-cache postgresql-dev

COPY shard.yml shard.lock ./
RUN shards install --production

COPY . .
COPY --from=assets /app/public/css/tailwind.css ./public/css/tailwind.css
RUN crystal build src/mercado-crystal.cr --release -o bin/server

FROM alpine:3.21
WORKDIR /app

RUN apk add --no-cache \
    ca-certificates \
    gc \
    libevent \
    libgcc \
    openssl \
    pcre2 \
    postgresql-libs \
    tzdata \
    yaml \
    zlib

COPY --from=builder /app/bin/server ./server
COPY --from=builder /app/public ./public

EXPOSE 3000
CMD ["./server"]
