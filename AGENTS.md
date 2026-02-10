# Agent Instructions

This project uses **bd (beads)** for issue tracking. Run `bd prime` for workflow context, or install hooks (`bd hooks install`) for auto-injection.

## Quick Reference

### Issue Tracking (beads)
```bash
bd ready              # Find unblocked work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
bd create "Title" --type task --priority 2  # Create issue
```

### Code Formatting (SwiftFormat)
```bash
make format           # Format all Swift files
make lint             # Check formatting without modifying
swiftformat --lint Sources/MouseJiggler/SomeFile.swift  # Check single file
```

**Pre-commit hook is installed** - Swift files are auto-formatted on every commit.

## Mouse Jiggler Project Phases

| Issue | Phase | Status |
|-------|-------|--------|
| N/A | Phase 1: Project Setup + Basic UI | ✅ COMPLETED |
| mouse-jiggler-pp0 | Phase 2: Fine-tune Idle Detection | open |
| mouse-jiggler-ivg | Phase 3: Test & Refine Mouse Movement | open |
| mouse-jiggler-kib | Phase 4: Add Settings & Menu Bar Mode | open |
| mouse-jiggler-k79 | Phase 5: Polish & Distribution | open |

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds

