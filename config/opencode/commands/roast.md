---
description: Roast an idea through 4 agents (Believer, Skeptic, Investor, Judge) and get one verdict
---

# ROAST — Idea Roast Council

The user wants their idea roasted. Keyword in comments: **ROAST**.

**Submitted idea:**

$ARGUMENTS

Run the council by spawning 4 subagents IN ORDER using the `task` tool. Each agent needs the prior outputs to do their job — do NOT run them in parallel. Each step's input includes everything from previous steps.

## Sequence

### 1. The Believer
Spawn the `creyente` subagent. Pass it only the user's idea verbatim. Capture its full response.

### 2. The Skeptic
Spawn the `esceptico` subagent. Pass it:
- The user's idea
- The Believer's full response

Capture its full response.

### 3. The Investor
Spawn the `inversionista` subagent. Pass it:
- The user's idea
- The Believer's full response
- The Skeptic's full response

Capture its full response.

### 4. The Judge
Spawn the `juez` subagent. Pass it:
- The user's idea
- The Believer's full response
- The Skeptic's full response
- The Investor's full response

Capture its verdict.

## Final output

Present a clean council transcript to the user in this exact shape, tight prose, no filler between sections:

```
## THE IDEA
<echo the idea in one line>

## THE BELIEVER SAYS
<creyente's full output>

## THE SKEPTIC SAYS
<esceptico's full output>

## THE INVESTOR SAYS
<inversionista's full output>

## THE JUDGE RULES
<juez's full verdict — verdict, risk, 10-minute test, and the fix if FIX FIRST>
```

End with one short line: `Run /roast again with a new idea, or come back tomorrow — the council remembers.`