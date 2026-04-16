# General Rules

- Clarify ambiguity before acting; do not guess at unclear requirements.
- State only material assumptions, and only when they affect the chosen approach.
- Choose the simplest interpretation and the smallest solution that satisfies the request.
- Keep changes strictly scoped to the task; do not refactor adjacent code without need.
- Do not introduce abstractions, options, or fallbacks that the task does not require.
- Remove only code or imports made unnecessary by your own change.
- Verify with the smallest meaningful check that covers the changed path.
- Do not claim completion without direct verification; if verification was limited, say so plainly.
- Validate at real boundaries such as user input or external systems, not inside trusted internal flows.
- Prefer reversible actions, and require user approval before bypassing checks or taking risky external actions.
