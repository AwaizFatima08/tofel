#!/usr/bin/env python3
"""Writes content/blueprint.json: topics, per-topic targets and the TOEFL iBT pattern.

TOEFL iBT since 21 Jan 2026 (checked against ets.org and the ETS "2026 Update Test Blueprint and Specifications",
4 Nov 2026): Reading (50 items, ~30 min) and Listening (47 items, ~29 min) are two-stage adaptive: a router module,
then a lower or upper module chosen by the router score. Writing (12 items, 23 min) and Speaking (11 items, 8 min)
are linear. Each section is reported on a 1-6 band scale in half bands; the overall band is their average rounded
to the nearest half band, with a comparable 0-120 total during the transition.

Every mock paper holds the router plus BOTH second modules (lower and upper) for Reading and Listening. A slot is
(topic, level, count); count is in questions, or in sets for set topics. Complete the Words counts as one question
per passage here (it scores 10 points: one per word).
"""
import collections, json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PAPERS = 20

# section key, title, [(topic key, id prefix, title, set size or 0, practice target, scope)]
SECTIONS = [
    ("reading", "Reading", [
        ("ctw", "rc", "Complete the Words", 0, 30,
         "A short academic paragraph (60-95 words): the first sentence is whole, then exactly 10 words have their second half missing; the test taker types the missing letters. Tests vocabulary, word forms, grammar and meaning from context."),
        ("rdl2", "rs", "Read in Daily Life: short texts", 2, 12,
         "Short everyday texts (25-80 words): notices, signs, text messages, menus, social media posts, short emails, timetables. 2 questions each: purpose, detail, meaning of a phrase, what the reader should do."),
        ("rdl3", "rl", "Read in Daily Life: longer texts", 3, 12,
         "Longer everyday texts (90-160 words): emails, campus announcements, flyers, product instructions, schedules, web pages, message threads. 3 questions each: purpose, detail, inference, vocabulary, next action."),
        ("rap", "ra", "Read an Academic Passage", 5, 12,
         "Academic passages of 170-230 words (life and earth science, history, art, psychology, business, technology) with 5 questions: main idea, detail, inference, vocabulary in context, reference, purpose of a sentence, organization, negative fact."),
    ]),
    ("listening", "Listening", [
        ("lcr", "lr", "Listen and Choose a Response", 0, 60,
         "One speaker says a short line (a question, request, complaint or remark, 4-20 words); choose the most natural reply from four written responses. Tests pragmatic meaning, idioms and indirect answers."),
        ("lcv", "lc", "Listen to a Conversation", 2, 16,
         "Short conversations between two speakers (80-150 words, 6-10 turns) in campus or everyday settings, 2 questions each: main topic, detail, speaker's purpose or attitude, what happens next."),
        ("lan", "la", "Listen to an Announcement", 2, 12,
         "Announcements or voicemails by one speaker (70-130 words): class changes, campus events, facility rules, field trips, deadlines. 2 questions each: purpose, detail, what listeners must do."),
        ("lat", "lt", "Listen to an Academic Talk", 4, 10,
         "Short lectures or academic talks by one speaker (160-250 words), science, social science, humanities, business. 4 questions each: main idea, detail, purpose of an example, speaker's attitude, organization, inference."),
    ]),
    ("writing", "Writing", [
        ("bas", "wb", "Build a Sentence", 0, 60,
         "A line from one person in a short exchange; the reply is built by putting 4-7 word chunks in the right order (sometimes with one extra chunk that does not belong). Tests word order: questions, embedded questions, tenses, relative clauses, adverb placement."),
        ("eml", "we", "Write an Email", 0, 10,
         "A practical situation (about 60-100 words) and three things the email must do; write an email of about 100-150 words in 7 minutes with the right tone."),
        ("dsc", "wd", "Write for an Academic Discussion", 0, 10,
         "A professor's question on a class discussion board and two students' posts; write a contribution of at least 100 words in 10 minutes that states and supports an opinion."),
    ]),
    ("speaking", "Speaking", [
        ("lrp", "sr", "Listen and Repeat", 7, 8,
         "A scenario (e.g. training as a museum guide) and 7 sentences to repeat exactly, getting longer and more complex (4 to about 20 words)."),
        ("int", "si", "Take an Interview", 4, 8,
         "A scenario (e.g. a research study about city life) and 4 interview questions, from personal and familiar to opinion and prediction; 45 seconds to answer each, no preparation time."),
    ]),
]

