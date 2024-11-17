# Start with a minimal Debian-based image
FROM debian:bookworm-slim

# Set non-interactive mode to avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential dependencies
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    pkg-config \
    qmake6 \
    qt6-base-dev \
    qt6-declarative-dev \
    qt6-tools-dev \
    qt6-multimedia-dev \
    build-essential \
    libssl-dev \
    libxcb1-dev \
    x11-apps \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables for Qt6 (optional but can help)
ENV QTDIR=/usr/lib/x86_64-linux-gnu/qt6
ENV PATH=$QTDIR/bin:$PATH
ENV LD_LIBRARY_PATH=$QTDIR/lib:$LD_LIBRARY_PATH

RUN apt-get update && apt-get install curl

RUN curl https://sh.rustup.rs -sSf | bash -s -- -y

RUN echo '. $HOME/.cargo/env' >> $HOME/.bashrc

RUN . "$HOME/.cargo/env"

# Set the working directory
WORKDIR /app

# Copy your source code into the container
# COPY hyperbase /app

# RUN qmake && make

# ENTRYPOINT "./run.sh"
CMD "/bin/bash"

