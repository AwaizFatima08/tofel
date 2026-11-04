#!/usr/bin/env python3
"""Checks every file in content/bank against docs/content-schema.md.

  python3 tool/validate.py                 whole bank, plus coverage against the blueprint
  python3 tool/validate.py --files a b     only those files (repo-wide duplicate check still runs)
  python3 tool/validate.py --coverage      also print every unmet target
Exit 1 if any error is found.
"""
import argparse, collections, json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BP = json.loads((ROOT / "content/blueprint.json").read_text())
TOPICS = {(s["key"], t["key"]): t for s in BP["sections"] for t in s["topics"]}
BANNED = re.compile(r"all of the above|none of the above|both a and b", re.I)
GAP = re.compile(r"\[\[([^\[\]|]*)\|([^\[\]|]*)\]\]")
SPEAKER = re.compile(r"^[WM]: \S")
TYPES = {
    "ctw": {"ctw"}, "rdl2": {"mc"}, "rdl3": {"mc"}, "rap": {"mc"},
    "lcr": {"lcr"}, "lcv": {"mc"}, "lan": {"mc"}, "lat": {"mc"},
    "bas": {"bas"}, "eml": {"email"}, "dsc": {"disc"}, "lrp": {"repeat"}, "int": {"interview"},
}
# words in a set text: (min, max)
SET_WORDS = {"rdl2": (20, 90), "rdl3": (85, 175), "rap": (160, 245)}
SCRIPT_WORDS = {"lcv": (70, 170), "lan": (60, 145), "lat": (150, 270)}


def norm(s):
    return re.sub(r"\s+", " ", s.lower()).strip()


def words(s):
    return len(re.findall(r"[A-Za-z0-9']+", s))


def load(path, errors):
    rows = []
    for n, line in enumerate(path.read_text().splitlines(), 1):
        if not line.strip():
            continue
        try:
            rows.append((n, json.loads(line)))
        except json.JSONDecodeError as e:
            errors.append(f"{path.name}:{n}: bad JSON: {e}")
    return rows


def check_ctw(q, err):
    stem = q["stem"]
    gaps = GAP.findall(stem)
    if len(gaps) != 10:
        err(f"ctw needs exactly 10 [[shown|missing]] gaps, found {len(gaps)}")
    if stem.count("[[") != len(gaps) or stem.count("]]") != len(gaps):
        err("malformed [[ ]] marker")
    first_gap = stem.find("[[")
    first_end = re.search(r"[.!?](\s|$)", stem)
    if first_end and first_gap != -1 and first_gap < first_end.start():
        err("the first sentence must have no gaps")
    for shown, missing in gaps:
        word = shown + missing
        if not re.fullmatch(r"[A-Za-z]{2,}", word):
            err(f"gap word must be letters only: {word!r}")
            continue
        if len(shown) != len(word) // 2:
            err(f"'{word}': show the first {len(word) // 2} letters (len//2), not {len(shown)}")
        if not missing:
            err(f"'{word}': nothing missing")
    plain = GAP.sub(lambda m: m.group(1) + m.group(2), stem)
    n = words(plain)
    if not 55 <= n <= 105:
        err(f"ctw paragraph has {n} words (want 60-95)")
    return [s + m for s, m in gaps]