# Module recipes: (topic, level, count). Router modules are medium (level 2), upper modules hard (3), lower easy (1).
R_ROUTER = [("ctw", 2, 2), ("rdl2", 2, 1), ("rdl3", 2, 1), ("rap", 2, 2)]
R_LOWER = [("ctw", 1, 1), ("rdl2", 1, 1), ("rdl3", 1, 1)]
R_UPPER = [("ctw", 3, 1), ("rap", 3, 1)]
L_ROUTER = [("lcr", 2, 10), ("lcv", 2, 3), ("lan", 2, 2), ("lat", 2, 3)]
L_LOWER = [("lcr", 1, 7), ("lcv", 1, 2), ("lan", 1, 2)]
L_UPPER = [("lcr", 3, 5), ("lcv", 3, 2), ("lan", 3, 1), ("lat", 3, 1)]
W_TASKS = [("bas", 1, 3), ("bas", 2, 4), ("bas", 3, 3), ("eml", 2, 1), ("dsc", 2, 1)]
S_TASKS = [("lrp", 2, 1), ("int", 2, 1)]

SET_SIZE = {t[0]: t[3] for _, _, ts in SECTIONS for t in ts}
POINTS = {"ctw": 10}


def items(recipe):
    return sum(n * (SET_SIZE[t] or 1) * POINTS.get(t, 1) for t, _, n in recipe)


ADAPTIVE = {
    "reading": {"title": "Reading", "router": R_ROUTER, "lower": R_LOWER, "upper": R_UPPER,
                "minutes": {"router": 20, "lower": 9, "upper": 9}},
    "listening": {"title": "Listening", "router": L_ROUTER, "lower": L_LOWER, "upper": L_UPPER,
                  "minutes": {"router": 18, "lower": 7, "upper": 11}},
}
for key, m in ADAPTIVE.items():
    m["items"] = {s: items(m[s]) for s in ("router", "lower", "upper")}
    assert m["items"]["lower"] == m["items"]["upper"], key
assert ADAPTIVE["reading"]["items"]["router"] + ADAPTIVE["reading"]["items"]["upper"] == 50
assert ADAPTIVE["listening"]["items"]["router"] + ADAPTIVE["listening"]["items"]["upper"] == 47
assert items(W_TASKS) == 12 and items(S_TASKS) == 11

targets = collections.Counter()  # (topic, level) -> questions (or sets) in the test pool
for m in ADAPTIVE.values():
    for stage in ("router", "lower", "upper"):
        for t, level, n in m[stage]:
            targets[(t, level)] += n * PAPERS
for t, level, n in W_TASKS + S_TASKS:
    targets[(t, level)] += n * PAPERS

doc = {
    "papers": PAPERS,
    "sections": [
        {"key": k, "title": title, "topics": [
            {"key": tk, "prefix": p, "title": tt, "set_size": size, "practice": prac, "scope": scope,
             "test": {f"L{lv}": n for (t, lv), n in sorted(targets.items()) if t == tk},
             "test_unit": "sets" if size else "questions"}
            for tk, p, tt, size, prac, scope in topics
        ]} for k, title, topics in SECTIONS
    ],
    "adaptive": {k: {"title": m["title"], "minutes": m["minutes"], "items": m["items"],
                     "stages": {s: [{"topic": t, "level": lv, "count": n} for t, lv, n in m[s]]
                                for s in ("router", "lower", "upper")}}
                 for k, m in ADAPTIVE.items()},
    # Router points needed for the upper module (60 %).
    "route_upper_at": {k: round(m["items"]["router"] * 0.6) for k, m in ADAPTIVE.items()},
    "writing": {"tasks": [{"topic": t, "level": lv, "count": n} for t, lv, n in W_TASKS],
                "minutes": {"bas": 6, "eml": 7, "dsc": 10}},
    "speaking": {"tasks": [{"topic": t, "level": lv, "count": n} for t, lv, n in S_TASKS],
                 "seconds": {"lrp": 12, "int": 45}},
}
prefixes = [t[1] for *_, ts in SECTIONS for t in ts]
assert len(prefixes) == len(set(prefixes)), "duplicate prefix"
(ROOT / "content/blueprint.json").write_text(json.dumps(doc, indent=1) + "\n")
for k, m in ADAPTIVE.items():
    print(k, m["items"], "upper at", doc["route_upper_at"][k])
for (t, lv), n in sorted(targets.items()):
    print(f"  {t:5} L{lv}: {n}{' sets' if SET_SIZE[t] else ''}")
