# NOX sound audition — October 28, 2026

Chase requested a playable, sortable list of potential environmental sound uses,
including current-game comparisons, before choosing replacements. Delivered as
a local audition browser: **http://127.0.0.1:8876/**.

Start/reopen with `tools/audio/start_nox_audition.ps1`. The tool starts a hidden
Python server bound only to `127.0.0.1`; it opens the page in the default browser.
The Codex browser tab is also retained for this review. Nothing is hosted online.
Use `-NoBrowser` to start without opening a second tab. The original archive at
`C:\Users\chase\Documents\Threadbound Asset Library\archives\Essentials_Series_NOX_SOUND.zip`
must remain available. The catalog/tools are backed up in Git; that archive is
still a separate local-library backup responsibility.

## What to listen through

**60 starter candidates**, all **1,644 NOX WAVs** under All NOX sounds, and
**27 existing project SFX sources** under Current game sounds. The starter list
includes several variants where comparison helps, with cars/trucks, electronics
and human efforts outside the initial environmental selection.

| Filter / search | Possible Threadbound use | Initial candidates |
| --- | --- | --- |
| Wood, Footsteps | Dock planks, porch decks, wooden house floors | `Footsteps_Wood_Walk_01/02`, `Footsteps_Wood_Run_01/02` |
| Rock, Footsteps / Landings | Cave stone, tower approach and harder ground contact | `Footsteps_Rock_Walk_01/02`, `Footsteps_Rock_Jump_Land_01` |
| Water / Water splashes | Shallow wading and splash layers | Water walk/run variants and light/big jump splashes; these are shallow-water recordings, not proven full-body swim entries |
| Grass, Gravel, Mud, Leaves | Village-edge surfaces and ground texture | One initial walk/run/landing option per selected surface; expand All NOX for more variations |
| Village & nature / foliage | Brush through tall grass, sparse outdoor life | Tall-grass movement, forest birds, cicadas, night and meadow recordings |
| Doors & objects | House door opening, key/latch handling | `Household_Door_Wood_Open_Stereo.wav`, `Household_Closet_Key_Insertion_Stereo.wav` |
| Cloth & handling | Clothing rustle, handled fabric, subtle grapple/gear layer | Coat pickup/throw and backpack pickup/drop; not ready-made cloth-tear impacts |
| Water ambience | Stream/inlet beds, moving water near outlets | Calm stream, river and waterfall; selected Iceland light stream and distant surf for contrast |
| Cave ambience | Cave/tower-interior atmosphere | Cave Dark, Deep and Drips loops |
| Hearth & fire / Weather & wind | Village hearths and approved outdoor weather | Small/medium fire, calm rain and wind, stronger alternatives for comparison |

The source names and project's existing audio registry provide these use labels.
**This is a shortlist by plausible function, not an assertion that the clips
have been heard and accepted.** Surf may feel too large for the lake, outdoor
recordings may not fit underwater, and human voices may not fit woven creatures.
No thread-snap, sword-hit or creature identity is approved through this catalog.

## Use the page

1. Start with the shortlist. Search an action/surface/filename or choose a category.
2. Play any row. Sort by friendly name, original filename, duration or category.
   Pagination keeps the full pack manageable.
3. Use Play current source where a matching registry event exists. Footsteps and
   landings compare against the current generic three-variant sets; cloth source
   candidates expose the current grapple/damage sources as optional references.
   Ambience/doors with no matched registry event are marked as addition candidates.
4. Mark Favorite, Maybe or Pass; leave notes such as “porch only” or “too much surf.”
5. Choose Favorites or Reviewed sounds to revisit choices, then **Export my picks**
   to save `threadbound-sound-picks.json` for sharing/backing up the decisions.

Picks persist in this browser on this localhost origin; changing browser or port
uses a different storage area. Export before clearing browser data. The server
does not save user review choices or overwrite repository files. Browser notes
and favorites are not automatically committed.

The player preserves full clip length, sample rate, channels and recording level.
It converts WAV samples to PCM16 in memory for consistent browser playback, with
no normalization, resampling or edits to the original archive. The master volume
starts at 45%. Existing project files are heard as raw sources; runtime pitch,
randomization, volume offsets and bus processing are not reproduced. A/B source
audition is therefore a texture/character comparison, not a final in-game mix.

## Implementation and verification

Task-owned metadata lives in `work/nox-sound-audition-2026-10-28/`, protected from
Godot imports by `.gdignore`. Audio is read on demand from the external archive or
the exact existing SFX paths in the catalog. There is no bulk WAV extraction or
new audio added to the production game. Original files remain unchanged.

Each catalog entry records its original member/path, SHA-256 hash, proposed use,
sample rate/channels, measured duration/peak/RMS and current-event comparison keys.
The source archive hash matches the earlier asset audit. The catalog was built
against baseline `550d6280`. See [catalog summary](../../work/nox-sound-audition-2026-10-28/catalog_summary.json)
and [verification results](../../work/nox-sound-audition-2026-10-28/verification.json).
Bundled NOX README license text is retained beside the metadata; its stated CC0
license was established in the original asset audit.

Focused checks cover all-file decoding/counts, stable IDs/hashes, special filename
classification, signed PCM24 decoding, current-event mapping, complete preview
duration/rate/channels for representative categories and 96 kHz source, byte-range
seeking, unsupported paths/ranges, and static UI availability. Browser checks cover
candidate/current playback, search/category filtering, sorting and local favorite
persistence. Temporary QA selections are cleared before handoff.

No runtime sound assignment, game code, equipment/combat system or scene tree
changed. Game audio is still awaiting Chase's listening decisions. A later
implementation should install only selected variants and verify them in the
actual environment at gameplay volume, with separate approval for any protected
system change. No gameplay acceptance is inferred from a working audition page.

Rebuild: `python tools/audio/build_nox_audition_catalog.py` (Python + NumPy).
Restart the task server after changing the catalog. Run
`python tools/audio/verify_nox_audition.py` against the running localhost service;
local socket access may require execution outside Codex's socket-restricted sandbox.

Checkpoint: `chore: add NOX sound audition browser and environment shortlist`.