def check_question(q, where, section, topic, sets, err):
    for field in ("id", "pool", "level", "type", "stem", "explanation"):
        if field not in q:
            err(f"missing {field}")
            return None
    meta = TOPICS.get((section, topic))
    if not meta:
        err(f"unknown section/topic {section}/{topic}")
        return None
    pool, kind = q["pool"], q["type"]
    if pool not in ("test", "practice"):
        err("pool must be test or practice")
    if not re.fullmatch(rf"{meta['prefix']}-{'t' if pool == 'test' else 'p'}\d{{4}}", q["id"]):
        err(f"id must look like {meta['prefix']}-t0001 / {meta['prefix']}-p0001")
    if q["level"] not in (1, 2, 3):
        err("level must be 1, 2 or 3")
    if kind not in TYPES[topic]:
        err(f"type {kind} not allowed in {topic} (use {sorted(TYPES[topic])})")
        return None
    min_expl = {"email": 400, "disc": 500, "interview": 300, "repeat": 20}.get(kind, 40)
    if len(q["explanation"]) < min_expl:
        err("explanation too short")
    opts, ans = q.get("options"), q.get("answer")
    if kind in ("mc", "lcr"):
        if not (isinstance(opts, list) and len(opts) == 4 and all(isinstance(o, str) and o.strip() for o in opts)):
            err("needs 4 non-empty options")
            return None
        if len({norm(o) for o in opts}) != 4:
            err("options are not all different")
        if not (isinstance(ans, list) and len(ans) == 1 and isinstance(ans[0], int) and 0 <= ans[0] < 4):
            err("answer must be [i] with i in 0-3")
            return None
    elif opts is not None or ans is not None:
        err(f"{kind} has no options or answer")
    if kind == "ctw":
        check_ctw(q, err)
    elif kind == "lcr":
        say = q.get("say", "")
        if not SPEAKER.match(say):
            err("say must start with 'W: ' or 'M: '")
        if not 3 <= words(say) <= 28:
            err(f"say has {words(say)} words (want 4-20)")
        if q["stem"] != "Choose the best response.":
            err("lcr stem must be 'Choose the best response.'")
    elif kind == "bas":
        chunks, suffix = q.get("chunks"), q.get("suffix")
        if not SPEAKER.match(q["stem"]):
            err("bas stem must start with 'W: ' or 'M: '")
        if not (isinstance(chunks, list) and 4 <= len(chunks) <= 7 and all(isinstance(c, str) and c.strip() == c and c for c in chunks)):
            err("bas needs 4-7 non-empty chunks")
            return kind
        if len({c.lower() for c in chunks}) != len(chunks):
            err("chunks must all be different")
        if not (isinstance(suffix, str) and suffix and suffix[-1] in ".?!"):
            err("suffix must end with . ? or !")
        if not isinstance(q.get("prefix", ""), str):
            err("prefix must be a string")
        extra = q.get("extra")
        if extra is not None and (not isinstance(extra, str) or extra.lower() in {c.lower() for c in chunks}):
            err("extra must be one chunk string not among the chunks")
        for alt in q.get("alt", []):
            if sorted(alt) != list(range(len(chunks))) or alt == list(range(len(chunks))):
                err("each alt must be a different permutation of the chunk indexes")
        if any(re.search(r"[.?!]$", c) for c in chunks):
            err("end punctuation belongs in suffix, not in a chunk")
    elif kind == "email":
        b = q.get("bullets")
        if not (isinstance(b, list) and len(b) == 3 and all(isinstance(x, str) and x for x in b)):
            err("email needs 3 bullets")
        if not q.get("task") or not (isinstance(q.get("points"), list) and len(q["points"]) >= 3):
            err("email needs task and 3+ points")
        n = words(q["explanation"])
        if not 95 <= n <= 175:
            err(f"model email has {n} words (want 110-160)")
    elif kind == "disc":
        posts = q.get("posts")
        if not (isinstance(posts, list) and len(posts) == 2 and all(isinstance(p, dict) and p.get("name") and p.get("text") for p in posts)):
            err("disc needs 2 posts with name and text")
        if not q.get("prof") or not q.get("task") or not (isinstance(q.get("points"), list) and len(q["points"]) >= 3):
            err("disc needs prof, task and 3+ points")
        n = words(q["explanation"])
        if not 110 <= n <= 185:
            err(f"model contribution has {n} words (want 120-170)")
    elif kind == "repeat":
        n = words(q["stem"])
        if not 3 <= n <= 24:
            err(f"repeat sentence has {n} words (want 4-22)")
    elif kind == "interview":
        n = words(q["explanation"])
        if not 80 <= n <= 135:
            err(f"model answer has {n} words (want 90-120)")
        if not (isinstance(q.get("points"), list) and len(q["points"]) >= 3):
            err("interview needs 3+ points")
    text = " ".join([q["stem"], q["explanation"], *(opts or [])])
    if BANNED.search(text):
        err("uses an all/none-of-the-above style option")
    if meta["set_size"] and "set" not in q:
        err("this topic needs a set id")
    if not meta["set_size"] and "set" in q:
        err("this topic does not use sets")
    return kind


