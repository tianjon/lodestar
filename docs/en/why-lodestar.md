# Why Lodestar Exists

## The real problem is orientation decay, not memory loss

An autoregressive coding agent is recency-weighted by construction: every new message pulls
hardest on the next token. Over a long session that pull compounds. The agent quietly starts
optimizing for the *latest* instruction instead of the goal that set the session in motion, and
the original objective decays turn by turn.

Four mechanics in real agent harnesses sever the thread again and again:

- **Context compaction** summarizes the conversation lossily and continues from the summary.
- **A fresh session** starts with almost empty context — only static files are auto-loaded.
- **Task skills** (TDD, debugging, review) impose their own procedure and can pull focus.
- **Subagents** run with fresh context and do not inherit what the parent was steering toward.

The dangerous failure mode is not forgetting a fact. It is the **silent slide**: the agent stays
fluent, confident, and busy while aimed at the wrong target. Nobody notices until a large amount
of work points the wrong way.

## This is a control problem, not a search problem

A recall database or vector store retrieves *facts*. Orientation is different: it is holding
*what we are trying to do right now, and whether this next action serves it*. You cannot search
your way back onto course; you need a setpoint to steer by. Lodestar is that setpoint, not another
index.

## What Lodestar adds

A small, durable, project-local **anchor** that survives the things that erase a conversation:

- the current **mode** (explore / clarify / decide / execute / review);
- the one active **goal**, in a single sentence;
- an observable **done-when**;
- explicit **boundaries** (what is out of scope this phase);
- the project's **domain language**;
- open **gaps**, with evidence and confidence;
- **decisions**, with alternatives and rationale;
- the **next action**.

## The stance: honest, not deferential

Lodestar records the user's requirement *at the source*, then compares it honestly against
current practice — it neither flatters the user nor bows to the literature. When the requirement
and practice conflict, it is allowed to challenge the goal itself, **with evidence**, and to
surface a third path that transcends both. The principle is to break through experience limits
rather than optimize blindly inside them.

## What it is not

Lodestar is not a general recall database, not vector search, not a replacement for task skills,
and not an attempt to remember every sentence. It preserves orientation, not transcript.

## Honest scope

The value is real but conditional. It is highest on long, multi-session, cross-harness work where
intent genuinely decays. It is overhead on a single short session with an already-clear goal. And
a half-maintained anchor is worse than none, because a stale goal misleads with the authority of
a written record — which is exactly why the maintenance discipline is load-bearing, not optional.

## Desired state

When Lodestar is working, a resumed session can say, in one breath:

> We are working on this goal; success means this; these things are out of scope; the current gap
> is this; the next useful action is this.
