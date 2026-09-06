ARG REDROID_IMAGE=redroid/redroid:11.0.0-latest
FROM $REDROID_IMAGE as redroid

FROM alpine AS download-apk

ARG CORAL_APK_URL
ARG CORAL_APK_HASH_SHA256

RUN apk add curl perl-utils unzip
RUN curl -v -L -o /coral.apk "${CORAL_APK_URL}"
RUN echo "${CORAL_APK_HASH_SHA256}  /coral.apk" | shasum -a 256 -c -
RUN unzip -d /apk -o /coral.apk 'lib/*'

FROM alpine AS download-frida

ARG FRIDA_SERVER_URL=https://github.com/frida/frida/releases/download/16.0.7/frida-server-16.0.7-android-arm64.xz

RUN apk add curl xz
RUN curl -v -L -o /frida-server.xz "${FRIDA_SERVER_URL}"
RUN xz --decompress -k /frida-server.xz
RUN chmod +x /frida-server

FROM redroid

# Note: La ligne 'RUN mv su _su' a été supprimée pour éviter le Segfault (Exit code 139) sous BuildKit ARM.

# Copie de l'APK
COPY --from=download-apk /coral.apk /system/app/Coral/Coral.apk

# Copie des bibliothèques natived ARM64 au lieu des bibliothèques x86/x86_64
COPY --from=download-apk /apk/lib/arm64-v8a /system/lib64

# Copie de Frida Server version ARM64
COPY --from=download-frida /frida-server /system/bin/frida-server

ENTRYPOINT [ "/init", "qemu=1", "androidboot.hardware=redroid", "ro.secure=0", "androidboot.use_memfd=1" ]

ARG CORAL_APK_VERSION
ARG CORAL_APK_BUILD
ARG CORAL_APK_HASH_SHA256

LABEL uk.org.fancy.nxapi-znca-api.coral.version=${CORAL_APK_VERSION}
LABEL uk.org.fancy.nxapi-znca-api.coral.build=${CORAL_APK_BUILD}
LABEL uk.org.fancy.nxapi-znca-api.coral.apk_hash_sha256=${CORAL_APK_HASH_SHA256}
