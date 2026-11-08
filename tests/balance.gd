extends SceneTree
## Actual-engine deterministic balance regression, not a Python approximation.
const Simulation = preload("res://scripts/simulation/case_simulation.gd")
const SAMPLES = 500
const PRIORITY = {
    "nomination": 25, "petition": 18, "rulebook": 16,
    "special_council": 15, "front_page": 14, "goose_stage": 13,
    "goose_hungry": 12, "goose_prize": 11, "camera": 10,
    "goose_viral": 9, "endorsement": 8, "goose_debate": 7, "poll": 6
}

func _initialize() -> void:
    var natural := _wins(false)
    var guided := _wins(true)
    print("Balance: natural=%d/%d; targeted Nudge=%d/%d" % [natural, SAMPLES, guided, SAMPLES])
    if natural >= 175:
        printerr("FAIL: the town wins too often without intervention")
        quit(1)
    elif guided < 300 or guided - natural < 250:
        printerr("FAIL: a targeted strategy must meaningfully outperform chance")
        quit(1)
    else:
        print("PASS: actual Godot balance regression")
        quit(0)

func _wins(strategy: bool) -> int:
    var wins := 0
    for seed_id in range(SAMPLES):
        var sim = Simulation.new(seed_id, false)
        for day_index in range(7):
            if strategy:
                var best_id: String = ""
                var best_score: float = -1.0
                for rule in sim.available_events():
                    var id: String = str(rule["id"])
                    var utility: float = float(PRIORITY.get(id, 0)) + 0.2 * int(rule["support"])
                    if utility > best_score and sim.can_stamp("nudge", id):
                        best_id = id
                        best_score = utility
                if not best_id.is_empty():
                    sim.stage_stamp("nudge", best_id)
            sim.advance_day()
        if sim.status == "won":
            wins += 1
    return wins
