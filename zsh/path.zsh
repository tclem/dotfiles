export MANPATH="/usr/local/man:/usr/local/mysql/man:/usr/local/git/man:$MANPATH"
export PATH="/usr/local/bin:$ZSH/bin:$PATH" # homebrew
export PATH=$PATH:$HOME/go/bin # Go binaries
export PATH="$HOME/.cargo/bin:$PATH" # Rust cargo
export PATH=":bin:$PATH"

export PATH="/usr/local/opt/mysql-client/bin:$PATH" # mysql

# export PATH="/usr/local/opt/python@3.8/libexec/bin:$PATH"

# node and npm, specifically not using a version manager as I only work with
# node in the tree-sitter project.
# export PATH="/usr/local/opt/node@10/bin:$PATH"
# export PATH="$PATH:./node_modules/.bin"
