#!/usr/bin/env python3
"""Generate the transmission roster grid from the transform.

Headroom band x scrutiny level x triage behavior = 3 x 3 x 4 = 36 entries.
Each entry is computed, never hand-set, so the grid tests whether the
transform is deterministic and complete.

Version 1.2 replaces the banded lookup tables with piecewise-linear
resolution over the same points, so one implementation serves the grid
and any off-grid posture. At band centers the outputs are identical to
the tables they replace.
"""

# --- posture sample points -------------------------------------------------

HEADROOM = {
    "C1": dict(label="low",  fluency=0.20, stamina=0.15, appetite=0.25),
    "C2": dict(label="mid",  fluency=0.60, stamina=0.50, appetite=0.40),
    "C3": dict(label="high", fluency=0.90, stamina=0.85, appetite=0.85),
}

SCRUTINY = {
    "S1": dict(label="settled",     value=0.15),
    "S2": dict(label="guarded",     value=0.50),
    "S3": dict(label="adversarial", value=0.85),
}

TRIAGE = {
    "T1": dict(label="full",     place="defer", single=0.50,
               priority="content"),
    "T2": dict(label="scan",     place="frame",    single=0.80,
               priority="balance"),
    "T3": dict(label="decide",   place="early",    single=0.80,
               priority="extent"),
    "T4": dict(label="sentence", place="sentence", single=1.00,
               priority="extent"),
}

OFFICE = {
    "construct": dict(iuxta_floor=0.20, sequent_floor=0.20),
    "judicial":     dict(iuxta_floor=0.85, sequent_floor=0.70),
}

# --- declared constants ----------------------------------------------------
# None of these is measured. They are the framework's tuning surface and are
# named here rather than buried in the arithmetic.

OFFICE_GAP = 0.35            # sequent may not exceed iuxta by more than this
SEQUENT_DISCOUNT = 0.20    # sequent sits below the other capacity settings
SEQUENT_LANDING = 0.70     # at and above, arrangement leaves the land instrument
OBLIGE_DEFAULT = 0.90  # the professional case the grid spans
OBLIGE_EARLY = 0.60    # delta fraction at which place moves to early
OBLIGE_DELTA = dict(steady=-0.60, settled=-0.35, invite=+0.30)

# --- resolution curves -----------------------------------------------------
# Each is a list of (input, output) points read by piecewise interpolation.
# Inputs are capacity for the headroom-side curves and scrutiny for the rest.

FLAT_BY_CAPACITY  = [(0.15, 0.90), (0.50, 0.85), (0.85, 0.60)]
FLAT_BY_SCRUTINY  = [(0.15, 0.90), (0.50, 0.75), (0.85, 0.30)]
FLAT_CONCESSION   = 0.15
BARE_BY_CAPACITY  = {0.15: [(0.15, 0.90), (0.50, 0.90), (0.85, 0.90)],
                     0.50: [(0.15, 0.70), (0.50, 0.60), (0.85, 0.55)],
                     0.85: [(0.15, 0.35), (0.50, 0.20), (0.85, 0.10)]}
STEADY_BY_CAPACITY = [(0.15, 0.95), (0.50, 0.85), (0.85, 0.80)]
INVITE_BY_SCRUTINY = [(0.15, 0.35), (0.50, 0.65), (0.85, 0.30)]
ADVERSARIAL = 0.85


def clamp(x, lo=0.0, hi=1.0):
    return round(max(lo, min(hi, x)), 2)


def curve(x, points):
    """Piecewise-linear read of a resolution curve, flat outside its ends."""
    if x <= points[0][0]:
        return points[0][1]
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        if x <= x1:
            return y0 + (x - x0) * (y1 - y0) / (x1 - x0)
    return points[-1][1]
NAMES = {
    "C1-S1-T1": "The learner",
    "C1-S1-T2": "The fatigued reviewer",
    "C1-S3-T1": "The depleted auditor",
    "C2-S1-T1": "The settled executive",
    "C2-S1-T3": "The delegating chief",
    "C2-S2-T1": "The guarded evaluator",
    "C2-S2-T3": "The selection panel",
    "C2-S3-T1": "The auditor",
    "C3-S1-T1": "The peer specialist",
    "C3-S1-T2": "The reference user",
    "C3-S3-T1": "The peer reviewer",
    "C3-S2-T2": "The standards body",
}


