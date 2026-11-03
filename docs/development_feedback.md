# In-game development feedback

Approved by Chase November 2, 2026. Available in debug/editor runs through the
existing DebugUI singleton. Start/restart the game after installing this change.

November 3 repair: Chase reports broken typing and shaking while recording.
The controls manager had serialized built-in editing shortcuts without modifiers
(for example Ctrl+A became bare A). The loader now restores engine/project UI
keyboard defaults, skips old UI keyboard entries, and saves gameplay keyboard
bindings without resaving engine shortcuts. Gameplay remaps remain intact. This
also restores paste/newline/backspace behavior; no control reset is required.
The form stays embedded and defers its initial description focus until shown.

## Capture while playing

- **Ctrl+F1** or the bottom-right **Feedback** button takes a screenshot and
  opens the feedback window. The screenshot is taken before that window appears.
- **Ctrl+F2** or **Record clip** starts a short game-viewport recording. Press
  it again to stop and open feedback. Ctrl+F1 also finishes an active recording.
  Recording stops automatically at 20 seconds or about 32 MiB of JPEG data.
- Write what happened or what you want changed. Title, expected result and
  reproduction steps are optional. Choose kind, area, impact and frequency.
  Positive feedback and questions are supported alongside bugs/suggestions.
- **Save & copy handoff** (also Ctrl+Enter) marks the report ready and copies a
  message with its exact folder. Return to Codex and say **review my latest
  feedback**, or paste the handoff. No attachment-by-attachment work is needed
  when Codex can access this checkout.
- Escape/window-close keeps a draft. Notes autosave after 0.5 seconds of idle
  typing. Closing restores the prior pause state, mouse mode and menu focus.
  Failed saves stay visible so you can retry or copy your notes.

## Where it goes

Editor runs save to **`LocalOnly/Feedback/`** in the project. Debug exports,
or an unwritable checkout, use **`user://feedback/`**. **Open report folder**
shows the actual destination. On Windows the normal fallback is
`%APPDATA%/Godot/app_userdata/Threadbound/feedback/`.

Each `reports/<UTC-time-and-unique-id>/` contains:

- `report.md`: readable feedback, capture links and handoff context.
- `report.json`: feedback plus structured diagnostics and captured game state.
- `screenshot.png`: game viewport at the feedback request, when rendering exists.
- For a clip, `recording.avi` and `frame_*.jpg`: a silent MJPEG recording and
  individually inspectable frames. Frame timestamps and encoding issues are in
  the JSON. An interrupted recording can retain JPEGs before an AVI is finalized.

`latest.txt` points to the last report successfully saved as ready. Drafts stay
in their report folders; they do not replace that pointer. To resume an old
draft, read/copy its saved fields from `report.json`; the current UI opens a new
report per capture rather than editing an earlier report.

The tool creates `.gitignore` and `.gdignore` inside the inbox so captures stay
out of Git and Godot imports independently of the root ignore rules. There is
no upload, GitHub issue creation, automatic chat message or background AI run.
Local reports are not backed up by pushing source code. Their capture can show
unpublished art; keep them local unless intentionally sharing them.

## Context attached automatically

- UTC/session/report identifiers, game and engine versions, source revision,
  branch and bounded working-tree status. Git is inspected at session startup;
  exported builds identify the source revision as unavailable.
- Scene path/name, player location/velocity/facing, floor/wall/water state,
  animation/action flags, health, AP, momentum, Flow State and debug cheats.
- Equipment/pattern references, checkpoint/recovery position, tutorial/demo
  flags and collected identity threads. No save file is changed or copied.
- Camera position/zoom, house occupancy/door-transition state and nearby enemies
  (up to 12 within 1,200 world units).
- FPS, time scale, physics rate, memory, GPU/renderer, display/difficulty settings
  and current input bindings. FPS is the engine's current estimate, not a profile.
- Up to 30 seconds of state sampled every 0.5 seconds; up to 120 recent bound
  gameplay button/action events; 300 recent log entries and lifetime warning/error
  counts. Unbound typed keys and feedback text are excluded from input history.
  Analog stick movement is represented by sampled held actions/player velocity,
  rather than logging every axis event.
- Runtime warnings/errors with source locations and available script backtraces.
  Godot's [Logger API](https://docs.godotengine.org/en/stable/classes/class_logger.html)
  supplies these; engine initialization before the logger is installed is outside
  its coverage. Messages and backtraces have bounded lengths.

The snapshot is read-only and taken before feedback pauses the game. These
records help diagnose/reproduce an issue; they are not a deterministic replay
or proof of its cause. Scene-specific fields that do not exist are omitted.

## Crashes and recording limits

