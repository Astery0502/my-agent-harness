# Trial T8: Step D Discipline Under Subtle Framing Trap

## Target behavior

When step B generates candidate routes that all appear individually reasonable,
step D should still find a substantive critique — not a shallow "all look fine"
pass-through. The design tension exists in the request itself, not in any one
obviously-wrong route.

This trial directly targets the open question: *does D discipline hold when B
generates routes that all look reasonable?*

## Input prompt

```
/plan Add a --watch mode to sync.sh that monitors source files and re-syncs automatically when they change
```

## How to run

Run exactly as written in a Claude Code session where the harness is installed.

## What to observe

- [ ] Step B generates multiple candidate routes (e.g., FSEvents/inotify native
      watching, polling loop, git post-commit hook, OS service). Each should look
      independently reasonable.
- [ ] Step D does NOT simply validate all routes and pick the most practical one.
      A shallow D looks like: "Route 1 is best because it uses native OS events."
- [ ] Step D surfaces the design tension in the request itself: watch mode creates
      ambient, continuous sync that can deploy mid-edit changes. The current sync
      model is intentional and atomic — deploys happen when the user decides to
      deploy, not reactively on every file save.
- [ ] Step D identifies the consequence: a partially-written source file, a
      mid-refactor state, or a feature branch being worked on could all trigger
      an unintended live deploy.
- [ ] The surviving route (if any) either: (a) constrains watch mode to staging
      only, (b) requires a debounce + explicit confirmation, or (c) reframes the
      ask as "faster feedback loop" (e.g., `--dry-run --watch`) rather than
      ambient live deploys.

## Pass condition

Step D produces a substantive challenge grounded in the sync model (intentional
vs. reactive), not a surface-level comparison of implementation approaches. The
final task chain does not implement ambient auto-deploy on file change without
constraints.

## Notes

The failure mode: D reads as a continuation of B — comparing polling vs. native
watching, discussing debounce intervals, selecting the technically best
implementation — without ever questioning whether ambient sync is the right model
at all. This would confirm D discipline collapses when no route is obviously wrong.

This prompt was chosen because all four typical routes (native watch, polling,
git hook, OS service) are reasonable engineering choices, and none is immediately
suspicious. The flaw is upstream of the routes.