GRADIENTS = {
    "C1-S1-T1": ["reader in distress -> invite 0.85, steady 1.00",
                 "consent to work absent -> see the obligation overlay"],
    "C1-S1-T2": ["descent may never come -> place early",
                 "capacity intact, willingness spent -> spread holds, "
                 "sparse to 0.90"],
    "C1-S3-T1": ["provenance still required -> attribute agent carries "
                 "it structurally, flat stays high",
                 "counsel may read -> single 0.90",
                 "the finding judges past action -> declare office judicial"],
    "C2-S1-T1": ["reader scans -> place frame, single 0.80",
                 "standing below the register -> invite 0.60",
                 "fatigue on the day -> settled and spread +0.20",
                 "the memo reviews a decision already taken -> declare "
                 "office judicial"],
    "C2-S2-T1": ["standing genuinely held -> invite 0.45",
                 "compression reads as a claim -> spread +0.15"],
    "C2-S3-T1": ["litigation-adjacent -> flat -0.15, bare -0.10",
                 "finding is uncontested -> bare 0.70",
                 "the finding judges past action -> declare office judicial"],
    "C3-S1-T1": ["consuming model -> ground, sparse, plain to 0.00; "
                 "cadence staccato",
                 "outside the specialty -> treat as C2",
                 "end of a hard week -> stamina falls, treat spread and "
                 "settled as C2"],
    "C3-S1-T2": ["structure is rotation, not development -> settled 0.05",
                 "newcomer may enter the audience -> plain +0.30"],
    "C3-S3-T1": ["reviewing rather than reviewed -> invite 0.50",
                 "provenance is the content -> flat 0.10"],
}


FALLBACK = {
    "C1": ["fluency higher than stamina -> plain falls, ground and "
           "spread hold on stamina",
           "consent to work present -> ground to 1.00"],
    "C2": ["stamina spent on the day -> spread, sparse, settled toward C1",
           "appetite higher than assessed -> spread and plain toward C3"],
    "C3": ["reading outside the specialty -> treat as C2 throughout",
           "newcomer in the audience -> plain +0.30, ground +0.30"],
}


SCRUT_FALLBACK = {
    "S1": "pre-emptive defense reads as trouble -> keep bare above 0.80",
    "S2": "standing genuinely held -> invite toward 0.45",
    "S3": "the challenge is real -> bare is the setting that earns its cost",
}


def flat_setting(capacity, scrutiny):
    """Layering takes the higher of the two derivations, conceding one step
    toward the scrutiny pull where they conflict."""
    by_capacity = curve(capacity, FLAT_BY_CAPACITY)
    by_scrutiny = curve(scrutiny, FLAT_BY_SCRUTINY)
    if by_scrutiny >= by_capacity:
        return clamp(by_capacity)
    return clamp(max(by_scrutiny, by_capacity - FLAT_CONCESSION))


def bare_setting(capacity, scrutiny):
    """Scrutiny sets the target; capacity lifts it, pre-emptive defense being
    itself load that a depleted reader cannot carry."""
    pts = [(s, curve(capacity, BARE_BY_CAPACITY[s]))
           for s in sorted(BARE_BY_CAPACITY)]
    return clamp(curve(scrutiny, pts))


def office_settings(office, capacity, scrutiny):
    """Resolve (iuxta, sequent). sequent takes capacity less the discount;
    iuxta takes scrutiny, the one setting scrutiny raises. The office sets
    floors under both, and the floors do not yield."""
    floors = OFFICE[office]
    sequent = clamp(max(floors["sequent_floor"],
                        1.0 - capacity - SEQUENT_DISCOUNT))
    iuxta = clamp(max(floors["iuxta_floor"], scrutiny))
    if sequent - iuxta > OFFICE_GAP:
        iuxta = clamp(sequent - OFFICE_GAP)
    return iuxta, sequent


def oblige_fraction(oblige):
    """How far this reader falls short of the obliged professional case.
    0.0 is a reader who owes the reading; 1.0 is one present by choice."""
    return clamp((OBLIGE_DEFAULT - oblige) / OBLIGE_DEFAULT)


def cadence_note(spread, declared=None):
    """Cadence is declared from document kind, not derived from posture. The
    one enforced exclusion: distribution needs span, so high spread cannot be
    carried in short declaratives."""
    if declared:
        return declared
    return "declared, staccato excluded" if spread >= 0.70 else "declared"


def resolve(cred, scrut, tri, office="construct",
            oblige=OBLIGE_DEFAULT, cadence=None, span=None):
    c, s, t = HEADROOM[cred], SCRUTINY[scrut], TRIAGE[tri]
    return resolve_posture(
        fluency=c["fluency"], stamina=c["stamina"], appetite=c["appetite"],
        scrutiny=s["value"], triage=t["label"], oblige=oblige,
        office=office, cadence=cadence, span=span)


