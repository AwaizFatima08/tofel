#!/usr/bin/env python3
"""Builds assets/data from content/: one bank file per section, forms.json (the 20 mock papers), catalog.json,
lessons.json, guide.json and vocab.json.

Each paper holds, for Reading and Listening, the router module plus both second modules (lower and upper), filled
slot by slot from the blueprint recipes, and the linear Writing and Speaking tasks. Same input gives the same papers
(fixed seeds), so paper contents stay stable.
  python3 tool/build_content.py            needs the full bank
  python3 tool/build_content.py --partial  builds only the papers the bank can fill (development)
"""
import collections, json, random, re, shutil, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets/data"
BP = json.loads((ROOT / "content/blueprint.json").read_text())
PAPERS = BP["papers"]
PARTIAL = "--partial" in sys.argv
SET_SIZE = {t["key"]: t["set_size"] for s in BP["sections"] for t in s["topics"]}
# Order of tasks inside a module, as on the real test.
ORDER = ["ctw", "rdl2", "rdl3", "rap", "lcr", "lcv", "lan", "lat"]
Q_FIELDS = (("options", "o"), ("answer", "a"), ("set", "st"), ("say", "sy"), ("chunks", "ck"), ("prefix", "pf"),
            ("suffix", "sf"), ("extra", "ex"), ("alt", "al"), ("bullets", "bl"), ("task", "tk"), ("points", "pt"),
            ("prof", "pr"), ("posts", "ps"))
S_FIELDS = (("title", "t"), ("text", "x"), ("kind", "k"), ("script", "sc"), ("roles", "r"), ("voice", "v"))


def load():
    sets, questions = {}, []
    for path in sorted((ROOT / "content/bank").glob("*/*.jsonl")):
        topic = re.sub(r"-\d+$", "", path.stem)
        for line in path.read_text().splitlines():
            if not line.strip():
                continue
            row = json.loads(line)
            row["topic"], row["section"] = topic, path.parent.name
            if row.get("type") == "set":
                sets[row["id"]] = row
            else:
                questions.append(row)
    return sets, questions


def units(questions, sets):
    """Test-pool units keyed by (topic, level): single question ids, or the ordered ids of a set."""
    by_set = collections.defaultdict(list)
    out = collections.defaultdict(list)
    for q in questions:
        if q["pool"] != "test":
            continue
        if q.get("set"):
            by_set[q["set"]].append(q["id"])
        else:
            out[(q["topic"], q["level"])].append([q["id"]])
    for sid, ids in by_set.items():
        s = sets[sid]
        out[(s["topic"], s["level"])].append(ids)
    for key in out:
        out[key].sort()
    return out


def fill(pool, recipes, short):
    """recipes: {name: [slots]}; returns per paper {name: [(topic, unit)]} or None when the bank is short."""
    need = collections.defaultdict(list)  # (topic, level) -> [(name, count)]
    for name, slots in recipes.items():
        for slot in slots:
            need[(slot["topic"], slot["level"])].append((name, slot["count"]))
    papers = [{name: [] for name in recipes} for _ in range(PAPERS)]
    broken = set()
    for key, wants in need.items():
        per_paper = sum(n for _, n in wants)
        items = list(pool.get(key, []))
        random.Random(f"{'/'.join(recipes)}/{key}").shuffle(items)
        if len(items) < per_paper * PAPERS:
            short.append(f"{key}: {len(items)}/{per_paper * PAPERS}")
        for k in range(PAPERS):
            chunk = items[k * per_paper:(k + 1) * per_paper]
            if len(chunk) < per_paper:
                broken.add(k)
                continue
            for name, n in wants:
                papers[k][name] += [(key[0], u) for u in chunk[:n]]
                chunk = chunk[n:]
    return [None if k in broken else p for k, p in enumerate(papers)]


def ordered(stage_units, rng):
    stage_units = list(stage_units)
    rng.shuffle(stage_units)
    stage_units.sort(key=lambda u: ORDER.index(u[0]) if u[0] in ORDER else 99)
    return [i for _, u in stage_units for i in u]


