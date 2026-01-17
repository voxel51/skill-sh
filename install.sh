#!/bin/sh
# skill.sh - Install agent skills with zero dependencies
# https://github.com/voxel51/skill-sh
# Powered by Voxel51
#
# Usage: curl -sL https://skill.sh | sh -s -- owner/repo
#        curl -sL https://skill.sh | sh -s -- owner/repo --skill my-skill --agent claude-code

set -e

# ─────────────────────────────────────────────────────────────────────────────
# Colors and formatting
# ─────────────────────────────────────────────────────────────────────────────

if [ -t 1 ]; then
  BOLD=$(printf '\033[1m')
  DIM=$(printf '\033[2m')
  CYAN=$(printf '\033[36m')
  GREEN=$(printf '\033[32m')
  YELLOW=$(printf '\033[33m')
  RED=$(printf '\033[31m')
  ORANGE=$(printf '\033[38;5;208m')
  RESET=$(printf '\033[0m')
else
  BOLD=''
  DIM=''
  CYAN=''
  GREEN=''
  YELLOW=''
  RED=''
  ORANGE=''
  RESET=''
fi

# ─────────────────────────────────────────────────────────────────────────────
# Output helpers
# ─────────────────────────────────────────────────────────────────────────────

info() {
  printf "%s◇%s  %s\n" "$CYAN" "$RESET" "$1"
}

success() {
  printf "%s◆%s  %s\n" "$GREEN" "$RESET" "$1"
}

warn() {
  printf "%s◇%s  %s\n" "$YELLOW" "$RESET" "$1"
}

error() {
  printf "%s✗%s  %s\n" "$RED" "$RESET" "$1"
}

step() {
  printf "%s│%s\n" "$DIM" "$RESET"
}

header() {
  printf "\n"
  printf "%s███████╗██╗  ██╗██╗██╗     ██╗        ███████╗██╗  ██╗%s\n" "$ORANGE" "$RESET"
  printf "%s██╔════╝██║ ██╔╝██║██║     ██║        ██╔════╝██║  ██║%s\n" "$ORANGE" "$RESET"
  printf "%s███████╗█████╔╝ ██║██║     ██║        ███████╗███████║%s\n" "$ORANGE" "$RESET"
  printf "%s╚════██║██╔═██╗ ██║██║     ██║        ╚════██║██╔══██║%s\n" "$ORANGE" "$RESET"
  printf "%s███████║██║  ██╗██║███████╗███████╗██╗███████║██║  ██║%s\n" "$ORANGE" "$RESET"
  printf "%s╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚═╝╚══════╝╚═╝  ╚═╝%s\n" "$ORANGE" "$RESET"
  printf "%sPowered by Voxel51%s\n" "$DIM" "$RESET"
  printf "\n"
}

footer() {
  printf "%s│%s\n" "$DIM" "$RESET"
  printf "%s└  %sDone!%s\n\n" "$BOLD" "$GREEN" "$RESET"
}

# ─────────────────────────────────────────────────────────────────────────────
# Agent configurations
# ─────────────────────────────────────────────────────────────────────────────

HOME_DIR="$HOME"

# Agent: name|display_name|project_dir|global_dir|detect_path
AGENTS="
opencode|OpenCode|.opencode/skill|$HOME_DIR/.config/opencode/skill|$HOME_DIR/.config/opencode
claude-code|Claude Code|.claude/skills|$HOME_DIR/.claude/skills|$HOME_DIR/.claude
codex|Codex|.codex/skills|$HOME_DIR/.codex/skills|$HOME_DIR/.codex
cursor|Cursor|.cursor/skills|$HOME_DIR/.cursor/skills|$HOME_DIR/.cursor
amp|Amp|.agents/skills|$HOME_DIR/.config/agents/skills|$HOME_DIR/.config/amp
antigravity|Antigravity|.agent/skills|$HOME_DIR/.gemini/antigravity/skills|$HOME_DIR/.gemini/antigravity
github-copilot|GitHub Copilot|.github/skills|$HOME_DIR/.copilot/skills|$HOME_DIR/.copilot
roo|Roo Code|.roo/skills|$HOME_DIR/.roo/skills|$HOME_DIR/.roo
kilo|Kilo Code|.kilocode/skills|$HOME_DIR/.kilocode/skills|$HOME_DIR/.kilocode
goose|Goose|.goose/skills|$HOME_DIR/.config/goose/skills|$HOME_DIR/.config/goose
"