def resolve_posture(fluency, stamina, appetite, scrutiny, triage,
                    oblige=OBLIGE_DEFAULT, office="construct",
                    cadence=None, priority=None, span=None):
    """The transform. Works on and off the grid."""
    capacity = min(fluency, stamina)
    base = clamp(1.0 - capacity)

    spread   = clamp(base + (0.5 - appetite) * 0.30)
    sparse   = base
    plain    = clamp((1.0 - fluency) + (0.5 - appetite) * 0.20)
    ground = clamp(base + 0.15)

    settled = linked = base
    flat = flat_setting(capacity, scrutiny)
    bare = bare_setting(capacity, scrutiny)
    attribute = "agent" if scrutiny >= ADVERSARIAL else "artifact"

    steady = curve(capacity, STEADY_BY_CAPACITY)
    if scrutiny >= ADVERSARIAL:
        steady += 0.05
    invite = curve(scrutiny, INVITE_BY_SCRUTINY)

    # oblige is the one component that moves with its settings
    frac = oblige_fraction(oblige)
    steady    = clamp(steady    + OBLIGE_DELTA["steady"]    * frac)
    settled   = clamp(settled   + OBLIGE_DELTA["settled"]   * frac)
    invite = clamp(invite + OBLIGE_DELTA["invite"] * frac)

    tri = {"full": "T1", "scan": "T2", "decide": "T3",
           "sentence": "T4"}[triage]
    t = TRIAGE[tri]
    single = t["single"]
    place = t["place"]
    if linked >= 0.70:
        single = clamp(single + 0.15)
    if frac >= OBLIGE_EARLY and place in ("defer", "frame"):
        place = "early"

    if tri == "T4":
        sparse = 0.00
        ground = min(ground, 0.50)

    iuxta, sequent = office_settings(office, capacity, scrutiny)
    if sequent >= SEQUENT_LANDING:
        if place == "defer":
            place = "coda"
        single = clamp(single + 0.15)

    return dict(
        fluency=fluency, stamina=stamina, appetite=appetite,
        scrutiny=scrutiny, triage=triage, oblige=oblige,
        capacity=clamp(capacity),
        office=office, cadence=cadence_note(spread, cadence),
        priority=priority or t["priority"], span=span or "",
        spread=spread, sparse=sparse, plain=plain, ground=ground,
        steady=steady, invite=invite, single=single,
        place=place,
        settled=settled, linked=linked, flat=flat, bare=bare,
        iuxta=iuxta, sequent=sequent, attribute=attribute,
    )


def fmt(v):
    return "%.2f" % v if isinstance(v, float) else v


def calibration_block(r, indent=""):
    """The full calibration, in the presentation order used everywhere:
    document, posture, load, land, vantage. Scalars precede categoricals
    within each group; the document group is the exception, its trailing
    span being an integer word count."""
    L = []
    L.append("document    office %-11s cadence %s"
             % (r["office"], r["cadence"]))
    L.append("            priority %s%s"
             % (r["priority"], "  span %s" % r["span"] if r["span"] else ""))
    L.append("posture     fluency %.2f  stamina %.2f  appetite %.2f  "
             "scrutiny %.2f" % (r["fluency"], r["stamina"], r["appetite"],
                                r["scrutiny"]))
    L.append("            oblige %.2f   triage %s" % (r["oblige"], r["triage"]))
    L.append("load        spread %s  sparse %s  plain %s  ground %s"
             % (fmt(r["spread"]), fmt(r["sparse"]), fmt(r["plain"]),
                fmt(r["ground"])))
    L.append("land        steady %s  invite %s  single %s  place %s"
             % (fmt(r["steady"]), fmt(r["invite"]), fmt(r["single"]),
                r["place"]))
    L.append("vantage     settled %s  linked %s  flat %s  bare %s"
             % (fmt(r["settled"]), fmt(r["linked"]), fmt(r["flat"]),
                fmt(r["bare"])))
    L.append("            iuxta %s  sequent %s  attribute %s"
             % (fmt(r["iuxta"]), fmt(r["sequent"]), r["attribute"]))
    return "\n".join(indent + x for x in L)


def render(cred, scrut, tri):
    key = "%s-%s-%s" % (cred, scrut, tri)
    r = resolve(cred, scrut, tri)
    name = NAMES.get(key)
    head = "**%s**" % key + ("  ---  %s" % name if name else "")
    lines = [head, "```", calibration_block(r), "```"]
    grads = GRADIENTS.get(key, FALLBACK[cred] + [SCRUT_FALLBACK[scrut]])
    for g in grads:
        lines.append("- %s" % g)
    lines.append("")
    return "\n".join(lines)


def office_overlay():
    """Judicial deltas against the construct grid. A full cross would
    double the roster to record a declaration that moves at most four
    fields, so the judicial case is an overlay."""
    lines = []
    for tri in TRIAGE:
        rows = []
        for cred in HEADROOM:
            for scrut in SCRUTINY:
                a = resolve(cred, scrut, tri, "construct")
                b = resolve(cred, scrut, tri, "judicial")
                moved = ["%s %s -> %s" % (k, fmt(a[k]), fmt(b[k]))
                         for k in ("iuxta", "sequent", "place", "single")
                         if a[k] != b[k]]
                if moved:
                    rows.append("    %-9s %s" % (key_of(cred, scrut, tri),
                                                 "   ".join(moved)))
        if rows:
            lines.append("### Triage: %s\n" % TRIAGE[tri]["label"])
            lines.append("```")
            lines.extend(rows)
            lines.append("```\n")
    return "\n".join(lines)


def key_of(cred, scrut, tri):
    return "%s-%s-%s" % (cred, scrut, tri)


if __name__ == "__main__":
    out = []
    for tri in TRIAGE:
        out.append("### Triage: %s\n" % TRIAGE[tri]["label"])
        for cred in HEADROOM:
            for scrut in SCRUTINY:
                out.append(render(cred, scrut, tri))
    print("\n".join(out))
    print("@@OFFICE_OVERLAY@@")
    print(office_overlay())
