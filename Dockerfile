FROM ubuntu:focal

# Set environment variables
ENV ANDROID_SDK_ROOT=/usr/lib/android-sdk

ENV FLUTTER_SDK_ROOT=/usr/lib/flutter
ENV FLUTTER_SDK_VERSION=3.44.0-stable

# Include flutter and android tools in path
ENV PATH="${PATH}:${FLUTTER_SDK_ROOT}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools"

# Enable noninteractive installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies and tools
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    apt-transport-https \
    ca-certificates \
    gnupg \
    software-properties-common \
    wget \
    curl \
    git \
    lib32z1 \
    libbz2-1.0:amd64 \
    libc6:amd64 \
    libglu1-mesa \
    libstdc++6:amd64 \
    openjdk-17-jdk \
    unzip \
    wget \
    xz-utils \
    zip

RUN apt-get update && apt-get install -y ca-certificates gpg wget gnupg \
software-properties-common && rm -rf /var/lib/apt/lists/*

RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc | gpg --dearmor > /usr/share/keyrings/kitware-archive-keyring.gpg

RUN echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ focal main" | tee /etc/apt/sources.list.d/kitware.list

RUN apt-get update && apt-get install -y cmake clang ninja-build pkg-config && rm -rf /var/lib/apt/lists/*


# Add flutter to safe directory in git
RUN git config --system --add safe.directory /usr/lib/flutter


# Download and install Android Command Line Tools
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    wget -O commandlinetools.zip "https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip" && \
    unzip commandlinetools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
    mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
    rm commandlinetools.zip

# Accept Android SDK licenses and install necessary components
RUN yes | ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --licenses && \
    ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"

# Insall Flutter SDK
RUN mkdir -p ${FLUTTER_SDK_ROOT} && \
    cd ${FLUTTER_SDK_ROOT} && \
    curl -OL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_SDK_VERSION}.tar.xz && \
    tar -xf flutter_linux_${FLUTTER_SDK_VERSION}.tar.xz -C /usr/lib/ && \
    rm -rf flutter_linux_${FLUTTER_SDK_VERSION}.tar.xz

# Disable Flutter telemetry
RUN flutter --disable-analytics

RUN flutter doctor
# Default shell to bash
SHELL ["/bin/bash", "-c"]