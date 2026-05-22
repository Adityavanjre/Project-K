import type { Node as DbNode, Edge as DbEdge } from '@/types/database';
import type { Node as RFNode, Edge as RFEdge } from '@xyflow/react';

export type MapViewMode = 'overview' | 'focused';
export type MapNodeRole = 'overview' | 'selected' | 'first-hop' | 'second-hop';

export interface FocusedGraph {
  selectedNodeId: number;
  firstHopIds: number[];
  secondHopIds: number[];
  nodeIds: Set<number>;
}

export interface RahNodeData {
  label: string;
  edgeCount: number;
  dbNode: DbNode;
  role: MapNodeRole;
  connectionCount: number;
  prominence: number;
  [key: string]: unknown;
}

export const NODE_LIMIT = 200;
export const FIRST_HOP_LIMIT = 10;
export const SECOND_HOP_LIMIT = 18;

type Point = { x: number; y: number };

export function buildAdjacency(dbEdges: DbEdge[]): Map<number, Set<number>> {
  const adjacency = new Map<number, Set<number>>();

  for (const edge of dbEdges) {
    if (!adjacency.has(edge.from_node_id)) adjacency.set(edge.from_node_id, new Set());
    if (!adjacency.has(edge.to_node_id)) adjacency.set(edge.to_node_id, new Set());
    adjacency.get(edge.from_node_id)?.add(edge.to_node_id);
    adjacency.get(edge.to_node_id)?.add(edge.from_node_id);
  }

  return adjacency;
}

export function buildDegreeMap(dbEdges: DbEdge[]): Map<number, number> {
  const adjacency = buildAdjacency(dbEdges);
  const degreeMap = new Map<number, number>();

  adjacency.forEach((neighbours, nodeId) => {
    degreeMap.set(nodeId, neighbours.size);
  });

  return degreeMap;
}

export function buildFocusedGraph(
  selectedNodeId: number,
  adjacency: Map<number, Set<number>>,
  degreeMap: Map<number, number>,
): FocusedGraph {
  const directNeighbours = [...(adjacency.get(selectedNodeId) ?? [])]
    .sort((a, b) => {
      const degreeDiff = (degreeMap.get(b) ?? 0) - (degreeMap.get(a) ?? 0);
      return degreeDiff !== 0 ? degreeDiff : a - b;
    })
    .slice(0, FIRST_HOP_LIMIT);

  const firstHopSet = new Set(directNeighbours);
  const secondHopScores = new Map<number, { sharedCount: number; degree: number }>();

  for (const firstHopId of directNeighbours) {
    for (const candidateId of adjacency.get(firstHopId) ?? []) {
      if (candidateId === selectedNodeId || firstHopSet.has(candidateId)) continue;

      const existing = secondHopScores.get(candidateId) ?? {
        sharedCount: 0,
        degree: degreeMap.get(candidateId) ?? 0,
      };

      existing.sharedCount += 1;
      secondHopScores.set(candidateId, existing);
    }
  }

  const secondHopIds = [...secondHopScores.entries()]
    .sort((a, b) => {
      const sharedDiff = b[1].sharedCount - a[1].sharedCount;
      if (sharedDiff !== 0) return sharedDiff;

      const degreeDiff = b[1].degree - a[1].degree;
      return degreeDiff !== 0 ? degreeDiff : a[0] - b[0];
    })
    .slice(0, SECOND_HOP_LIMIT)
    .map(([nodeId]) => nodeId);

  return {
    selectedNodeId,
    firstHopIds: directNeighbours,
    secondHopIds,
    nodeIds: new Set([selectedNodeId, ...directNeighbours, ...secondHopIds]),
  };
}

