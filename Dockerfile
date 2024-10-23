#
# BASE artifact
#
FROM --platform=linux/amd64 ubuntu:22.04 AS base

RUN apt-get update && apt-get install -y curl gnupg2 git

RUN curl -fsSL https://crystal-lang.org/install.sh | bash -s -- --channel=stable

#
# BUILDER artifact
#
FROM base AS builder

RUN mkdir -p /app
WORKDIR /app
COPY app/shard* /app/

RUN shards install

COPY app/ /app

#
# SERVICE 
#
FROM builder AS service

ENV image_name=crystalbank

WORKDIR /app

EXPOSE 3000
