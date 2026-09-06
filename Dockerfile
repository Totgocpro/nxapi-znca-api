ARG TARGETPLATFORM

FROM --platform=$TARGETPLATFORM node:20-slim AS build

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY src ./src
COPY tsconfig.json ./

RUN npx tsc

FROM --platform=$TARGETPLATFORM node:20-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends android-tools-adb && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY bin ./bin
COPY resources ./resources
COPY --from=build /app/dist ./dist

RUN chmod +x /app/bin/nxapi-znca-api.js /app/resources/docker-entrypoint.sh && \
    ln -s /app/bin/nxapi-znca-api.js /usr/local/bin/nxapi-znca-api

ENV NXAPI_DATA_PATH=/data
ENV NODE_ENV=production

RUN mkdir -p /data && ln -s /data/android /root/.android

VOLUME [ "/data" ]

ENTRYPOINT [ "/app/resources/docker-entrypoint.sh" ]
CMD [ "--help" ]
