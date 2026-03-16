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

# Install Rust
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Back to non-root agent user
USER agent

# Copilot config and instructions
COPY --chown=agent:agent copilot-instructions.md /home/agent/.copilot/copilot-instructions.md
COPY --chown=agent:agent config.json /home/agent/.copilot/config.json

# Cargo uses git CLI for private repo fetches
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true

# Setup the entrypoint
COPY --chown=agent:agent entrypoint.sh /home/agent/entrypoint.sh
RUN chmod +x /home/agent/entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/home/agent/entrypoint.sh"]
CMD ["sleep", "infinity"]