# ─────────────────────────────────────────────────────────────────────────────
# Helper functions
# ─────────────────────────────────────────────────────────────────────────────

get_agent_field() {
  echo "$1" | cut -d'|' -f"$2"
}

detect_installed_agents() {
  detected=""
  echo "$AGENTS" | while IFS= read -r line; do
    [ -z "$line" ] && continue
    name=$(get_agent_field "$line" 1)
    detect_path=$(get_agent_field "$line" 5)
    if [ -d "$detect_path" ]; then
      echo "$name"
    fi
  done
}

get_agent_config() {
  echo "$AGENTS" | while IFS= read -r line; do
    [ -z "$line" ] && continue
    name=$(get_agent_field "$line" 1)
    if [ "$name" = "$1" ]; then
      echo "$line"
      return
    fi
  done
}

get_display_name() {
  config=$(get_agent_config "$1")
  get_agent_field "$config" 2
}

get_install_path() {
  # $1 = agent name, $2 = skill name, $3 = global (1 or 0)
  config=$(get_agent_config "$1")
  if [ "$3" = "1" ]; then
    base=$(get_agent_field "$config" 4)
  else
    base="$(pwd)/$(get_agent_field "$config" 3)"
  fi
  echo "$base/$2"
}

# ─────────────────────────────────────────────────────────────────────────────
# Parse source URL
# ─────────────────────────────────────────────────────────────────────────────

parse_source() {
  input="$1"

  # GitHub URL with tree path
  if echo "$input" | grep -qE 'github\.com/[^/]+/[^/]+/tree/[^/]+/.+'; then
    owner=$(echo "$input" | sed -E 's|.*github\.com/([^/]+)/([^/]+)/tree/([^/]+)/(.+)|\1|')
    repo=$(echo "$input" | sed -E 's|.*github\.com/([^/]+)/([^/]+)/tree/([^/]+)/(.+)|\2|')
    subpath=$(echo "$input" | sed -E 's|.*github\.com/([^/]+)/([^/]+)/tree/([^/]+)/(.+)|\4|')
    REPO_URL="https://github.com/$owner/$repo.git"
    REPO_SUBPATH="$subpath"
    return
  fi

  # GitHub URL
  if echo "$input" | grep -qE 'github\.com/[^/]+/[^/]+'; then
    owner=$(echo "$input" | sed -E 's|.*github\.com/([^/]+)/([^/]+).*|\1|')
    repo=$(echo "$input" | sed -E 's|.*github\.com/([^/]+)/([^/]+).*|\2|' | sed 's/\.git$//')
    REPO_URL="https://github.com/$owner/$repo.git"
    REPO_SUBPATH=""
    return
  fi

  # GitHub shorthand: owner/repo or owner/repo/path
  if echo "$input" | grep -qE '^[^/]+/[^/]+' && ! echo "$input" | grep -q ':'; then
    owner=$(echo "$input" | cut -d'/' -f1)
    repo=$(echo "$input" | cut -d'/' -f2)
    subpath=$(echo "$input" | cut -d'/' -f3- | sed 's|^/*||')
    REPO_URL="https://github.com/$owner/$repo.git"
    REPO_SUBPATH="$subpath"
    return
  fi

  # Fallback: treat as git URL
  REPO_URL="$input"
  REPO_SUBPATH=""
}

# ─────────────────────────────────────────────────────────────────────────────
# Discover skills in a directory
# ─────────────────────────────────────────────────────────────────────────────

