---
name: Refine
description: "Use when the user asks to clean up, sharpen, split, or otherwise refine one node or a small set of nodes, including title, description, source, and likely edges."
---

# Refine

## Goal

Turn nodes into atomic, high-signal units of context. Inspect first, propose specific improvements, then apply only after the user confirms.

## Default Posture

- Refinement is proposal-first. Show the suggested title, description, source handling, and edge changes before writing unless the user explicitly says to apply immediately.
- Bias toward atomic units of context: one clear idea, source, person, decision, project, or claim per node.
- If a node contains multiple durable ideas, recommend a split, but do not push so hard that cleanup turns into friction.

## Tool Path

Load the target node before you suggest changes:

- internal / standalone:
  - `getNodesById`
- packaged MCP:
  - `rah_get_nodes`

Gather surrounding graph context when needed:

- internal / standalone:
  - `queryNodes`
  - `retrieveQueryContext`
  - `queryEdge`
- packaged MCP:
  - `rah_search_nodes`
  - `rah_retrieve_query_context`
  - `rah_query_edges`

Apply approved changes with the matching write tools:

- internal / standalone:
  - `updateNode`
  - `createNode`
  - `createEdge`
  - `updateEdge`
- packaged MCP:
  - `rah_update_node`
  - `rah_add_node`
  - `rah_create_edge`
  - `rah_update_edge`

## Workflow

1. Load the node and inspect `title`, `description`, `source`, `link`, metadata, and current edges.
2. Decide whether the node is already atomic or whether it is carrying multiple durable ideas that should probably be split.
3. Tighten the title so it is specific and scannable. Prefer explicit subject + claim/theme over vague labels.
4. Rewrite the description in natural prose so it clearly says:
   - what this thing is
   - why it belongs in the graph
   - what its current status or relevance is when known
5. Handle `source` carefully:
   - if it is the user's own idea, preserve their wording as much as possible with only minimal cleanup
   - if it is an external artifact, keep `source` as the canonical raw text, not an assistant summary
   - if the source is bloated because it really contains multiple ideas, suggest splitting it into multiple nodes
6. Search for nearby graph context when it would improve the refinement:
   - likely duplicate or sibling nodes
   - projects, beliefs, or themes that explain why this node belongs
   - existing edges that are weak or missing
7. Suggest 1-3 high-signal edges when obvious. Use search and edge-query tools to find the right targets before proposing them.
8. Return a compact proposal that includes:
   - suggested title
   - suggested description
   - suggested source handling or edited source excerpt
   - suggested split nodes if needed
   - suggested edges with explicit explanations
9. Wait for the user's yes/no or edits.
10. After approval, apply the node updates first, then create or update the approved edges.
11. Report exactly what changed and what still needs user judgment.

## Batch Mode

For a small set of nodes, refine each node individually. Do not reuse boilerplate descriptions across unrelated nodes.

## Quality Bar

- Titles are explicit enough to scan quickly.
- Descriptions stand on their own and make the node legible.
- `source` preserves provenance and the user's real wording.
- Edge suggestions explain why the relationship exists.
- The user can approve or reject the proposal quickly.

## Do Not

- Silently rewrite a node and move on.
- Collapse a user-authored idea into a one-line assistant summary.
- Force a split when a simple cleanup is enough.
- Create edges before the user confirms them.
- Use vague description language like "is about", "explores", or "discusses".
