---
name: pk-tmux
triggers:
  - tmux
  - run in background
  - start server
  - run dev server
  - background task
  - persistent session
  - terminal session
---

# pk-tmux - Session Management Skill

Use this skill when the user wants to run commands in tmux sessions, manage background tasks, or work with persistent terminal sessions.

## Overview

This skill manages tmux sessions tied to the current project. It uses Unix sockets in `/tmp/` for session management and organizes tasks into dedicated windows.

## Quick Status Check

**Always run this first** to get current state in one command:
```bash
~/.claude/skills/pk-tmux/tmux-status.sh [project-name] [project-cwd]
# Or with defaults (uses current dir):
~/.claude/skills/pk-tmux/tmux-status.sh
```

Output includes:
- Session name, socket path, attach command
- All windows with their CWD and running process
- Whether each window is busy `[RUNNING]` or idle (at shell)
- Quick command templates for common operations

## Session Naming Convention

- **Socket path**: `/tmp/claude-<project>.sock` (add hash/number suffix if collision)
- **Session name**: Same as project name (basename of CWD)
- Example: Project at `/home/user/myproject` → socket `/tmp/claude-myproject.sock`, session `myproject`
- If socket exists for different path, use `/tmp/claude-myproject-<hash>.sock`

## Core Commands

### Check if session exists
```bash
tmux -S /tmp/claude-<project>.sock has-session -t <project> 2>/dev/null && echo "exists" || echo "not found"
```

### Create new session (detached, in project CWD)
```bash
tmux -S /tmp/claude-<project>.sock new-session -d -s <project> -c <project-cwd>
```

### List windows in session
```bash
tmux -S /tmp/claude-<project>.sock list-windows -t <project> -F "#{window_index}: #{window_name}"
```

### Create new window with name
```bash
tmux -S /tmp/claude-<project>.sock new-window -t <project> -n <window-name> -c <project-cwd>
```

### Send command to specific window
```bash
tmux -S /tmp/claude-<project>.sock send-keys -t <project>:<window-name> '<command>' Enter
```

### Check what's running in a window/pane (get current command)
```bash
tmux -S /tmp/claude-<project>.sock list-panes -t <project>:<window> -F "#{pane_current_command}"
```

### Check if command is still running (pane is busy)
```bash
# If pane_current_command is NOT "bash"/"zsh"/shell, something is running
tmux -S /tmp/claude-<project>.sock display-message -t <project>:<window> -p "#{pane_current_command}"
```

### Capture pane output (last N lines)
```bash
# Start small (20 lines), increase only if needed
tmux -S /tmp/claude-<project>.sock capture-pane -t <project>:<window> -p -S -20

# Filter output to reduce noise (e.g., only errors)
tmux -S /tmp/claude-<project>.sock capture-pane -t <project>:<window> -p -S -100 | grep -i "error\|fail\|warn"

# Get last N lines with tail
tmux -S /tmp/claude-<project>.sock capture-pane -t <project>:<window> -p -S -500 | tail -20
```

### Kill a window
```bash
tmux -S /tmp/claude-<project>.sock kill-window -t <project>:<window-name>
```

### Kill entire session
```bash
tmux -S /tmp/claude-<project>.sock kill-session -t <project>
```

## Workflow

### 1. Initialize Session
Before running any command, always:
1. Determine project name from CWD basename
2. Check if session exists
3. If not, create it
4. Report connection info to user

### 2. Running Tasks

**For foreground/monitored tasks:**
1. Create a dedicated window with descriptive name (e.g., `build`, `test`, `server`)
2. Send the command to that window
3. Poll `pane_current_command` to detect when command finishes
4. Capture output to report results

**For background tasks:**
1. Create window and send command
2. Immediately report that task is running in background
3. Tell user how to check on it later

### 3. Polling for Completion
```bash
# Loop until shell prompt returns (command finished)
while true; do
  cmd=$(tmux -S /tmp/claude-<project>.sock display-message -t <project>:<window> -p "#{pane_current_command}")
  if [[ "$cmd" == "bash" || "$cmd" == "zsh" || "$cmd" == "fish" || "$cmd" == "sh" ]]; then
    echo "Command finished"
    break
  fi
  sleep 1
done
```

## User Communication

**ALWAYS tell the user how to connect:**
```
To connect to this session:
  tmux -S /tmp/claude-<project>.sock attach -t <project>

To attach to specific window:
  tmux -S /tmp/claude-<project>.sock attach -t <project>:<window-name>
```

## Questions to Ask if Unclear

- "Should I run this in the background, or wait for it to complete?"
- "What should I name this window? (e.g., 'build', 'server', 'test')"
- "Should I create a new window or reuse an existing one?"
- "Do you want me to capture and show the output when done?"

## Best Practices

1. **Unique window names**: Use descriptive names like `dev-server`, `npm-build`, `pytest`
2. **Minimal output capture**: Start with 20-30 lines max. Only increase if user needs more. Use `grep`, `tail`, `head` to filter noise and avoid polluting context with verbose logs
3. **Filter smartly**: For build/test output, grep for `error|fail|warn|PASS|FAIL`. For servers, grep for startup confirmation or errors
4. **Clean up**: Offer to kill windows/sessions when tasks are done
5. **Status reporting**: Tell user what's running where
6. **Error handling**: Check exit codes when possible via `echo $?` after command completes

## Example Session

```bash
# Project: myapp (CWD: /home/user/myapp)
SOCKET="/tmp/claude-myapp.sock"
SESSION="myapp"

# Initialize
tmux -S $SOCKET has-session -t $SESSION 2>/dev/null || \
  tmux -S $SOCKET new-session -d -s $SESSION -c /home/user/myapp

# Run dev server in background
tmux -S $SOCKET new-window -t $SESSION -n server -c /home/user/myapp
tmux -S $SOCKET send-keys -t $SESSION:server 'npm run dev' Enter

# Run tests and wait for completion
tmux -S $SOCKET new-window -t $SESSION -n tests -c /home/user/myapp
tmux -S $SOCKET send-keys -t $SESSION:tests 'npm test' Enter
# ... poll until done, then capture output
```
