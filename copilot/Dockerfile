# Official sandbox template includes: Ubuntu, Node.js, Go, Python 3, Git,
# GitHub CLI, Docker CLI, ripgrep, jq, make, and the copilot agent binary.
FROM docker/sandbox-templates:copilot

# Switch to root for system-level installations
USER root

# Add build toolchain and libraries for Rust/native compilation
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    libssl-dev \
    pkg-config \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Back to non-root agent user
USER agent

# Install Rust as agent so rustup can manage toolchains at runtime
ENV RUSTUP_HOME=/home/agent/.rustup \
    CARGO_HOME=/home/agent/.cargo \
    PATH=/home/agent/.cargo/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Copilot config and instructions
COPY --chown=agent:agent copilot-instructions.md /home/agent/.copilot/copilot-instructions.md
COPY --chown=agent:agent config.json /home/agent/.copilot/config.json

# Git credential helper: reads GH_TOKEN at invocation time for private repos
RUN printf '#!/bin/sh\nif [ "$1" = "get" ]; then\n  while IFS= read -r line; do\n    case "$line" in host=*) host="${line#host=}" ;; esac\n  done\n  if [ "$host" = "github.com" ]; then\n    echo "protocol=https"\n    echo "host=github.com"\n    echo "username=x-access-token"\n    echo "password=$GH_TOKEN"\n  fi\nfi\n' \
      > /home/agent/.git-credential-gh-token \
    && chmod +x /home/agent/.git-credential-gh-token \
    && git config --global credential.https://github.com.helper /home/agent/.git-credential-gh-token \
    && git config --global --add safe.directory /workspace

# Cargo uses git CLI for private repo fetches
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true
