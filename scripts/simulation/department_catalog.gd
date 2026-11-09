extends RefCounted
## Permanent unlocks with case-specific loadouts. All game effects live in CaseSimulation;
## this catalog is the single source for price, tier and readable promises.

const ORDER: Array[String] = [
    "lost_property", "fortuitous_timing", "embarrassments", "postal_inspector",
    "double_booking", "appointment_bureau", "echo_chamber", "rumour_mill",
    "reality_reconciliation", "chain_reactions", "second_chances", "automatic_paperwork"
]
const DATA: Dictionary = {
    "lost_property": {"name": "Department of Lost Property", "cost": 7, "cases": 0, "detail": "The first misdirectable letter or poster each day takes its alternate route automatically.", "tag": "MISROUTING"},
    "fortuitous_timing": {"name": "Office of Fortuitous Timing", "cost": 9, "cases": 0, "detail": "Each day, one incident can synchronize an unrelated eligible incident at the same location.", "tag": "SYNCHRONIZE"},
    "embarrassments": {"name": "Minor Embarrassments Division", "cost": 9, "cases": 0, "detail": "The first official social blunder daily creates gossip and replenishes one Influence.", "tag": "GOSSIP"},
    "postal_inspector": {"name": "Inspectorate of Misplaced Mail", "cost": 11, "cases": 1, "detail": "The first postal incident daily guarantees an eligible consequence it directly unlocks.", "tag": "POSTAL CASCADE"},
    "double_booking": {"name": "Department of Double Booking", "cost": 14, "cases": 2, "detail": "Approve TWO different stamps per day, if you can pay for both and accept their Strain.", "tag": "SECOND STAMP"},
    "appointment_bureau": {"name": "Office of Convenient Appointments", "cost": 15, "cases": 2, "detail": "Reschedule automatically books one other eligible incident from the same location.", "tag": "RESCHEDULE PAIR"},
    "echo_chamber": {"name": "Bureau of Parallel Outcomes", "cost": 17, "cases": 3, "detail": "Once a day, an incident with two plausible outcomes may create both sets of consequences.", "tag": "PARALLEL FACTS"},
    "rumour_mill": {"name": "Official Rumour Mill", "cost": 18, "cases": 3, "detail": "The first support-gaining incident each day plants a public-interest lead for further news.", "tag": "VIRAL CHAIN"},
    "reality_reconciliation": {"name": "Reality Reconciliation Office", "cost": 21, "cases": 4, "detail": "The first reality correction daily also produces a second, different correction's facts.", "tag": "DIVERSE CORRECTIONS"},
    "chain_reactions": {"name": "Knock-On Effects Authority", "cost": 24, "cases": 4, "detail": "The first new eligible consequence each day is guaranteed instead of rolling its chance.", "tag": "FREE DOMINO"},
    "second_chances": {"name": "Appeals and Second Chances", "cost": 28, "cases": 6, "detail": "The first failed stamped attempt daily is guaranteed tomorrow if still eligible.", "tag": "APPEAL"},
    "automatic_paperwork": {"name": "Office of Self-Filing Paperwork", "cost": 36, "cases": 8, "detail": "Automatically completes up to two newly eligible multi-prerequisite links each day.", "tag": "AUTO CHAIN"}
}

static func get_department(id: String) -> Dictionary:
    return DATA.get(id, {})

static func is_known(id: String) -> bool:
    return DATA.has(id)