discover_skills() {
  base_path="$1"
  search_path="$base_path"
  [ -n "$REPO_SUBPATH" ] && search_path="$base_path/$REPO_SUBPATH"

  FOUND_SKILLS=""

  # Priority search directories
  search_dirs="
$search_path
$search_path/skills
$search_path/skills/.curated
$search_path/skills/.experimental
$search_path/.claude/skills
$search_path/.codex/skills
$search_path/.cursor/skills
$search_path/.opencode/skill
$search_path/.agents/skills
$search_path/.agent/skills
$search_path/.github/skills
"

  echo "$search_dirs" | while IFS= read -r dir; do
    [ -z "$dir" ] && continue
    [ ! -d "$dir" ] && continue

    # Check subdirectories for SKILL.md
    for skill_dir in "$dir"/*/; do
      [ ! -d "$skill_dir" ] && continue
      if [ -f "$skill_dir/SKILL.md" ]; then
        # Parse name from SKILL.md frontmatter
        skill_name=$(grep -E '^name:' "$skill_dir/SKILL.md" 2>/dev/null | head -1 | sed 's/^name:[[:space:]]*//' | tr -d '"' | tr -d "'")
        skill_desc=$(grep -E '^description:' "$skill_dir/SKILL.md" 2>/dev/null | head -1 | sed 's/^description:[[:space:]]*//' | tr -d '"' | tr -d "'")
        if [ -n "$skill_name" ]; then
          echo "$skill_name|$skill_desc|$skill_dir"
        fi
      fi
    done
  done | sort -u
}

# ─────────────────────────────────────────────────────────────────────────────
# Interactive selection
# ─────────────────────────────────────────────────────────────────────────────

select_items() {
  prompt="$1"
  items="$2"
  allow_multiple="$3"

  # Save items to temp file to avoid subshell issues
  items_file=$(mktemp)
  echo "$items" > "$items_file"

  # Count items
  item_count=$(grep -c '|' "$items_file" || echo "0")

  while true; do
    # Display numbered list (read from file, not pipe)
    i=1
    while IFS='|' read -r name rest; do
      [ -z "$name" ] && continue
      printf "  %s%d)%s %s\n" "$DIM" "$i" "$RESET" "$name" >&2
      i=$((i + 1))
    done < "$items_file"

    printf "\n%s?%s %s %s(comma-separated numbers, or 'a' for all)%s: " "$CYAN" "$RESET" "$prompt" "$DIM" "$RESET" >&2
    read -r selection </dev/tty

    # Validate input
    if [ -z "$selection" ]; then
      printf "  %s⚠%s  Please enter a selection\n\n" "$YELLOW" "$RESET" >&2
      continue
    fi

    if [ "$selection" = "a" ] || [ "$selection" = "A" ]; then
      while IFS='|' read -r name rest; do
        [ -z "$name" ] && continue
        echo "$name"
      done < "$items_file"
      rm -f "$items_file"
      return
    fi

    # Validate numbers
    valid=1
    for num in $(echo "$selection" | tr ',' ' '); do
      num=$(echo "$num" | tr -d ' ')
      [ -z "$num" ] && continue
      # Check if it's a number
      if ! echo "$num" | grep -qE '^[0-9]+$'; then
        printf "  %s⚠%s  '%s' is not a valid number\n\n" "$YELLOW" "$RESET" "$num" >&2
        valid=0
        break
      fi
      # Check if in range
      if [ "$num" -lt 1 ] || [ "$num" -gt "$item_count" ]; then
        printf "  %s⚠%s  '%s' is out of range (1-%d)\n\n" "$YELLOW" "$RESET" "$num" "$item_count" >&2
        valid=0
        break
      fi
    done

    [ "$valid" = "0" ] && continue

    # Parse comma-separated numbers
    echo "$selection" | tr ',' '\n' | while read -r num; do
      num=$(echo "$num" | tr -d ' ')
      [ -z "$num" ] && continue
      sed -n "${num}p" "$items_file" | cut -d'|' -f1
    done

    rm -f "$items_file"
    return
  done
}

confirm() {
  printf "%s?%s %s %s[Y/n]%s: " "$CYAN" "$RESET" "$1" "$DIM" "$RESET"
  read -r answer </dev/tty
  case "$answer" in
    [nN]*) return 1 ;;
    *) return 0 ;;
  esac
}

# ─────────────────────────────────────────────────────────────────────────────
# List installed skills
# ─────────────────────────────────────────────────────────────────────────────