function buildOverviewLayout(
  nodes: DbNode[],
  adjacency: Map<number, Set<number>>,
  degreeMap: Map<number, number>,
  centerX: number,
  centerY: number,
): Map<string, Point> {
  const positions = new Map<string, Point>();
  const sortNodesByWeight = (left: DbNode, right: DbNode) => {
    const degreeDiff = (degreeMap.get(right.id) ?? right.edge_count ?? 0) - (degreeMap.get(left.id) ?? left.edge_count ?? 0);
    return degreeDiff !== 0 ? degreeDiff : left.id - right.id;
  };

  const sortedNodes = [...nodes].sort(sortNodesByWeight);
  if (sortedNodes.length === 0) {
    return positions;
  }

  const maxDegree = Math.max(...sortedNodes.map((node) => degreeMap.get(node.id) ?? node.edge_count ?? 0), 1);
  const minRadius = 24;
  const maxRadius = Math.max(280, Math.min(520, 140 + sortedNodes.length * 2.2));
  const nodeIds = sortedNodes.map((node) => node.id);
  const state = new Map<number, { x: number; y: number; vx: number; vy: number; targetRadius: number; mass: number }>();

  sortedNodes.forEach((node, index) => {
    const degree = degreeMap.get(node.id) ?? node.edge_count ?? 0;
    const centrality = degree / maxDegree;
    const targetRadius = minRadius + (1 - centrality) * (maxRadius - minRadius);
    const angle = (index / Math.max(sortedNodes.length, 1)) * Math.PI * 2 - Math.PI / 2;

    state.set(node.id, {
      x: centerX + Math.cos(angle) * targetRadius,
      y: centerY + Math.sin(angle) * targetRadius,
      vx: 0,
      vy: 0,
      targetRadius,
      mass: 1 + centrality * 1.8,
    });
  });

  const iterations = 140;
  for (let step = 0; step < iterations; step += 1) {
    const alpha = 1 - step / iterations;

    for (let i = 0; i < nodeIds.length; i += 1) {
      const leftId = nodeIds[i];
      const left = state.get(leftId);
      if (!left) continue;

      for (let j = i + 1; j < nodeIds.length; j += 1) {
        const rightId = nodeIds[j];
        const right = state.get(rightId);
        if (!right) continue;

        const dx = right.x - left.x;
        const dy = right.y - left.y;
        const distanceSquared = dx * dx + dy * dy + 0.01;
        const distance = Math.sqrt(distanceSquared);
        const repulsion = (2200 * alpha) / distanceSquared;
        const fx = (dx / distance) * repulsion;
        const fy = (dy / distance) * repulsion;

        left.vx -= fx / left.mass;
        left.vy -= fy / left.mass;
        right.vx += fx / right.mass;
        right.vy += fy / right.mass;
      }
    }

    sortedNodes.forEach((node) => {
      const current = state.get(node.id);
      if (!current) return;

      for (const neighbourId of adjacency.get(node.id) ?? []) {
        if (!state.has(neighbourId) || neighbourId <= node.id) continue;

        const neighbour = state.get(neighbourId);
        if (!neighbour) continue;

        const dx = neighbour.x - current.x;
        const dy = neighbour.y - current.y;
        const distance = Math.sqrt(dx * dx + dy * dy) || 1;
        const desired = 70 + Math.min(
          Math.abs(current.targetRadius - neighbour.targetRadius) * 0.35 + 24,
          150,
        );
        const pull = (distance - desired) * 0.0048 * alpha;
        const fx = (dx / distance) * pull;
        const fy = (dy / distance) * pull;

        current.vx += fx;
        current.vy += fy;
        neighbour.vx -= fx;
        neighbour.vy -= fy;
      }
    });

    sortedNodes.forEach((node) => {
      const current = state.get(node.id);
      if (!current) return;

      const dx = current.x - centerX;
      const dy = current.y - centerY;
      const distance = Math.sqrt(dx * dx + dy * dy) || 1;
      const radialError = distance - current.targetRadius;
      const radialPull = radialError * 0.0075;

      current.vx -= (dx / distance) * radialPull;
      current.vy -= (dy / distance) * radialPull;

      if (current.targetRadius <= minRadius + 8) {
        current.vx += (centerX - current.x) * 0.0035;
        current.vy += (centerY - current.y) * 0.0035;
      }

      current.vx *= 0.86;
      current.vy *= 0.86;
      current.x += current.vx;
      current.y += current.vy;
    });
  }

  sortedNodes.forEach((node) => {
    const current = state.get(node.id);
    if (!current) return;
    positions.set(String(node.id), { x: current.x, y: current.y });
  });

  return positions;
}

