---
name: Create Skill
description: "Use when the user explicitly wants to create, rewrite, or remove a skill, or when they describe a repeatable workflow that should probably become a skill."
---

# Create Skill

## Goal

Create small, focused skills with clear triggers, explicit tool guidance, and a clean execution contract. Suggest a skill when the same workflow is likely to recur.

## Use This When

- The user asks to create, rewrite, merge, or remove a skill.
- The user keeps describing a repeatable workflow that should become reusable doctrine.
- An existing skill is too vague, too broad, or overlaps with another skill enough that it should be reworked.

At that point, it is appropriate to suggest creating or tightening a skill.

## Design Standard

1. One job per skill.
2. Put the trigger directly into `description`.
3. Keep the body procedural, short, and high-signal.
4. Name the tool path only when tool choice materially matters.
5. Make proposal/apply boundaries explicit.
6. Include guardrails and failure modes.

## Recommended Structure

- `name`
- `description`
- one short goal section
- trigger / use cases
- step-by-step workflow
- tool pointers when relevant
- quality bar
- do-not list

## Tool Pointers

When tool choice matters, point to the matching family for the current surface instead of pretending every agent has the same names:

- Internal / standalone skill tools:
  - `listSkills`
  - `readSkill`
  - `writeSkill`
  - `deleteSkill`
- Packaged MCP skill tools:
  - `rah_list_skills`
  - `rah_read_skill`
  - `rah_write_skill`
  - `rah_delete_skill`
- Graph lookup tools for surrounding context:
  - internal / standalone: `queryNodes`, `retrieveQueryContext`, `getNodesById`, `queryEdge`
  - packaged MCP: `rah_search_nodes`, `rah_retrieve_query_context`, `rah_get_nodes`, `rah_query_edges`

Only mention the tools the skill genuinely depends on.

## Workflow

1. Decide whether this actually needs a skill. If the existing tool descriptions and core prompt contract are already enough, do not create one.
2. Identify the trigger, the repeatable user intent, and the expected output.
3. Check overlap with existing skills before adding another file.
4. Draft the `description` so another agent can trigger the skill from natural language without guessing.
5. Draft the shortest body that still makes the workflow, tool path, and failure modes explicit.
6. If tool choice differs by surface, include surface-aware tool pointers.
7. Save or rewrite the skill only after the user confirms the intended scope and wording.
8. If the new skill absorbs older skills, say which ones should be removed.

## Quality Bar

- Another agent can execute it without guessing.
- The description is action-oriented and triggerable.
- The procedure is sequential and concrete.
- The skill is focused enough that it will be called for a real workflow, not a vague topic area.
- It does not duplicate doctrine that should live in tool descriptions instead.

## Consolidation Rule

If two skills share the same trigger, tool path, and output contract, merge them.

## Do Not

- Create broad catch-all skills.
- Hide the trigger in the body while leaving the description generic.
- List every tool in the system.
- Split one workflow into multiple skills just because the old file count was higher.
- Keep a legacy skill only because it already exists.
