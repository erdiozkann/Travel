# AI Agent Rules (Global)

## Purpose
This document defines how AI agents must behave.

---

## Authority Split
- Opus 4.5: Architecture, scope, rules
- Gemini 3 Pro High: Implementation only

Gemini MUST NOT:
- Add screens
- Change flow
- Invent features
- Modify scope

---

## Mobile Constraints
- All AI work is async
- No blocking calls on mobile
- Outputs must be compact JSON
- Cache results whenever possible

---

## Output Rules
- Structured
- Explicit
- No assumptions
- Confidence level included

---

## Escalation Rule
If an agent is unsure:
- Ask
- Do not guess