# NOX sound audition

Open **http://127.0.0.1:8876/** while the local audition server is running.
To reopen later, run `tools/audio/start_nox_audition.ps1` from this repository.
It uses the bundled Python runtime, starts the server hidden, and opens the page.
To run in a terminal instead: `python tools/audio/serve_nox_audition.py`.

Start here shows 60 candidates for footsteps, landings, shallow splashes, water,
caves, rain/wind, hearths, doors, keys, cloth and outdoor life. All 1,644 NOX files
and 27 current SFX sources can also be browsed. Search/filter/sort the list, play
a candidate, compare current sources where listed, and mark Favorite/Maybe/Pass.
Notes and decisions are saved in this browser on this localhost origin. Use
**Export my picks** to save/share `threadbound-sound-picks.json`.

Candidates are proposed from source names and project needs, not accepted by
listening. The in-game mix/pitch is not reproduced. No sound is replaced or
imported by this tool. The task folder has `.gdignore`; source audio stays in
the external NOX ZIP and existing project locations.

The NOX archive must remain at:
`C:\Users\chase\Documents\Threadbound Asset Library\archives\Essentials_Series_NOX_SOUND.zip`.
The raw archive remains local-only. Catalog, tools and verification are in Git.
