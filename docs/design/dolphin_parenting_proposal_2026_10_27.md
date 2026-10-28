# Independent duplicate dolphin — scene correction proposal

**Approved by Chase on October 27, 2026:** "Approve the dolphin reparenting fix."
Implementation/verification are tracked in the October 27 follow-up report.

The comparison scene's added dolphin was a child of
the original Tide Duelist. Parent movement carries it without running the child's
wall sweep. Parent death/hiding and process changes also affect the child.
Changing only its transform-inheritance flag would leave those lifetime problems.

Reparent **only the added dolphin** as a direct child of the room. Preserve its
current world position, **(349, 2008)**, all tuning and unique ID. Name it
`TideDuelist2`. Keep the original dolphin and the user-added heron in place.
Do not add randomized attack delays or change enemy damage/speed.

The concrete scene edit is:

```diff
-[node name="TideDuelist" parent="TideDuelist" parent_id_path=PackedInt32Array(553997636) index="13" unique_id=1067205541 instance=ExtResource("2_ewax1")]
-position = Vector2(-275, 1185)
+[node name="TideDuelist2" parent="." unique_id=1067205541 instance=ExtResource("2_ewax1")]
+position = Vector2(349, 2008)
```

The comparison-controller sibling index will be updated if necessary to reflect
the additional room child. Preserve all other existing user/editor scene edits.

Files to modify:

- `Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.tscn`
- New `tools/enemies/verify_duplicate_dolphins.gd` and optional Godot UID
- New `work/duplicate-dolphins-2026-10-27/` before/after motion, collision, death
  and reset reports with `.gdignore`
- This proposal, `docs/verification/lakeside_followups_2026_10_27.md`,
  `docs/project_status_and_worklist.md` and `docs/next_test_session.md`

Verify authored world placement, each enemy's independent dash and wall sweep,
parent movement/death not moving/hiding the other, separate targeting, and F2/save
reset preserving both actors and their art selection. Existing idle phase offsets
already keep their breathing/tail motions separate.

AGENTS.md explicitly lists "Scene tree restructuring" as requiring approval.
This correction changes the saved parent/child relationship; Chase's explicit
approval above authorizes the scoped scene edit. Appearance/feel acceptance is separate.