def build_papers(pool, levels):
    short = []
    adaptive = {k: fill(pool, m["stages"], short) for k, m in BP["adaptive"].items()}
    writing = fill(pool, {"w": BP["writing"]["tasks"]}, short)
    speaking = fill(pool, {"s": BP["speaking"]["tasks"]}, short)
    built = []
    for k in range(PAPERS):
        parts = [adaptive["reading"][k], adaptive["listening"][k], writing[k], speaking[k]]
        if any(p is None for p in parts):
            continue
        paper = {"id": f"toefl-{k + 1:02d}", "number": k + 1, "title": f"Mock Test {k + 1}"}
        for key in ("reading", "listening"):
            rng = random.Random(f"order/{key}/{k}")
            paper[key] = {stage: ordered(u, rng) for stage, u in adaptive[key][k].items()}
            for stage, ids in paper[key].items():
                assert sum(10 if i.startswith("rc-") else 1 for i in ids) == BP["adaptive"][key]["items"][stage], (k, key, stage)
        tasks = collections.defaultdict(list)
        for topic, unit in sorted(writing[k]["w"], key=lambda u: (u[0], levels[u[1][0]], u[1][0])):
            tasks[topic] += unit
        for topic, unit in speaking[k]["s"]:
            tasks[topic] += unit
        paper["tasks"] = dict(tasks)
        built.append(paper)
    return built, short


def check(papers, pool):
    used = collections.Counter(
        i for p in papers for part in (p["reading"], p["listening"], p["tasks"]) for ids in part.values() for i in ids)
    repeats = [i for i, n in used.items() if n > 1]
    if repeats:
        sys.exit(f"{len(repeats)} questions used twice, e.g. {repeats[:3]}")
    all_ids = {i for units_ in pool.values() for u in units_ for i in u}
    unused = all_ids - set(used)
    if unused:
        print(f"note: {len(unused)} test questions not used in any paper, e.g. {sorted(unused)[:5]}")


def compact(q):
    row = {"id": q["id"], "tp": q["topic"], "pl": q["pool"][0], "lv": q["level"], "ty": q["type"],
           "s": q["stem"], "e": q["explanation"]}
    for src, dst in Q_FIELDS:
        if src in q and q[src] not in ("", None, []):
            row[dst] = q[src]
    return row


def main():
    sets, questions = load()
    pool = units(questions, sets)
    levels = {q["id"]: q["level"] for q in questions}
    papers, short = build_papers(pool, levels)
    if short and not PARTIAL:
        sys.exit("bank is short:\n  " + "\n  ".join(short))
    check(papers, pool)
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)
    for s in BP["sections"]:
        rows, used_sets = [], {}
        for q in questions:
            if q["section"] != s["key"]:
                continue
            rows.append(compact(q))
            if "set" in q:
                src = sets[q["set"]]
                used_sets[q["set"]] = {k2: src[k1] for k1, k2 in S_FIELDS if k1 in src}
        rows.sort(key=lambda r: r["id"])
        (OUT / f"bank_{s['key']}.json").write_text(json.dumps({"sets": used_sets, "questions": rows}, ensure_ascii=False, separators=(",", ":")))
    practice = collections.Counter()
    for q in questions:
        if q["pool"] == "practice":
            practice[q["topic"]] += 1
    lessons = [json.loads(p.read_text()) for p in sorted((ROOT / "content/lessons").glob("*.json"))]
    have_lesson = {l["topic"] for l in lessons}
    catalog = {
        "sections": [{"key": s["key"], "title": s["title"], "topics": [
            {"key": t["key"], "title": t["title"], "practice": practice[t["key"]], "lesson": t["key"] in have_lesson}
            for t in s["topics"]]} for s in BP["sections"]],
        "adaptive": [{"key": k, "minutes": m["minutes"], "items": m["items"], "upperAt": BP["route_upper_at"][k]}
                     for k, m in BP["adaptive"].items()],
        "writingMinutes": BP["writing"]["minutes"],
        "speakingSeconds": BP["speaking"]["seconds"],
    }
    (OUT / "catalog.json").write_text(json.dumps(catalog, ensure_ascii=False, separators=(",", ":")))
    (OUT / "forms.json").write_text(json.dumps(papers, separators=(",", ":")))
    (OUT / "lessons.json").write_text(json.dumps(lessons, ensure_ascii=False, separators=(",", ":")))
    guide = [json.loads(p.read_text()) for p in sorted((ROOT / "content/guide").glob("*.json"))]
    (OUT / "guide.json").write_text(json.dumps({"articles": guide}, ensure_ascii=False, separators=(",", ":")))
    vocab = sorted((w for p in sorted((ROOT / "content/vocab").glob("*.json")) for w in json.loads(p.read_text())), key=lambda w: w["w"].lower())
    (OUT / "vocab.json").write_text(json.dumps(vocab, ensure_ascii=False, separators=(",", ":")))
    size = sum(f.stat().st_size for f in OUT.iterdir())
    print(f"{len(papers)} papers built, {len(questions)} questions, {len(lessons)} lessons, {len(guide)} articles, {len(vocab)} words, {size / 1e6:.1f} MB")
    if short:
        print("short (partial build):\n  " + "\n  ".join(short[:30]))


main()