function buildFocusedLayout(
  nodes: DbNode[],
  focusedGraph: FocusedGraph,
  adjacency: Map<number, Set<number>>,
  centerX: number,
  centerY: number,
): Map<string, Point> {
  const positions = new Map<string, Point>();
  const firstHopCount = Math.max(1, focusedGraph.firstHopIds.length);
  const firstHopRadius = Math.max(220, Math.min(320, 180 + firstHopCount * 12));

  positions.set(String(focusedGraph.selectedNodeId), { x: centerX, y: centerY });

  const firstHopAngles = new Map<number, number>();
  focusedGraph.firstHopIds.forEach((nodeId, index) => {
    const angle = (index / firstHopCount) * Math.PI * 2 - Math.PI / 2;
    firstHopAngles.set(nodeId, angle);
    positions.set(String(nodeId), {
      x: centerX + Math.cos(angle) * firstHopRadius,
      y: centerY + Math.sin(angle) * firstHopRadius,
    });
  });

  const secondHopByParent = new Map<number, number[]>();
  focusedGraph.firstHopIds.forEach((nodeId) => secondHopByParent.set(nodeId, []));

  focusedGraph.secondHopIds.forEach((nodeId) => {
    const parentId = focusedGraph.firstHopIds
      .filter((firstHopId) => adjacency.get(nodeId)?.has(firstHopId))
      .sort((a, b) => (adjacency.get(b)?.size ?? 0) - (adjacency.get(a)?.size ?? 0))[0];

    const targetParent = parentId ?? focusedGraph.firstHopIds[0];
    const group = secondHopByParent.get(targetParent) ?? [];
    group.push(nodeId);
    secondHopByParent.set(targetParent, group);
  });

  secondHopByParent.forEach((group, parentId) => {
    const parentAngle = firstHopAngles.get(parentId) ?? -Math.PI / 2;
    group.forEach((nodeId, index) => {
      const localOffset = (index - (group.length - 1) / 2) * 0.24;
      const angle = parentAngle + localOffset;
      const radius = firstHopRadius + 150 + Math.floor(index / 4) * 30;
      positions.set(String(nodeId), {
        x: centerX + Math.cos(angle) * radius,
        y: centerY + Math.sin(angle) * radius,
      });
    });
  });

  nodes.forEach((node) => {
    if (!positions.has(String(node.id))) {
      positions.set(String(node.id), { x: centerX, y: centerY });
    }
  });

  return positions;
}

export function toRFNodes(params: {
  nodes: DbNode[];
  viewMode: MapViewMode;
  degreeMap: Map<number, number>;
  adjacency: Map<number, Set<number>>;
  focusedGraph: FocusedGraph | null;
  centerX: number;
  centerY: number;
}): RFNode<RahNodeData>[] {
  const { nodes, viewMode, degreeMap, adjacency, focusedGraph, centerX, centerY } = params;

  const positions = viewMode === 'focused' && focusedGraph
    ? buildFocusedLayout(nodes, focusedGraph, adjacency, centerX, centerY)
    : buildOverviewLayout(nodes, adjacency, degreeMap, centerX, centerY);

  return nodes.map((node) => {
    const role: MapNodeRole = focusedGraph
      ? node.id === focusedGraph.selectedNodeId
        ? 'selected'
        : focusedGraph.firstHopIds.includes(node.id)
          ? 'first-hop'
          : 'second-hop'
      : 'overview';

    return {
      id: String(node.id),
      type: 'rahNode',
      position: positions.get(String(node.id)) ?? { x: centerX, y: centerY },
      data: {
        label: node.title || 'Untitled',
        edgeCount: degreeMap.get(node.id) ?? node.edge_count ?? 0,
        dbNode: node,
        role,
        connectionCount: adjacency.get(node.id)?.size ?? 0,
        prominence: Math.min(1, (degreeMap.get(node.id) ?? node.edge_count ?? 0) / Math.max(...nodes.map((n) => degreeMap.get(n.id) ?? n.edge_count ?? 0), 1)),
      },
    };
  });
}

export function toRFEdges(params: {
  dbEdges: DbEdge[];
  nodeIds: Set<string>;
  focusedGraph: FocusedGraph | null;
}): RFEdge[] {
  const { dbEdges, nodeIds, focusedGraph } = params;

  return dbEdges
    .filter((edge) => nodeIds.has(String(edge.from_node_id)) && nodeIds.has(String(edge.to_node_id)))
    .map((edge) => {
      const explanation = typeof edge.context?.explanation === 'string' ? edge.context.explanation : '';
      const touchesSelected = focusedGraph
        ? edge.from_node_id === focusedGraph.selectedNodeId || edge.to_node_id === focusedGraph.selectedNodeId
        : false;
      const touchesSecondHop = focusedGraph
        ? focusedGraph.secondHopIds.includes(edge.from_node_id) || focusedGraph.secondHopIds.includes(edge.to_node_id)
        : false;

      return {
        id: String(edge.id),
        source: String(edge.from_node_id),
        target: String(edge.to_node_id),
        type: 'rahEdge',
        animated: false,
        data: { explanation },
        style: focusedGraph
          ? touchesSelected
            ? { stroke: 'color-mix(in srgb, var(--rah-accent-green) 55%, #94a3b8)', strokeWidth: 1.9, opacity: 0.72 }
            : touchesSecondHop
              ? { stroke: '#64748b', strokeWidth: 1.15, opacity: 0.3 }
              : { stroke: '#475569', strokeWidth: 1.05, opacity: 0.22 }
          : { stroke: '#475569', strokeWidth: 1.05, opacity: 0.2 },
        zIndex: touchesSelected ? 10 : 1,
      };
    });
}
