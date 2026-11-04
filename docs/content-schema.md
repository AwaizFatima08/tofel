# Question bank format

Source files: `content/bank/<section>/<topic>.jsonl` (a topic may split: `<topic>-2.jsonl`, `<topic>-3.jsonl`).
One JSON object per line, UTF-8. Sections, topics, id prefixes, set sizes and targets are in `content/blueprint.json`
(`python3 tool/make_blueprint.py` prints the test targets per topic and level).

## Common fields (every question)
| Field | Rule |
|---|---|
| `id` | `<prefix>-t0001` (mock pool) or `<prefix>-p0001` (practice pool). Never reuse an item across pools |
| `pool` | `test` or `practice` |
| `level` | 1 easy (CEFR A2-B1), 2 medium (B1-B2), 3 hard (C1) |
| `type` | see the table below |
| `stem` | the question text (what the test taker reads) |
| `explanation` | teaches the answer: where the evidence is, then why the most tempting wrong choice is wrong. 2-5 sentences. For writing and speaking tasks, a model response (see below) |
| `set` | id of the set line (text, script or scenario) the question belongs to; required in set topics |

## Question types
| `type` | Topic | Fields |
|---|---|---|
| `ctw` Complete the Words | reading ctw | `stem`: the paragraph. Exactly 10 damaged words are written `[[shown|missing]]`, e.g. `[[dev|elop]]`; `shown` is the first half of the word, rounded down (`len(word)//2` letters; "develop" → "dev" + "elop"), `missing` the rest. The first sentence has no gaps. Only whole words of 2+ letters; never proper nouns, numbers or words with apostrophes or hyphens. The `explanation` covers each word in one short clause ("1 develop: verb after 'to'; ...") |
| `mc` multiple choice | reading rdl2, rdl3, rap; listening lcv, lan, lat | `options`: 4 strings, `answer`: `[i]` |
| `lcr` choose a response | listening lcr | `say`: the spoken line, `"W: ..."` or `"M: ..."` (woman or man speaking); `stem`: "Choose the best response."; `options`: 4 written replies, `answer`: `[i]` |
| `bas` build a sentence | writing bas | `stem`: person A's line, `"W: ..."` or `"M: ..."`. `chunks`: the reply's chunks IN THE CORRECT ORDER (4-7 chunks, lower case unless a proper noun or "I"), `prefix`: optional words shown before the chunks (may be ""), `suffix`: the end punctuation (`"."` or `"?"`), optionally with fixed words before it (`"tomorrow?"`). `extra`: optional single distractor chunk that does not belong. `alt`: optional list of other correct orders as index lists into `chunks` (only when another order is fully natural). The reply = prefix + chunks + suffix, joined with spaces. No `options`/`answer` |
| `email` | writing eml | `stem`: the situation; `bullets`: the 3 things to do; `task`: "Write an email to ... In your email, do the following:"; `explanation`: a model email (110-160 words, `\n` between greeting, paragraphs, closing); `points`: 3-5 strings, what a strong response does |
| `disc` | writing dsc | `stem`: the professor's post (question, 60-110 words), `prof`: "Dr. Gupta", `posts`: `[{"name":"Claire","text":"..."},{"name":"Andrew","text":"..."}]` (40-80 words each, different views); `task`: the standard instruction; `explanation`: a model contribution (120-170 words); `points`: 3-5 strings |
| `repeat` | speaking lrp | `stem`: the sentence to repeat exactly (4-22 words); `explanation`: one or two sentences on what to watch (linking, stress, a tricky word). No options |
| `interview` | speaking int | `stem`: the interviewer's question; `explanation`: a model answer that fills about 45 seconds (90-120 words, natural spoken style); `points`: 3-4 strings, what a strong answer does |

## Sets
A set line comes before its questions in the same file:
```json
{"type":"set","id":"ra-ts001","pool":"test","level":2,"title":"The Origins of Coral Reefs","text":"passage ..."}
```
- Set ids: `<prefix>-ts001` (test) or `<prefix>-ps001` (practice). Topics with `set_size` > 0 put every question
  in a set of exactly that many questions; all questions of a set share the set's `pool` and `level`.
- Reading sets: `text` is the text (paragraphs separated by `\n\n`). Daily-life texts may add `kind` (`email`,
  `notice`, `text messages`, `menu`, `schedule`, `post`, `flyer`, `web page`, `instructions`) and for text messages
  use one line per message `Name (10:14): message`.
- Listening sets (`lcv`, `lan`, `lat`): `text` is the one-line situation shown on screen ("Listen to a conversation
  between a student and a librarian."), `script`: the spoken lines in order, each `"W: ..."`, `"M: ..."` (woman, man)
  in conversations; announcements and talks use one speaker letter for every line. A conversation may name speakers
  in `roles`: `{"W": "student", "M": "librarian"}`. The script is read aloud by the phone's text-to-speech voices, so
  write it to be heard: spoken style, contractions, no brackets, no stage directions, numbers as people say them
  where it matters ("two thirty", "fifteen percent").
- Speaking sets: `lrp` `title` (e.g. "Museum guide training") and `text`: the scenario shown and read aloud
  (2-3 sentences), `voice`: `"W"` or `"M"`. `int`: `title`, `text` the scenario, `voice`.

## Examples
```json
{"id":"rc-t0001","pool":"test","level":2,"type":"ctw","stem":"Bees are important pollinators. They [[mo|ve]] pollen ...","explanation":"1 move: ..."}
{"id":"lr-t0001","pool":"test","level":1,"type":"lcr","say":"W: Do you know when the library closes tonight?","stem":"Choose the best response.","options":["At nine, I think.","Yes, I read it last night.","It's on the second floor.","No, I closed it."],"answer":[0],"explanation":"..."}
{"id":"wb-t0001","pool":"test","level":1,"type":"bas","stem":"M: Where did you find that great jacket?","prefix":"I","chunks":["bought it","at the market","near","my office"],"suffix":".","explanation":"..."}
```
