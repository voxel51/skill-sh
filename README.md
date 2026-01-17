<div align="center">

```
███████╗██╗  ██╗██╗██╗     ██╗        ███████╗██╗  ██╗
██╔════╝██║ ██╔╝██║██║     ██║        ██╔════╝██║  ██║
███████╗█████╔╝ ██║██║     ██║        ███████╗███████║
╚════██║██╔═██╗ ██║██║     ██║        ╚════██║██╔══██║
███████║██║  ██╗██║███████╗███████╗██╗███████║██║  ██║
╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚═╝╚══════╝╚═╝  ╚═╝
```

**Install agent skills with zero dependencies**

Powered by [Voxel51](https://voxel51.com)

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![FiftyOne Skills](https://img.shields.io/badge/FiftyOne-Skills-orange.svg)](https://github.com/voxel51/fiftyone-skills)

</div>

## Quick Start

```bash
curl -sL skil.sh | sh -s -- voxel51/fiftyone-skills
```

No Node. No Python. Just `curl`, `git`, and `sh`.

## Commands

```bash
# Install skills (interactive)
curl -sL skil.sh | sh -s -- owner/repo

# List available skills
curl -sL skil.sh | sh -s -- owner/repo --list

# List installed skills
curl -sL skil.sh | sh -s -- --installed

# Install specific skill globally
curl -sL skil.sh | sh -s -- owner/repo -s skill-name -g

# Non-interactive (CI/CD)
curl -sL skil.sh | sh -s -- owner/repo -y -g -a claude-code
```

## Options

| Option | Description |
|--------|-------------|
| `-s, --skill <name>` | Install specific skill(s) |
| `-a, --agent <name>` | Target specific agent(s) |
| `-g, --global` | Install to home directory |
| `-l, --list` | List available skills from repo |
| `-i, --installed` | List installed skills |
| `-y, --yes` | Skip prompts |

## Supported Agents

Claude Code, Cursor, Codex, OpenCode, GitHub Copilot, Amp, Antigravity, Roo Code, Kilo Code, Goose

## Resources

- [FiftyOne Skills](https://github.com/voxel51/fiftyone-skills) - Computer vision & ML workflows
- [Agent Skills Spec](https://agentskills.io) - Skills format specification
- [Discord](https://discord.gg/fiftyone-community) - Get help

<div align="center">

Copyright 2017-2026, Voxel51, Inc. · [MIT License](LICENSE)

</div>
