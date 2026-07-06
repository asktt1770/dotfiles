---
name: eli5
description: Explain any topic, code, architecture, or design decision so a non-engineer or an elementary-school child could understand it — covering both the structure and WHY it ended up this way. Use when the user says "eli5", "explain like I'm 5", "小学生でもわかるように", "構造と理由を教えて", "なんでこうなってるの", "explain simply", or "dumb it down", or asks why something is designed the way it is.
---

# Explain Like I'm 5 (ELI5)

Explain a topic so a curious 10-year-old who is NOT an engineer could follow it —
covering both _how it is structured_ and _why it ended up this way_. Respond in
the user's language (default: match the language the user wrote in).

## Step 1: Get the topic

Take the topic from the user. It can be:

- A programming concept (recursion, dependency injection, …)
- A piece of code, an error message, or a stack trace
- An architecture / system design, or a design decision ("why is it split like this?")
- Anything non-technical

If the topic points at a file or code, **read it first**. If nothing is given,
ask what to explain and stop.

## Step 2: Lead with WHY

Before any mechanics, answer in one or two plain sentences:

- **Why does this exist?** What problem was someone trying to solve?
- **Why is it shaped this way?** What would go wrong if it were built the obvious/naive way?

This is the part the user cares about most. Never skip it.

## Step 3: Explain with the ADEPT pattern

1. **Core idea** — one jargon-free sentence. If the reader stops here, they still learned something.
2. **Analogy** — map it to everyday life (toys, a kitchen, a library, LEGO, a playground). Pick an analogy that matches the real _mechanics_, not just the surface, and say out loud where the analogy breaks down.
3. **Diagram** — if there is structure or flow, add a short ASCII diagram (≤10 lines). Skip it for purely abstract ideas where a diagram would not help.
4. **Example** — one concrete, minimal example. For code, 3–5 real lines with a one-line comment.
5. **Summary** — one sentence the child could repeat back: "So [analogy] is like [real thing] because …"

## Step 4: Close so it sticks

- **なぜ大事か / Why it matters** — one line of real-world significance.
- **鵜呑みにしない点 / Caveats** — where the simple picture would mislead if taken too literally.
- **覚えるなら3つ / Remember 3 things** — three short takeaways.

## Rules

- Short sentences. Active voice. Simple words.
- **Simplify the language, never the facts.** A plausible-sounding wrong mechanism is worse than honest jargon. If you are unsure how something works, verify it before stating it.
- No condescending words: avoid "simply", "just", "obviously", "clearly", "単に", "〜するだけ".
- Build up layer by layer: start with the simplest piece and add one step at a time.
- Keep each section to at most 2–3 short paragraphs. Brevity wins.

## Step 5: Offer to go deeper

End with an offer such as: "どこかもっと深掘りする? 別の例も出せるよ / Want me to go deeper on any part, or see more examples?"
