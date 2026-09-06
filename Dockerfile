ARG TARGETPLATFORM

# --- Étape 1 : Build TypeScript & Dépendances ---
FROM --platform=$TARGETPLATFORM node:20-slim AS build

WORKDIR /app

# Outils de compilation natifs requis pour ARM64
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3 make g++ && \
    rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json* ./
RUN npm install

COPY src ./src
COPY tsconfig.json ./
RUN npx tsc

# Suppression des dépendances de dev après la compilation TypeScript
RUN npm prune --omit=dev

# --- Étape 2 : Image d'exécution (Runtime) ---
FROM --platform=$TARGETPLATFORM node:20-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends android-tools-adb && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package.json ./
COPY bin ./bin
COPY resources ./resources

# Copie des modules compilés et du code JS généré depuis l'étape build
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
