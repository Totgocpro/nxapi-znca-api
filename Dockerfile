ARG TARGETPLATFORM

# --- Étape 1 : Build TypeScript & Dépendances ---
FROM --platform=$TARGETPLATFORM node:20-slim AS build

WORKDIR /app

# Ajout de git, ca-certificates et des outils de compilation natifs
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3 make g++ git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json* ./

# Installation permissive pour éviter les blocages de peer-dependencies
RUN npm install --legacy-peer-deps

COPY src ./src
COPY tsconfig.json ./
RUN npx tsc

# Nettoyage des packages dev pour alléger le dossier final
RUN npm prune --omit=dev --legacy-peer-deps

# --- Étape 2 : Image d'exécution (Runtime ARM64) ---
FROM --platform=$TARGETPLATFORM node:20-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends android-tools-adb && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package.json ./
COPY bin ./bin
COPY resources ./resources

COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist

RUN chmod +x /app/bin/nxapi-znca-api.js /app/resources/docker-entrypoint.sh && \
    ln -s /app/bin/nxapi-znca-api.js /usr/local/bin/nxapi-znca-api

ENV NXAPI_DATA_PATH=/data
ENV NODE_ENV=production

RUN mkdir -p /data && ln -s /data/android /root/.android

VOLUME [ "/data" ]

ENTRYPOINT [ "/app/resources/docker-entrypoint.sh" ]
CMD [ "--help" ]
