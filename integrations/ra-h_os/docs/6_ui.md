# UI Surfaces

## Workspace Model

RA-H OS follows the current pane model:
- explicit `1 / 2 / 3` visible panes
- chat anchored to the right edge of the active workspace
- node tabs only in node panes
- singleton non-node panes

## Main Views

- `Feed` for recent and sortable node browsing
- `Map` for graph structure
- `Table` for dense inspection
- `Skills` for editable agent instructions
- `Chat` for agent-driven graph work

## UI Contract After The Migration

- The app no longer exposes a dimensions pane.
- Feed and table filtering are not dimension-based.
- Persisted pane layout should only hydrate valid pane types: `views`, `node`, `map`, `table`, `skills`.
- The app does not expose a separate organizing pane or category filter surface.

## Focus And Capture

- Capture must succeed without any category or context assignment.
- Focus surfaces should emphasize title, description, source, metadata, and edges.
- Node cards and focus views should not depend on category labels for meaning.
