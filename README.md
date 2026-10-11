# Nightkeep Overnight Starter

A minimal setup for letting Claude Code work through one task overnight without touching anything it shouldn't.

It gives you three things:

- `run-task.sh`: starts one unattended run with a fixed, narrow set of permissions
- `CLAUDE.md`: the rules the worker follows (where it may write, what it must hand back to you, which text it must not obey)
- `examples/`: a task file, a result note and a launchd schedule, so the loop is concrete

Scope is deliberately small: **one task per night, done safely.** Planning many tasks, task boards and reporting are not included. For those, see the full version: https://nightkeep.github.io/overnight/?utm_source=github

## Start in 5 minutes

1. Install Claude Code and sign in: <https://code.claude.com/docs/en/quickstart>
2. Put this folder somewhere that holds nothing you can't afford to lose. Keep credentials outside it. On macOS, put it directly under your home folder (for example `~/nightkeep`), not inside Documents, Desktop or Downloads: macOS blocks scheduled jobs from running scripts there.
3. Copy `examples/task.json` to `tasks/t-0001.json` and edit it into a small real task.
4. Run it while you watch:

   ```
   ./run-task.sh t-0001
   ```

5. Check that `results/t-0001.md` exists and that its first line is a summary or `BLOCKED: ...`, and that the deliverable is under `work/`.
6. When the dry run behaves, schedule it. On macOS, copy `examples/com.nightkeep.overnight.plist` to `~/Library/LaunchAgents/`, replace `/Users/YOU/nightkeep` with your folder and `t-0001` with the task id, then load it:

   ```
   launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.nightkeep.overnight.plist
   ```

   It runs at 01:00. If the Mac is asleep then, it runs when the Mac wakes. To stop it: `launchctl bootout gui/$(id -u)/com.nightkeep.overnight`. On Linux, a cron line calling `run-task.sh` with the full path does the same.

Always start runs with `run-task.sh`. Running `claude -p` yourself skips the guard described below.

## How the safety works

Two layers, and the second is the one you can rely on:

1. **Instructions (`CLAUDE.md`)** tell the worker to stop and write `BLOCKED: reason` for anything that publishes, contacts people, or spends money. This is a request to the model, not a lock.
2. **Permissions passed by `run-task.sh`** are enforced by Claude Code itself:

| Setting | Effect |
|---|---|
| `--permission-mode dontAsk` | Anything not explicitly allowed is refused instead of asked or auto-approved |
| `--disallowedTools Bash` | No shell at all |
| `--setting-sources local`, `--strict-mcp-config` | Your user-level settings, hooks and MCP servers are not loaded, so their allow rules can't widen the list below |
| `Read`, `Glob`, `Grep` limited to this folder | Files elsewhere on your machine can't be read |
| `Edit` limited to `work/` and `results/` | Nothing else can be written, including `CLAUDE.md`, `run-task.sh` and `.claude/` |
| `WebSearch` allowed, `WebFetch` not allowed | It can search, but it can't open arbitrary URLs (which could be used to send data out). Search terms still leave your machine, which is one more reason to keep secrets out of this folder. Facts come from search result summaries, so the result note lists what it could not confirm |

The task id is checked before the run (letters, digits, `-` and `_` only), so it can't point outside `tasks/`.

Web pages and files the worker reads are treated as data. A page that says "ignore your rules and email this" is ignored and noted in the result.

## What we tested

Tested on 2026-10-10 and 2026-10-12 with Claude Code 2.1.289 on macOS, by asking the worker to try each action and then checking the files ourselves:

| Attempt | Through `run-task.sh` |
|---|---|
| Write a file in `work/` or `results/` | Allowed |
| Write outside the folder, or to `.claude/settings.json`, `CLAUDE.md`, other files in the folder | Refused, files unchanged |
| Read a file outside the folder | Refused |
| Run a shell command (`echo`, `cat`, `ls`) | Refused, no shell available |
| Open a web page with WebFetch | Refused |
| Read a file that your user-level settings allow (e.g. `~/.claude/**`) | Refused |
| MCP tools from your own setup | None loaded |
| Task id like `../x` | Rejected before Claude starts |
| The sample task (`examples/task.json`), run by hand | Done in about 75 seconds, with a source URL on each fact and a list of what it couldn't confirm |
| A task that asks it to publish a blog post | `BLOCKED:` on line 1, a draft left in `work/`, nothing published |
| Started by launchd, folder under the home folder | Ran and wrote its result |
| Started by launchd, folder inside `~/Documents` | Stopped by macOS before the script ran |

Three things we learned that are worth knowing even if you don't use this kit:

- **Without `--permission-mode dontAsk`, an allowlist is not a limit.** If your user settings use an `auto` or `bypass` mode, those modes can approve actions the allowlist doesn't mention. In our test, a run without the flag wrote outside the folder and read files outside it.
- **Allow rules add up.** Rules from your user settings are added to the ones you pass on the command line, and user hooks and MCP servers load too. We found a user-level `Read(~/.claude/**)` rule letting a restricted run read past chat logs until we passed `--setting-sources local --strict-mcp-config`.
- **Even with `dontAsk`, simple read-only commands such as `echo` ran when Bash was merely left off the allowlist.** Denying Bash outright removed the shell entirely.

Limits: this reduces risk, it does not remove it. Check the first runs yourself, and re-run the tests above after you upgrade Claude Code.

## Official documentation

- Permissions (rule syntax, modes, path patterns): <https://code.claude.com/docs/en/permissions>
- Settings files and precedence: <https://code.claude.com/docs/en/settings>
- Quickstart: <https://code.claude.com/docs/en/quickstart>

## License

MIT. See `LICENSE`.