list_installed() {
  header
  printf "%sInstalled Skills%s\n\n" "$BOLD" "$RESET"

  found_any=0

  echo "$AGENTS" | while IFS= read -r line; do
    [ -z "$line" ] && continue
    name=$(get_agent_field "$line" 1)
    display=$(get_agent_field "$line" 2)
    project_dir=$(get_agent_field "$line" 3)
    global_dir=$(get_agent_field "$line" 4)

    # Check global skills
    if [ -d "$global_dir" ]; then
      skills_found=0
      for skill_dir in "$global_dir"/*/; do
        [ ! -d "$skill_dir" ] && continue
        if [ -f "$skill_dir/SKILL.md" ]; then
          if [ "$skills_found" -eq 0 ]; then
            printf "%s%s%s %s(global)%s\n" "$CYAN" "$display" "$RESET" "$DIM" "$RESET"
            skills_found=1
            found_any=1
          fi
          skill_name=$(basename "$skill_dir")
          desc=$(grep -E '^description:' "$skill_dir/SKILL.md" 2>/dev/null | head -1 | sed 's/^description:[[:space:]]*//' | tr -d '"' | tr -d "'" | cut -c1-60)
          printf "  %s✓%s %s\n" "$GREEN" "$RESET" "$skill_name"
          [ -n "$desc" ] && printf "    %s%s%s\n" "$DIM" "$desc" "$RESET"
        fi
      done
    fi

    # Check project skills (current directory)
    project_path="$(pwd)/$project_dir"
    if [ -d "$project_path" ]; then
      skills_found=0
      for skill_dir in "$project_path"/*/; do
        [ ! -d "$skill_dir" ] && continue
        if [ -f "$skill_dir/SKILL.md" ]; then
          if [ "$skills_found" -eq 0 ]; then
            printf "%s%s%s %s(project)%s\n" "$CYAN" "$display" "$RESET" "$DIM" "$RESET"
            skills_found=1
            found_any=1
          fi
          skill_name=$(basename "$skill_dir")
          desc=$(grep -E '^description:' "$skill_dir/SKILL.md" 2>/dev/null | head -1 | sed 's/^description:[[:space:]]*//' | tr -d '"' | tr -d "'" | cut -c1-60)
          printf "  %s✓%s %s\n" "$GREEN" "$RESET" "$skill_name"
          [ -n "$desc" ] && printf "    %s%s%s\n" "$DIM" "$desc" "$RESET"
        fi
      done
    fi
  done

  printf "\n"
}

# ─────────────────────────────────────────────────────────────────────────────
# Main installation logic
# ─────────────────────────────────────────────────────────────────────────────

main() {
  # Parse arguments
  SOURCE=""
  GLOBAL=0
  YES=0
  LIST_ONLY=0
  INSTALLED_ONLY=0
  SELECTED_SKILLS=""
  SELECTED_AGENTS=""

  while [ $# -gt 0 ]; do
    case "$1" in
      -g|--global)
        GLOBAL=1
        shift
        ;;
      -y|--yes)
        YES=1
        shift
        ;;
      -l|--list)
        LIST_ONLY=1
        shift
        ;;
      -i|--installed)
        INSTALLED_ONLY=1
        shift
        ;;
      -s|--skill)
        shift
        SELECTED_SKILLS="$SELECTED_SKILLS $1"
        shift
        ;;
      -a|--agent)
        shift
        SELECTED_AGENTS="$SELECTED_AGENTS $1"
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      -*)
        error "Unknown option: $1"
        usage
        exit 1
        ;;
      *)
        SOURCE="$1"
        shift
        ;;
    esac
  done

  # Handle --installed flag (no source required)
  if [ "$INSTALLED_ONLY" = "1" ]; then
    list_installed
    exit 0
  fi

  if [ -z "$SOURCE" ]; then
    error "No source specified"
    usage
    exit 1
  fi

  header

  # Parse source
  parse_source "$SOURCE"
  info "Source: $CYAN$REPO_URL$RESET"
  [ -n "$REPO_SUBPATH" ] && info "Path: $CYAN$REPO_SUBPATH$RESET"
  step

  # Clone repository
  TEMP_DIR=$(mktemp -d)
  trap "rm -rf '$TEMP_DIR'" EXIT

  info "Cloning repository..."
  if ! git clone --depth 1 --quiet "$REPO_URL" "$TEMP_DIR" 2>/dev/null; then
    error "Failed to clone repository"
    exit 1
  fi
  success "Repository cloned"
  step

  # Discover skills
  info "Discovering skills..."
  SKILLS=$(discover_skills "$TEMP_DIR")
  SKILL_COUNT=$(echo "$SKILLS" | grep -c '|' || echo "0")

  if [ "$SKILL_COUNT" -eq 0 ] || [ -z "$SKILLS" ]; then
    error "No skills found"
    printf "%s│%s  Skills require a SKILL.md with name and description\n" "$DIM" "$RESET"
    exit 1
  fi

  success "Found $GREEN$SKILL_COUNT$RESET skill(s)"
  step

  # List only mode
  if [ "$LIST_ONLY" = "1" ]; then
    printf "\n%sAvailable Skills%s\n\n" "$BOLD" "$RESET"
    echo "$SKILLS" | while IFS='|' read -r name desc path; do
      [ -z "$name" ] && continue
      printf "  %s%s%s\n" "$CYAN" "$name" "$RESET"
      printf "    %s%s%s\n" "$DIM" "$desc" "$RESET"
    done
    printf "\n%sUse --skill <name> to install specific skills%s\n\n" "$DIM" "$RESET"
    exit 0
  fi

  # Select skills
  if [ -n "$SELECTED_SKILLS" ]; then
    # Filter to selected skills
    INSTALL_SKILLS=""
    for skill in $SELECTED_SKILLS; do
      match=$(echo "$SKILLS" | grep "^$skill|" || true)
      if [ -n "$match" ]; then
        INSTALL_SKILLS="$INSTALL_SKILLS