def check_set(row, topic, err):
    if topic in SET_WORDS:
        n = words(row.get("text", ""))
        lo, hi = SET_WORDS[topic]
        if not lo <= n <= hi:
            err(f"text has {n} words (want {lo}-{hi})")
    if topic in SCRIPT_WORDS:
        script = row.get("script")
        if not (isinstance(script, list) and script and all(isinstance(s, str) and SPEAKER.match(s) for s in script)):
            err("script must be a list of 'W: ...' / 'M: ...' lines")
            return
        n = sum(words(s[3:]) for s in script)
        lo, hi = SCRIPT_WORDS[topic]
        if not lo <= n <= hi:
            err(f"script has {n} words (want {lo}-{hi})")
        speakers = {s[0] for s in script}
        if topic == "lcv" and len(speakers) != 2:
            err("a conversation needs a W and an M speaker")
        if topic in ("lan", "lat") and len(speakers) != 1:
            err("announcements and talks have one speaker")
        if re.search(r"[\[\]()*]", " ".join(script)):
            err("no brackets or stage directions in a script")
    if topic in ("lrp", "int"):
        if row.get("voice") not in ("W", "M") or not row.get("title"):
            err("speaking sets need title and voice W or M")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--files", nargs="*")
    ap.add_argument("--coverage", action="store_true")
    args = ap.parse_args()
    errors = []
    all_files = sorted((ROOT / "content/bank").glob("*/*.jsonl"))
    only = {Path(f).resolve() for f in args.files} if args.files else None
    ids, stems, sets, set_where, texts = {}, {}, {}, {}, {}
    members = collections.defaultdict(list)
    have = collections.Counter()  # (topic, level, pool) -> questions or sets
    keys = collections.Counter()
    types = collections.Counter()
    levels = collections.Counter()
    longest = wordy = 0
    for path in all_files:
        section = path.parent.name
        topic = re.sub(r"-\d+$", "", path.stem)
        report = only is None or path.resolve() in only
        sink = errors if report else []
        meta = TOPICS.get((section, topic))
        for n, row in load(path, sink):
            where = f"{section}/{path.name}:{n}"
            if row.get("type") == "set":
                sid = row.get("id", "")
                err = lambda m, sid=sid, where=where, sink=sink: sink.append(f"{where} {sid}: {m}")
                if sid in sets:
                    err("duplicate set id")
                if meta and not re.fullmatch(rf"{meta['prefix']}-[tp]s\d{{3}}", sid):
                    err(f"set id must look like {meta['prefix']}-ts001 / {meta['prefix']}-ps001")
                if row.get("pool") not in ("test", "practice") or row.get("level") not in (1, 2, 3):
                    err("set needs pool and level")
                if len(row.get("text", "")) < 30:
                    err("set text too short")
                key = norm(row.get("text", "") + " ".join(row.get("script", [])))
                if key in texts:
                    err(f"same text as {texts[key]}")
                texts[key] = sid
                check_set(row, topic, err)
                sets[sid] = row
                set_where[sid] = (where, sink, section, topic)
                continue
            err = lambda m, row=row, where=where, sink=sink: sink.append(f"{where} {row.get('id', '?')}: {m}")
            kind = check_question(row, where, section, topic, sets, err)
            qid = row.get("id", "?")
            if qid in ids:
                err(f"duplicate id (also {ids[qid]})")
            ids[qid] = where
            sid = row.get("set")
            if sid:
                members[sid].append(row)
                if sid not in sets:
                    err(f"set {sid} not found above this line")
                elif (sets[sid].get("pool"), sets[sid].get("level")) != (row.get("pool"), row.get("level")):
                    err("pool and level must match the set's")
            key = (norm(row.get("stem", "") + "|" + row.get("say", "")), sid or "")
            if key in stems and row.get("type") not in ("repeat",):
                err(f"same stem as {stems[key]}")
            stems[key] = qid
            if not meta:
                continue
            if not meta["set_size"]:
                have[(topic, row.get("level"), row.get("pool"))] += 1
            if report and kind:
                types[kind] += 1
                levels[row.get("level")] += 1
                if kind in ("mc", "lcr") and row.get("answer"):
                    keys[(kind, row["answer"][0])] += 1
                    lengths = [len(o) for o in row["options"]]
                    if max(lengths) >= 20:
                        wordy += 1
                        if lengths[row["answer"][0]] == max(lengths) and lengths.count(max(lengths)) == 1:
                            longest += 1
    for sid, row in sets.items():
        where, sink, section, topic = set_where[sid]
        meta = TOPICS.get((section, topic))
        if not meta:
            continue
        size = len(members[sid])
        if meta["set_size"] and size != meta["set_size"]:
            sink.append(f"{where} {sid}: set has {size} questions, needs {meta['set_size']}")
        have[(topic, row.get("level"), row.get("pool"))] += 1
    for e in errors[:300]:
        print("ERROR", e)
    if len(errors) > 300:
        print(f"... {len(errors) - 300} more")
    total = sum(types.values())
    if total:
        print("types", dict(sorted(types.items())), "levels", dict(sorted(levels.items())))
        for kind in ("mc", "lcr"):
            counts = [keys.get((kind, i), 0) for i in range(4)]
            if sum(counts) >= 20:
                print(f"{kind} answer positions {counts}")
                if min(counts) < sum(counts) / 4 * 0.5:
                    print(f"WARN {kind} answer positions are unevenly spread")
        if wordy >= 20:
            share = longest / wordy
            print(f"correct option is the longest in {share:.0%} of {wordy} wordy questions (chance 25%)")
            if share > 0.4:
                print("WARN correct answers stand out by length; rebalance the options")
    if only is None or args.coverage:
        short, lines = 0, []
        for s in BP["sections"]:
            for t in s["topics"]:
                for slot, want in t["test"].items():
                    got = have[(t["key"], int(slot[1]), "test")]
                    if got < want:
                        short += (want - got) * (t["set_size"] or 1)
                        lines.append(f"  {s['key']}/{t['key']} test {slot}: {got}/{want} {t['test_unit']}")
                got = sum(v for (tk, _, pool), v in have.items() if tk == t["key"] and pool == "practice")
                if got < t["practice"]:
                    short += (t["practice"] - got) * (t["set_size"] or 1)
                    lines.append(f"  {s['key']}/{t['key']} practice: {got}/{t['practice']} {t['test_unit']}")
        if args.coverage:
            print("\n".join(lines))
        print(f"coverage: {len(ids)} questions, about {short} still to write")
    print(f"{len(errors)} errors")
    sys.exit(1 if errors else 0)


main()
