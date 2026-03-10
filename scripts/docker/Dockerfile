# Dockerfile for building libmpv (Linux and Windows cross-compile)
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install common build tools
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    ninja-build \
    nasm \
    pkg-config \
    autoconf \
    automake \
    libtool \
    git \
    curl \
    python3 \
    python3-pip \
    unzip \
    gperf \
    gettext \
    autopoint \
    && rm -rf /var/lib/apt/lists/*

# Install Meson via pip (to get a recent version)
RUN pip3 install --upgrade meson

# Linux build dependencies
RUN apt-get update && apt-get install -y \
    libva-dev \
    libvdpau-dev \
    libasound2-dev \
    libpulse-dev \
    libx11-dev \
    libxext-dev \
    libxrandr-dev \
    libxinerama-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Windows cross-compilation dependencies (MinGW)
RUN apt-get update && apt-get install -y \
    mingw-w64 \
    mingw-w64-tools \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