$match"
      fi
    done
    INSTALL_SKILLS=$(echo "$INSTALL_SKILLS" | grep -v '^$')
  elif [ "$YES" = "1" ]; then
    INSTALL_SKILLS="$SKILLS"
  elif [ "$SKILL_COUNT" -eq 1 ]; then
    INSTALL_SKILLS="$SKILLS"
    skill_name=$(echo "$SKILLS" | head -1 | cut -d'|' -f1)
    info "Skill: $CYAN$skill_name$RESET"
  else
    printf "\n%sSelect skills to install%s\n\n" "$BOLD" "$RESET"
    selected=$(select_items "Select skills" "$SKILLS" 1)
    INSTALL_SKILLS=""
    for skill in $selected; do
      match=$(echo "$SKILLS" | grep "^$skill|" || true)
      [ -n "$match" ] && INSTALL_SKILLS="$INSTALL_SKILLS
$match"
    done
    INSTALL_SKILLS=$(echo "$INSTALL_SKILLS" | grep -v '^$')
  fi
  step

  # Detect/select agents
  if [ -n "$SELECTED_AGENTS" ]; then
    TARGET_AGENTS="$SELECTED_AGENTS"
  else
    DETECTED=$(detect_installed_agents)
    DETECTED_COUNT=$(echo "$DETECTED" | grep -c . || echo "0")

    if [ "$DETECTED_COUNT" -eq 0 ]; then
      warn "No agents detected"
      if [ "$YES" = "1" ]; then
        TARGET_AGENTS="claude-code cursor codex"
      else
        printf "\n%sSelect agents to install to%s\n\n" "$BOLD" "$RESET"
        all_agents=$(echo "$AGENTS" | while IFS= read -r line; do
          [ -z "$line" ] && continue
          name=$(get_agent_field "$line" 1)
          display=$(get_agent_field "$line" 2)
          echo "$name|$display"
        done)
        TARGET_AGENTS=$(select_items "Select agents" "$all_agents" 1)
      fi
    elif [ "$YES" = "1" ]; then
      TARGET_AGENTS="$DETECTED"
    else
      # Show detected agents and let user select which ones
      printf "\n%sSelect agents to install to%s\n\n" "$BOLD" "$RESET"
      detected_list=""
      for agent in $DETECTED; do
        display=$(get_display_name "$agent")
        detected_list="$detected_list$agent|$display
