# CLAUDE.md

**AI Assistant Guide for supreme-succotash**

This document provides comprehensive guidance for AI assistants working with this codebase. It covers project structure, development workflows, coding conventions, and key considerations for effective collaboration.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Repository Structure](#repository-structure)
3. [Development Workflows](#development-workflows)
4. [Coding Conventions](#coding-conventions)
5. [Testing Strategy](#testing-strategy)
6. [Build & Deployment](#build--deployment)
7. [AI Assistant Guidelines](#ai-assistant-guidelines)
8. [Common Pitfalls](#common-pitfalls)
9. [Resources & References](#resources--references)

---

## Project Overview

### Purpose
Lift48 is a StrongLifts-style strength tracker for iPhone and Apple Watch, built around
**4 sets × 8 reps** and a **body-part split** (Chest, Back, Shoulders, Legs, Arms; 3 exercises each).
Product rules live in `docs/SPEC.md`; the UI-facing API is in `docs/APP_MODEL_API.md`.

### Technology Stack
- **Languages:** Swift (SWIFT_VERSION 5 mode in Xcode; LiftCore builds with Swift 6.1)
- **Frameworks:** SwiftUI, Observation, Swift Charts, WatchConnectivity, HealthKit, UserNotifications
- **Targets:** iOS 17+, watchOS 10+
- **Tools:** XcodeGen (`project.yml`), Swift Package Manager. No third-party dependencies.

### Key Features
Tap-to-log sets, auto progression with 3-strike 10% deload, auto rest timer (90/180/300 s),
warm-ups, plate calculator, history, progress charts, CSV export, program editor,
Apple Watch app with phone⇄watch sync, Apple Health.

---

## Repository Structure

```
supreme-succotash/
├── project.yml              # XcodeGen spec (iOS app embeds the watchOS app)
├── Packages/LiftCore/       # Pure Swift logic + XCTest suite (Foundation only, Linux-safe)
├── App/Shared/              # AppModel, WatchSyncCoordinator, HealthKit, notifications, haptics
├── App/iOS/                 # iPhone SwiftUI app (Views/Workout, History, Progress, Settings)
├── App/Watch/               # watchOS SwiftUI app
└── docs/                    # SPEC.md, APP_MODEL_API.md
```

### Key rules
- All non-trivial logic belongs in `LiftCore` and must be unit-tested. It must not import Apple-only frameworks.
- Views mutate state only through `AppModel` intents.
- The iPhone is authoritative for program, settings and history. Live sessions merge per field (see SPEC §2.1).
- The rest timer is an absolute `endsAt` date. Never keep a separate countdown.

---

## Development Workflows

### Git Workflow

**Branch Naming Convention:**
- Feature branches: `feature/description`
- Bug fixes: `fix/description`
- AI-generated branches: `claude/claude-md-mk2xq84fd0d1g70k-H6sZH` (auto-generated)

**Commit Messages:**
- Use clear, descriptive commit messages
- Format: `[type]: brief description`
- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`
- Example: `feat: add user authentication module`

**Pull Request Process:**
1. Create feature branch from main
2. Make changes and commit with clear messages
3. Push to remote branch
4. Create PR with detailed description
5. Address review feedback
6. Merge when approved

### Setting Up Development Environment

*[To be filled in with setup instructions]*

```bash
# Example setup commands
git clone <repository-url>
cd supreme-succotash
# Additional setup steps to be added
```

### Running the Project

*[To be filled in with run instructions]*

```bash
# Example commands
# npm start
# python main.py
# cargo run
```

---

## Coding Conventions

### General Principles

1. **Keep It Simple**: Avoid over-engineering; implement only what's needed
2. **Readability First**: Write code for humans, optimize later
3. **DRY (Don't Repeat Yourself)**: But only abstract when pattern is clear
4. **YAGNI (You Aren't Gonna Need It)**: Don't add features speculatively
5. **Consistent Style**: Follow established patterns in the codebase

### Code Style

*[To be filled in based on chosen language and style guide]*

**General Guidelines:**
- Use meaningful variable and function names
- Keep functions small and focused (single responsibility)
- Comment only when code intent isn't clear
- Avoid deep nesting (max 3-4 levels)
- Handle errors appropriately for the context

### Naming Conventions

*[To be filled in based on language choice]*

**Examples:**
- Variables: `camelCase` or `snake_case`
- Functions: `camelCase` or `snake_case`
- Classes: `PascalCase`
- Constants: `UPPER_SNAKE_CASE`
- Files: `kebab-case` or `snake_case`

### File Organization

*[To be filled in as patterns emerge]*

- One class/module per file (generally)
- Group related functionality
- Keep file size manageable (<500 lines typically)

---

## Testing Strategy

### Testing Approach

*[To be filled in as testing strategy is established]*

**Levels:**
- Unit Tests: Test individual functions/methods
- Integration Tests: Test component interactions
- E2E Tests: Test complete user workflows

### Running Tests

```bash
cd Packages/LiftCore && swift test
# Without a local toolchain (e.g. Linux sandbox):
docker run --rm -v "$PWD/Packages/LiftCore:/pkg" -w /pkg swift:6.1 swift test
```
App targets need Xcode on a Mac: `xcodegen generate && open Lift48.xcodeproj`.

### Test Coverage

*[To be filled in with coverage targets]*

- Target: TBD% code coverage
- Critical paths must be tested
- All bug fixes should include regression tests

---

## Build & Deployment

### Build Process

*[To be filled in with build instructions]*

```bash
# Example build commands
# npm run build
# python setup.py build
# cargo build --release
```

### Deployment

*[To be filled in with deployment process]*

**Environments:**
- Development: TBD
- Staging: TBD
- Production: TBD

---

## AI Assistant Guidelines

### Core Principles for AI Assistants

1. **Read Before Writing**: Always read existing files before modifying them
2. **Understand Context**: Use Explore agent for codebase exploration
3. **Minimal Changes**: Make only necessary changes; avoid refactoring unless asked
4. **Security First**: Watch for vulnerabilities (XSS, injection, etc.)
5. **Test Changes**: Verify changes work before committing
6. **Clear Communication**: Explain what you're doing and why

### Recommended Workflow

1. **Analyze Request**: Understand what's being asked
2. **Explore Codebase**: Use Task tool with Explore agent for discovery
3. **Plan Approach**: Use TodoWrite for multi-step tasks
4. **Read Relevant Files**: Use Read tool before editing
5. **Make Changes**: Use Edit tool for modifications
6. **Verify**: Test that changes work
7. **Commit**: Create clear, descriptive commits
8. **Document**: Update this file if patterns change

### Tool Usage Priorities

**For File Operations:**
- Use `Read` instead of `cat`
- Use `Edit` instead of `sed/awk`
- Use `Write` for new files (only when necessary)
- Use `Glob` for finding files by pattern
- Use `Grep` for searching code

**For Exploration:**
- Use `Task` tool with `subagent_type=Explore` for codebase discovery
- Use `Glob` for specific file patterns
- Use `Grep` for specific code searches

**For Complex Tasks:**
- Use `TodoWrite` to track progress
- Use `Task` tool with appropriate agent for multi-step work
- Break down large tasks into smaller steps

### Code Modification Guidelines

**When Adding Features:**
1. Find similar existing features first
2. Follow established patterns
3. Keep changes minimal and focused
4. Don't add extra functionality not requested

**When Fixing Bugs:**
1. Understand root cause before fixing
2. Fix only what's broken
3. Don't refactor surrounding code
4. Add tests to prevent regression

**When Refactoring:**
1. Only refactor if explicitly requested
2. Maintain existing behavior
3. Update tests if needed
4. Don't mix refactoring with feature additions

### Security Considerations

Always check for these common vulnerabilities:

- **Injection**: SQL, command, code injection
- **XSS**: Cross-site scripting
- **Authentication**: Weak or broken auth
- **Authorization**: Missing access controls
- **Sensitive Data**: Exposed secrets, credentials
- **Dependencies**: Vulnerable packages
- **Input Validation**: Unvalidated user input

### Error Handling Best Practices

*[To be filled in based on chosen language/framework]*

- Validate input at system boundaries
- Don't catch errors you can't handle
- Provide meaningful error messages
- Log errors appropriately
- Fail fast for programming errors

---

## Common Pitfalls

### What to Avoid

1. **Over-Engineering**: Don't add abstractions until patterns are clear
2. **Premature Optimization**: Make it work first, optimize later
3. **Breaking Changes**: Avoid backwards-incompatible changes without discussion
4. **Security Shortcuts**: Never compromise security for convenience
5. **Undocumented Assumptions**: Make assumptions explicit
6. **Copy-Paste Code**: Understand code before copying
7. **Ignoring Errors**: Handle or propagate errors appropriately
8. **Magic Numbers**: Use named constants
9. **God Objects**: Keep classes/modules focused
10. **Tight Coupling**: Maintain loose coupling between components

### Red Flags to Watch For

- Functions longer than ~50 lines
- Classes with too many responsibilities
- Deep nesting (>3-4 levels)
- Commented-out code (should be deleted)
- Hardcoded credentials or secrets
- Missing error handling at boundaries
- Inconsistent naming conventions
- Duplicate code across files

---

## Resources & References

### Documentation

*[To be filled in with relevant documentation links]*

- Project README: TBD
- API Documentation: TBD
- Architecture Docs: TBD

### External Resources

*[To be filled in with helpful external links]*

- Language Documentation: TBD
- Framework Documentation: TBD
- Style Guides: TBD

### Getting Help

*[To be filled in with support channels]*

- Issues: GitHub Issues
- Discussions: GitHub Discussions
- Contact: TBD

---

## Maintenance Notes

**Last Updated**: 2026-01-06

**Update Frequency**: This document should be updated when:
- Project structure significantly changes
- New patterns or conventions are established
- Development workflow changes
- New technologies are added
- Common issues are discovered

**Maintainers**: AI assistants should keep this document current and accurate as they work with the codebase.

---

## Version History

| Date | Changes | Updated By |
|------|---------|------------|
| 2026-01-06 | Initial creation - comprehensive template | Claude AI |
| 2026-10-04 | Filled in Lift48 overview, structure and test commands | Claude AI |

---

*This is a living document. Keep it updated as the project evolves.*
