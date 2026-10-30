# syntax=docker/dockerfile:1
# Targets: base (default), web, android, full (android + web)
ARG DEBIAN_VERSION=bookworm-slim

FROM debian:${DEBIAN_VERSION} AS base
ARG FLUTTER_VERSION
ARG FLUTTER_CHANNEL=stable
ENV DEBIAN_FRONTEND=noninteractive \
    FLUTTER_HOME=/opt/flutter \
    PUB_CACHE=/home/flutter/.pub-cache
ENV PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PUB_CACHE}/bin:${PATH}"

RUN test -n "${FLUTTER_VERSION}" || (echo "FLUTTER_VERSION build arg is required" >&2; exit 1) \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git unzip xz-utils zip \
      clang cmake ninja-build pkg-config libgtk-3-dev libglu1-mesa \
 && rm -rf /var/lib/apt/lists/* \
 && useradd --create-home --shell /bin/bash flutter \
 && git clone --depth 1 --branch "${FLUTTER_VERSION}" https://github.com/flutter/flutter.git "${FLUTTER_HOME}" \
 && git -C "${FLUTTER_HOME}" remote set-branches origin "${FLUTTER_CHANNEL}" \
 && git -C "${FLUTTER_HOME}" fetch --depth 1 origin "${FLUTTER_CHANNEL}" \
 && git -C "${FLUTTER_HOME}" checkout -q -B "${FLUTTER_CHANNEL}" \
 && git -C "${FLUTTER_HOME}" branch --set-upstream-to="origin/${FLUTTER_CHANNEL}" "${FLUTTER_CHANNEL}" \
 && chown -R flutter:flutter "${FLUTTER_HOME}" \
 && git config --system --add safe.directory "${FLUTTER_HOME}" \
 && mkdir -p /sdks && ln -s "${FLUTTER_HOME}" /sdks/flutter

USER root
WORKDIR /home/flutter
RUN flutter config --no-analytics --no-cli-animations \
 && flutter precache --linux \
 && flutter --version

LABEL org.opencontainers.image.source="https://github.com/manojvarmadiddi/flutter-docker" \
      org.opencontainers.image.title="flutter" \
      org.opencontainers.image.description="Flutter ${FLUTTER_VERSION} (${FLUTTER_CHANNEL})" \
      org.opencontainers.image.licenses="MIT"

# ---------------------------------------------------------------- web
FROM base AS web
USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends chromium \
 && rm -rf /var/lib/apt/lists/*
ENV CHROME_EXECUTABLE=/usr/bin/chromium
USER root
RUN flutter config --enable-web && flutter precache --web

# ---------------------------------------------------------------- android
FROM base AS android
ARG ANDROID_PLATFORM=35
ARG ANDROID_BUILD_TOOLS=35.0.0
ARG ANDROID_CMDLINE_TOOLS=11076708
USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends openjdk-17-jdk-headless \
 && rm -rf /var/lib/apt/lists/* \
 && ln -s "/usr/lib/jvm/java-17-openjdk-$(dpkg --print-architecture)" /usr/lib/jvm/java-17
ENV ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    JAVA_HOME=/usr/lib/jvm/java-17
ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"
RUN mkdir -p "${ANDROID_HOME}/cmdline-tools" \
 && curl -fsSL -o /tmp/cmdline-tools.zip \
      "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS}_latest.zip" \
 && unzip -q /tmp/cmdline-tools.zip -d "${ANDROID_HOME}/cmdline-tools" \
 && mv "${ANDROID_HOME}/cmdline-tools/cmdline-tools" "${ANDROID_HOME}/cmdline-tools/latest" \
 && rm /tmp/cmdline-tools.zip \
 && yes | sdkmanager --licenses >/dev/null \
 && sdkmanager "platform-tools" "platforms;android-${ANDROID_PLATFORM}" "build-tools;${ANDROID_BUILD_TOOLS}" \
 && chown -R flutter:flutter "${ANDROID_HOME}"
USER root
RUN flutter config --android-sdk "${ANDROID_HOME}" \
 && flutter precache --android \
 && (yes | flutter doctor --android-licenses >/dev/null || true)

# ---------------------------------------------------------------- full (android + web)
FROM android AS full
USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends chromium \
 && rm -rf /var/lib/apt/lists/*
ENV CHROME_EXECUTABLE=/usr/bin/chromium
USER root
RUN flutter config --enable-web && flutter precache --web
