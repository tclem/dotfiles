## Clean slate reset

# 1. Nuke the database (forces re-onboarding + fresh settings)
rm ~/.copilot/data.db*

# 2. Clean up orphaned worktrees
rm -rf ~/.copilot/copilot-worktrees/*

# 3. Prune stale git refs in each repo
cd ~/.copilot/repos/github_github-app && git worktree prune

# 4. Optionally clean session/workspace artifacts
rm -rf ~/.copilot/workspaces/*
rm -rf ~/.copilot/session-state/*
rm -rf ~/.copilot/chats/*
