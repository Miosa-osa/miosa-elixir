# Changelog

## [1.1.0] - 2026-05-26

### Added
- `Miosa.Sandbox.Files` — `tree/3`, `write_many/3`, `watch/3` (SSE stream)
- `Miosa.Sandbox.Share` — `create/3`, `list/2`, `revoke/3`
- `Miosa.Sandbox.Env` — `set/3`, `delete/3` (extends existing `list/2`)
- `Miosa.Sandbox.Processes` — `get/3`, `stop/3`, `logs/4`, aliased `kill/3`
- `Miosa.Sandboxes.fork/3` — fork a sandbox from a snapshot or live sandbox
- `Miosa.Sandboxes.preview_token/3` — mint short-lived preview tokens
- `Miosa.Templates` — `list/1` sandbox template catalog
- `Miosa.Quotas` — `get/2`, `set/3`, `delete/2` per-external_user_id quota overrides
- `Miosa.Usage.get/2` — grouped usage rollup by external_user_id / project / workspace
- `Miosa.Events.stream/2` — tenant-wide SSE event stream with type filtering

## [1.0.0] - 2026-05-22

### Added
- Full MIOSA platform API coverage
- Computer lifecycle (create, start, stop, restart, destroy)
- Desktop control (screenshot, click, type, key, hotkey, scroll, drag, windows)
- File operations (upload, download, write, list, export)
- Sandbox management (create, exec, snapshot, deploy)
- Deployment management (create, publish, rollback, versions, releases)
- Database management (create, credentials, logs)
- Storage (buckets, objects, presign)
- Functions, webhooks, cron jobs, volumes, API keys
- Workspaces and workspace sub-resources
- CUA (Computer-Use Agent) sessions
- Sandbox background process control
- Sandbox file watch SSE stream
- OpenComputers BYOC support
- Admin API access
- Streaming completions (chat + text)
- WebSocket-based exec spawn (PTY)