Each session writes `sessions/<id>/session.json` every two seconds, keeping recent
state/input/logs on disk. A clean shutdown marks that file closed. On the next
launch, reports list prior unclosed sessions whose process is no longer running.
Editor Stop, a force quit and a crash can all produce an unclosed session; the
tool does not label this evidence a confirmed crash. Inspect the retained session
and the engine-log directory recorded there. Up to the last two seconds can be
missing, and a native crash/freeze cannot open a form or guarantee a final write.
An autosaved report draft can retain feedback written before such an exit.

Recording is opt-in, approximately **10 fps**, at most **960 pixels wide**, with
no audio, microphone or desktop capture. GPU readback/JPEG compression and disk
writes add overhead; recording can affect the performance being reported.
Forward+/Mobile recording now requests asynchronous GPU readback instead of
waiting for each frame on the game thread. Compatibility rendering uses synchronous
readback. JPEG scaling/compression and frame writes run on a worker with at most
two queued images; overloaded captures skip frames rather than building an
unbounded backlog. Clip metadata identifies the readback path, encoding worker
and skipped frames. Stopping drains the pending readback/worker before packaging
the clip, with a two-second readback timeout that preserves earlier frames. Gaps
repeat the preceding frame in the AVI to preserve elapsed time. Original JPEGs
and timestamps remain available. Screenshot quality retains the viewport's
resolution. There is no always-on retrospective video buffer.

For performance isolation or an emergency workaround, launch with the user
argument `--no-debug-feedback`. To choose an inbox, use
`--feedback-inbox=<absolute-path>` after Godot's `--` argument separator.
Completed reports and old sessions remain until you choose to archive/delete
them; the tool bounds active buffers, not total lifetime inbox storage.

## Handling feedback in a future Codex chat

1. Read `LocalOnly/Feedback/latest.txt`, then that report's `report.md` and
   `report.json`. If asked about unsaved feedback or a crash, also inspect drafts
   and the referenced session. Use an explicitly supplied alternate path first.
2. Inspect the screenshot and relevant recording frames. Compare the capture's
   source/dirty state with the current checkout before reproducing it.
3. Separate Chase's observation, the diagnosis and any proposed change. Follow
   AGENTS.md approval requirements; a captured suggestion does not authorize
   combat/equipment/scene/asset changes by itself.
4. Keep this work list as the priority source. Record accepted follow-up there;
   append resolution/commit/validation evidence to the local report as useful.
   Do not treat a report as fixed simply because it was saved.

## Verification

`tools/debug_feedback/verify_debug_feedback.gd` exercises the shortcut, pre-pause
snapshot, logger bounds, drafts, ready reports/handoff, pause restoration,
write failures, recovery sessions and AVI structure. Use an isolated inbox:

```powershell
& $godot --headless --path . --log-file "$PWD/tmp/feedback-check.log" `
  --script tools/debug_feedback/verify_debug_feedback.gd -- `
  --feedback-inbox=res://tmp/feedback-verification
```

Omit `--headless` to additionally verify real screenshots and live recording.
The script deliberately emits one warning/error to check diagnostic capture;
those messages are expected. Independently decode resulting AVI files, for example
with `ffmpeg -v error -i recording.avi -f null -`.

November 2 validation: 38 headless and 43 rendered integration checks pass;
actual Forward+ Lakeside screenshot/moving-clip capture, visual form review and
independent FFmpeg AVI decoding pass. Local evidence is under `tmp/feedback-*`.
The sandbox cannot create the normal shader cache; compatibility-renderer checks
also emit existing unsupported-AA warnings. The Lakeside harness reports existing
`is_editable_instance` scene-entry diagnostics, and engine teardown reports resource
warnings. These also reproduce with `--no-debug-feedback`; they are retained in
diagnostics, not claimed fixed by this task.
User acceptance of the workflow remains open.

November 3 repair verification: 47 headless, 55 Forward+ and 54 Compatibility
checks pass, now
including actual key events in every text field, newline/backspace, focus across
autosave, recovery from corrupted UI shortcuts, preserved gameplay remaps and
the asynchronous recording path. Windows Computer Use verifies real paste plus
plain-A insertion. A two-second Chamber capture retains 18 frames; a stationary
platform registers at (0, 0) shift across the JPEGs. In that short local run,
95th-percentile frame interval is 4.89 ms during recording versus 4.49 ms before
recording; this is not a general performance budget. FFmpeg independently decodes
the resulting AVI. Evidence is local under `tmp/feedback-fix-*`,
`tmp/feedback-input-probe.json` and `tmp/feedback-stability-results.json`.
Chase's retest of normal feedback/recording remains open.
