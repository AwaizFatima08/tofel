# Lessons, guide articles and vocabulary

## Lessons: `content/lessons/<topic>.json` (one per blueprint topic, shown before that topic's practice)
```json
{"section":"reading","topic":"ctw","title":"Complete the Words","minutes":10,"lines":["..."]}
```
## Guide articles: `content/guide/<nn>-<slug>.json` (the Guide tab, grouped by `group`, sorted by file name)
```json
{"id":"exam-format","group":"The exam","title":"TOEFL iBT format at a glance","lines":["..."]}
```
## Line syntax (lessons and guide)
| Line starts with | Shows as |
|---|---|
| `## ` | heading |
| `- ` | bullet |
| `> ` | example box (worked example, sample sentence); consecutive `> ` lines form one box |
| `! ` | tip box (a trick or a trap to avoid) |
| anything else | paragraph |
No Markdown tables, no bold/italic markers.
A lesson teaches the task: what is on screen and the timing, what is being tested, a step-by-step method, worked
examples (an example item with the reasoning), the common traps, and the skills to build between mocks (vocabulary,
grammar points, listening habits). 900-1600 words.

## Vocabulary: `content/vocab/<letters>.json` (flashcards of high-frequency academic words)
```json
[{"w":"allocate","p":"verb","d":"to give a share of something for a purpose","e":"The college allocated more money to the library this year.","s":["assign","distribute"]}]
```
Definitions and example sentences are original. `s`: 1-3 synonyms (useful for vocabulary-in-context questions).
