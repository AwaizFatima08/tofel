# Writer brief: Prep Simulator for TOEFL

You write original practice material for a HomiLabs Android app that simulates the TOEFL iBT in its current form
(the January 2026 update: adaptive Reading and Listening, 1-6 band scores). Test takers worldwide, many in South
Asia, use it to prepare for university study abroad. Accuracy matters more than speed: one wrong key destroys trust
in the app.

## Format
Read `docs/content-schema.md` and `content/blueprint.json` (your topic's prefix, set size, scope and targets).
Write only the files named in your task. Write in chunks of at most 10 items (or 5 sets) per tool call, appending
with Bash heredocs (`cat >> file <<'EOF'`), and run `python3 tool/validate.py --files <your files>` after each
chunk; fix every ERROR. A file is finished only when it has 0 errors and no WARN. Use the id ranges your task
gives you, so two writers never collide. Keep one JSON object per line.

## The test (what each task looks like)
- Reading: Complete the Words (a paragraph with 10 half-words to finish), Read in Daily Life (short everyday texts
  with 2-3 questions), Read an Academic Passage (about 200 words, 5 questions). Router module, then an easier or
  harder second module.
- Listening: Listen and Choose a Response (one line, four written replies), conversations, announcements, academic
  talks. Every recording is heard ONCE; questions appear after it. The app reads scripts with text-to-speech.
- Writing: Build a Sentence (order word chunks into a reply), Write an Email (7 min), Write for an Academic
  Discussion (10 min).
- Speaking: Listen and Repeat (7 sentences), Take an Interview (4 questions, 45 seconds each).

## Difficulty
- Level 1 (CEFR A2-B1): everyday vocabulary, short sentences, the answer is stated plainly.
- Level 2 (B1-B2): some academic vocabulary, a paraphrase between text and answer, one inference step, a tempting
  wrong choice that repeats words from the text.
- Level 3 (C1): dense academic language, inference and purpose questions, idioms and indirect meaning, wrong
  choices that are partly true or reverse a relationship.

## Questions (Reading and Listening)
- Four options, exactly one correct. Each wrong option is wrong for a reason you can point to in the text or
  script: not mentioned, reversed, too extreme, true but does not answer the question, mixes two details.
- Paraphrase: the correct option should not copy a long phrase from the text; wrong options often DO copy words.
- Spread the correct letter evenly over A-D, and do not make the correct option the longest one.
- Question stems as on the TOEFL: "What is the main purpose of the email?", "According to the passage, ...",
  "The word 'X' in the passage is closest in meaning to", "What can be inferred about ...?", "Why does the
  professor mention ...?", "What will the woman probably do next?", "What does the man imply when he says ...?"
- Listening: questions must be answerable from what was heard once; do not test tiny details like exact minutes
  unless the script stresses them. At least one question per academic talk is about the main idea or the purpose of
  an example. Conversations: one gist question and one detail, attitude or next-action question.
- Listen and Choose a Response: the correct reply often answers indirectly ("Q: Want to grab lunch? A: I've got a
  lab until two."). Wrong replies: wrong tense or person, a word that sounds like one in the line, a reply to a
  different question, a socially odd response. Mix questions (wh-, yes/no, tag), requests, offers, complaints,
  news, opinions.

## Writing and Speaking tasks
- Build a Sentence: realistic campus or daily-life exchanges. The reply is one natural sentence (7-16 words in all).
  Test word order: indirect questions ("Do you know where the lab is?"), question word order, auxiliaries, adverbs
  of frequency, relative clauses, passive, prepositional phrases, "not only ... but also". About a third of items get
  one `extra` distractor chunk (a wrong auxiliary, a duplicate preposition, a wrong word form). There must be one
  correct order (add `alt` only if a second order is equally natural). The explanation names the grammar point and
  gives the full sentence.
- Write an Email: a realistic situation (a class, a club, a landlord, a company, a professor, a library); the three
  bullets ask for different moves (explain a problem, ask for something, suggest a solution, give details). The
  model email is natural, polite, and does all three things; tone matches the reader.
- Academic Discussion: the professor's prompt gives background then a clear question with two or more possible
  answers; the two students take different positions with a reason each. The model contribution takes a position,
  adds a NEW reason or example (not repeating the students), and refers to one student by name.
- Listen and Repeat: sentences belong to the scenario (instructions a manager or guide would say), grow from about
  4-6 words to 15-22 words, and include a mix of structures (imperatives, relative clauses, time clauses, numbers,
  names of places). Natural spoken English.
- Interview: four questions that move from personal experience to opinion, comparison and prediction about one
  topic. Model answers sound spoken (contractions, "I'd say", "for example"), give a clear answer in the first
  sentence and then a reason and an example, about 100 words.

## Language and topics
- American spelling, as on the TOEFL. International names (Priya, Mateo, Chen, Amara, Olga, Kwame, Sofia, Hamza,
  Aisha, Lucas, Yuki). Universities, cities and companies are fictional or generic ("the university", "Lakeside
  College").
- Academic topics across biology, astronomy, geology, environmental science, history, archaeology, art history,
  music, linguistics, psychology, sociology, economics, business, technology. Neutral and respectful; no current
  politics, religion, war, disasters or tragedy; nothing culturally offensive.
- Facts in academic passages and talks must be true or clearly general (no invented "facts" presented as real
  research findings with fake names and dates). If unsure about a fact, write it more generally.

## Explanations
Teach in 2-5 sentences: where the answer is (quote the key words), how the correct option paraphrases it, and why
the most tempting wrong option is wrong. Do not start with "The answer is".

## Variety and originality
- No near-duplicates within or across files: read your files before each chunk. Vary settings, names, text types,
  question shapes and which option is correct.
- Original work only. Never copy or closely reword ETS material (official practice tests, TOEFL TestReady, sample
  questions), prep books or websites.

## Boundaries
Only write the files in your task, plus your scratch folder. Do not edit tools, the blueprint, the app or other
topics. Do not run git. Final reply at most 6 lines: files, counts by pool and level, validator result, any items you
are unsure about (by id).
