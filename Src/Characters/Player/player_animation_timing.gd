extends RefCounted
## Preserved action timelines. Visible poses are owned by PlayerLive3DVisual.
## Unit-weight frames; completion signals and frame events keep their old cadence.
const CLIPS := {
	"Air_Double_Attack": {"frames": 27, "fps": 40.0, "loop": false},
	"Dash": {"frames": 1, "fps": 5.0, "loop": true},
	"Grapple_Diagonal": {"frames": 6, "fps": 18.0, "loop": false},
	"Grapple_Horizontal": {"frames": 6, "fps": 18.0, "loop": false},
	"Grapple_Strike": {"frames": 11, "fps": 40.0, "loop": false},
	"Ground_Attack_Combo_1": {"frames": 14, "fps": 30.0, "loop": false},
	"Ground_Attack_Combo_1_Backpedal": {"frames": 14, "fps": 30.0, "loop": false},
	"Ground_Attack_Combo_2": {"frames": 19, "fps": 30.0, "loop": false},
	"Ground_Attack_Combo_2_Backpedal": {"frames": 19, "fps": 30.0, "loop": false},
	"Ground_Attack_Combo_2_Stationary": {"frames": 19, "fps": 30.0, "loop": false},
	"Hurt": {"frames": 11, "fps": 60.0, "loop": false},
	"Idle": {"frames": 33, "fps": 24.0, "loop": true},
	"Jump_Apex": {"frames": 4, "fps": 8.0, "loop": true},
	"Jump_Ascent": {"frames": 4, "fps": 8.0, "loop": true},
	"Jump_Descent": {"frames": 4, "fps": 8.0, "loop": true},
	"Jump_Land": {"frames": 4, "fps": 12.0, "loop": false},
	"Ledge_Climb": {"frames": 4, "fps": 20.0, "loop": false},
	"Neutral_Special_Attack": {"frames": 48, "fps": 40.0, "loop": false},
	"Pogo_Attack": {"frames": 11, "fps": 24.0, "loop": false},
	"Pogo_Rebound": {"frames": 4, "fps": 24.0, "loop": false},
	"Run": {"frames": 11, "fps": 24.0, "loop": true},
	"Sit": {"frames": 48, "fps": 18.0, "loop": false},
	"Swim": {"frames": 38, "fps": 24.0, "loop": true},
	"Wall_Cling": {"frames": 4, "fps": 6.0, "loop": true},
}
