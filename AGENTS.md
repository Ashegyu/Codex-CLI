# Repository Guidelines

## Project Structure & Module Organization
This repository is an Electron desktop app. Core process logic lives in `main.js` (window lifecycle, PTY/CLI IPC), while `preload.js` exposes a safe API bridge for the renderer. UI markup is in `renderer/index.html`, and most client behavior is in `renderer/app.js` (chat flow, history, profile rendering, response parsing).  
Use `assets/` for static files and treat `dist/` as build output. Windows context-menu integration is maintained via `context-menu-install.reg` and `context-menu-uninstall.reg`.

## Build, Test, and Development Commands
- `npm install`: install dependencies.
- `npm run start`: run the app locally with Electron.
- `npm run build`: create a Windows package with `electron-builder`.
- `npm run build:portable`: create a portable Windows build.
- `powershell -File scripts/verify.ps1`: run repository verification flow referenced in README (when applicable).

There is no default `npm test` script today; include explicit manual verification notes in each PR.

## Coding Style & Naming Conventions
Follow the existing JavaScript style in this repo:
- 2-space indentation and semicolon-terminated statements.
- `camelCase` for functions and variables (for example, `renderProfiles`, `sendMessage`).
- Keep renderer logic in `renderer/` and process/system logic in `main.js`/`preload.js`.
- Prefer small, single-purpose functions over large multi-responsibility blocks.

## Testing Guidelines
Validate behavior through local app execution (`npm run start`) and exercise impacted UI flows. For packaging changes, run `npm run build` or `npm run build:portable` and verify outputs under `dist/`. When using verification scripts, record command and result in the PR.

## Commit & Pull Request Guidelines
Use conventional commit prefixes seen in project history: `feat:`, `fix:`, `refactor:`, `chore:`, `design:`. Keep each commit focused on one logical change.

PRs should include:
- concise problem/solution summary,
- touched paths/modules,
- verification steps and results,
- linked issue/task,
- screenshots or short recordings for UI changes.

## Security & Configuration Tips
Do not commit secrets, local tokens, or machine-specific paths. Review `.claude/settings.local.json` changes carefully before merging, since it controls local command permissions.