"
      done
      detected_list=$(echo "$detected_list" | grep -v '^$')
      TARGET_AGENTS=$(select_items "Select agents" "$detected_list" 1)
    fi
  fi
  step

  # Select scope
  if [ "$GLOBAL" = "0" ] && [ "$YES" = "0" ]; then
    printf "\n%sInstallation scope%s\n\n" "$BOLD" "$RESET"
    printf "  %s1)%s Project %s(current directory)%s\n" "$DIM" "$RESET" "$DIM" "$RESET"
    printf "  %s2)%s Global %s(home directory)%s\n" "$DIM" "$RESET" "$DIM" "$RESET"
    printf "\n%s?%s Select scope %s[1]%s: " "$CYAN" "$RESET" "$DIM" "$RESET"
    read -r scope_choice </dev/tty
    [ "$scope_choice" = "2" ] && GLOBAL=1
  fi
  step

  # Show summary
  printf "\n%sInstallation Summary%s\n\n" "$BOLD" "$RESET"
  echo "$INSTALL_SKILLS" | while IFS='|' read -r name desc path; do
    [ -z "$name" ] && continue
    printf "  %s%s%s\n" "$CYAN" "$name" "$RESET"
    for agent in $TARGET_AGENTS; do
      install_path=$(get_install_path "$agent" "$name" "$GLOBAL")
      display=$(get_display_name "$agent")
      printf "    %s→%s %s: %s%s%s\n" "$DIM" "$RESET" "$display" "$DIM" "$install_path" "$RESET"
    done
  done
  step

  # Confirm
  if [ "$YES" = "0" ]; then
    if ! confirm "Proceed with installation?"; then
      printf "\n%sInstallation cancelled%s\n\n" "$YELLOW" "$RESET"
      exit 0
    fi
  fi
  step

  # Install
  info "Installing skills..."

  SUCCESS_COUNT=0
  FAIL_COUNT=0

  echo "$INSTALL_SKILLS" | while IFS='|' read -r name desc skill_path; do
    [ -z "$name" ] && continue

    for agent in $TARGET_AGENTS; do
      install_path=$(get_install_path "$agent" "$name" "$GLOBAL")
      display=$(get_display_name "$agent")

      # Create directory and copy
      mkdir -p "$install_path"

      # Copy files (excluding README.md and metadata.json)
      if cp -r "$skill_path"/* "$install_path/" 2>/dev/null; then
        rm -f "$install_path/README.md" "$install_path/metadata.json" 2>/dev/null
        printf "  %s✓%s %s → %s\n" "$GREEN" "$RESET" "$name" "$display"
        printf "    %s%s%s\n" "$DIM" "$install_path" "$RESET"
      else
        printf "  %s✗%s %s → %s\n" "$RED" "$RESET" "$name" "$display"
      fi
    done
  done

  footer
}

usage() {
  printf "%sskill.sh%s - Install agent skills with zero dependencies\n\n" "$BOLD" "$RESET"
  printf "%sUsage:%s\n" "$BOLD" "$RESET"
  printf "  curl -sL skil.sh | sh -s -- <source> [options]\n"
  printf "  curl -sL skil.sh | sh -s -- --installed\n\n"
  printf "%sSource formats:%s\n" "$BOLD" "$RESET"
  printf "  owner/repo                    GitHub shorthand\n"
  printf "  owner/repo/path/to/skill      Direct path to skill\n"
  printf "  https://github.com/owner/repo Full GitHub URL\n\n"
  printf "%sOptions:%s\n" "$BOLD" "$RESET"
  printf "  -g, --global          Install globally (home directory)\n"
  printf "  -s, --skill <name>    Install specific skill(s)\n"
  printf "  -a, --agent <name>    Install to specific agent(s)\n"
  printf "  -l, --list            List available skills from repo\n"
  printf "  -i, --installed       List installed skills\n"
  printf "  -y, --yes             Skip confirmation prompts\n"
  printf "  -h, --help            Show this help\n\n"
  printf "%sExamples:%s\n" "$BOLD" "$RESET"
  printf "  curl -sL skil.sh | sh -s -- voxel51/fiftyone-skills\n"
  printf "  curl -sL skil.sh | sh -s -- voxel51/fiftyone-skills --skill fiftyone-develop-plugin\n"
  printf "  curl -sL skil.sh | sh -s -- owner/repo -g -a claude-code -y\n"
  printf "  curl -sL skil.sh | sh -s -- --installed\n\n"
  printf "%sSupported agents:%s\n" "$BOLD" "$RESET"
  printf "  claude-code, cursor, codex, opencode, amp, antigravity,\n"
  printf "  github-copilot, roo, kilo, goose\n\n"
}

main "$@"
