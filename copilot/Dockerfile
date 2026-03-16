FROM ubuntu:noble

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    ca-certificates \
    cmake \
    curl \
    curl \
    git \
    golang-go \
    jq \
    libssl-dev \
    libssl-dev \
    pkg-config \
    ripgrep \
    sudo \
    unzip \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Rust
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

# Install protoc
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user 'agent' with sudo privileges
RUN useradd -m -s /bin/bash -G sudo agent \
    && echo "agent ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/agent \
    && chmod 0440 /etc/sudoers.d/agent

# Install Copilot CLI
ARG COPILOT_VERSION=latest
RUN npm install -g @github/copilot@${COPILOT_VERSION}

USER agent
WORKDIR /home/agent

RUN mkdir -p /home/agent/.config/copilot \
    && mkdir -p /home/agent/.local/state/copilot \
    && mkdir -p /home/agent/.local/share/copilot

# Set XDG directories for Copilot CLI
ENV XDG_CONFIG_HOME=/home/agent/.config
ENV XDG_STATE_HOME=/home/agent/.local/state
ENV XDG_DATA_HOME=/home/agent/.local/share

# Add npm global bin to PATH
ENV PATH="/home/agent/.npm-global/bin:$PATH"
ENV NPM_CONFIG_PREFIX=/home/agent/.npm-global

# Enable staff mode and update copilot CLI via its own update channel
COPY --chown=agent:agent copilot-instructions.md /home/agent/.copilot/copilot-instructions.md
COPY --chown=agent:agent config.json /home/agent/.copilot/config.json
RUN copilot update || true

# Cargo uses git CLI for private repo fetches
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true

# Setup the entrypoint
COPY --chown=agent:agent entrypoint.sh /home/agent/entrypoint.sh
RUN chmod +x /home/agent/entrypoint.sh

# Working directory for mounted workspaces
WORKDIR /workspace

ENTRYPOINT ["/home/agent/entrypoint.sh"]
CMD ["sleep", "infinity"]
