#!/bin/bash
#
#

set -euo pipefail

sudo apt update -y
sudo apt install -y \
    autoconf \
    build-essential \
    curl \
    git \
    pkg-config \
    rbenv

# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
