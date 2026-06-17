# Stage 1: Build the Hermes Desktop app for Linux
FROM node:22-bookworm AS builder

ARG HERMES_SHA=unknown
ARG HERMES_REF=main

WORKDIR /build

COPY hermes-agent/package.json hermes-agent/package-lock.json ./
COPY hermes-agent/apps/shared/ apps/shared/
COPY hermes-agent/apps/desktop/ apps/desktop/
COPY hermes-agent/apps/bootstrap-installer/ apps/bootstrap-installer/

RUN npm install --prefer-offline --no-audit

WORKDIR /build/apps/desktop
ENV CSC_IDENTITY_AUTO_DISCOVERY=false
ENV GITHUB_SHA=${HERMES_SHA}
ENV GITHUB_REF_NAME=${HERMES_REF}
RUN npm run pack

# Stage 2: Runtime — LinuxServer KasmVNC base with the built Electron app
FROM ghcr.io/linuxserver/baseimage-kasmvnc:debianbookworm

ENV DEBIAN_FRONTEND=noninteractive

# Electron/Chromium runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk-3-0 libnotify4 libnss3 libxss1 libxtst6 \
    libatspi2.0-0 libdrm2 libgbm1 libasound2 \
    libx11-xcb1 libxcb-dri3-0 libxcomposite1 libxcursor1 \
    libxdamage1 libxfixes3 libxi6 libxrandr2 libxrender1 \
    libxshmfence1 libxext6 libx11-6 \
    libpango-1.0-0 libcairo2 libcups2 libdbus-1-3 \
    libexpat1 libfontconfig1 libgcc-s1 libglib2.0-0 \
    libnspr4 libuuid1 libappindicator3-1 \
    fonts-noto-core fonts-noto-cjk \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/apps/desktop/release/linux-unpacked /opt/hermes-desktop

COPY root/ /defaults/
COPY disable-auth.sh /custom-cont-init.d/disable-auth
RUN chmod +x /custom-cont-init.d/disable-auth

ENV HERMES_DESKTOP_DISABLE_GPU=1
ENV TITLE="Hermes Desktop"
ENV NO_DECOR=true

EXPOSE 3000
