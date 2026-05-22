import type {
  CanonicalNodeMetadata,
  NodeCapturedBy,
  NodeMetadataState,
} from '@/types/database';

type MetadataLike = CanonicalNodeMetadata | Record<string, unknown> | string | null | undefined;

export interface BuildCanonicalMetadataInput {
  existing?: MetadataLike;
  metadata?: MetadataLike;
  type?: string | null;
  state?: NodeMetadataState | null;
  captured_method?: string | null;
  captured_by?: NodeCapturedBy | null;
  source_metadata?: Record<string, unknown> | null;
}

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

export function parseNodeMetadata(metadata: MetadataLike): CanonicalNodeMetadata {
  if (!metadata) return {};

  if (typeof metadata === 'string') {
    try {
      const parsed = JSON.parse(metadata);
      return isObject(parsed) ? { ...parsed } : {};
    } catch {
      return {};
    }
  }

  return isObject(metadata) ? { ...metadata } : {};
}

function normalizeSourceMetadata(sourceMetadata: unknown): Record<string, unknown> {
  return isObject(sourceMetadata) ? { ...sourceMetadata } : {};
}

function normalizedString(value: unknown): string | undefined {
  if (typeof value !== 'string') return undefined;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

export function buildCanonicalNodeMetadata(input: BuildCanonicalMetadataInput): CanonicalNodeMetadata {
  const existing = parseNodeMetadata(input.existing);
  const incoming = parseNodeMetadata(input.metadata);

  const type = normalizedString(input.type) ?? normalizedString(incoming.type) ?? normalizedString(existing.type);
  const state = input.state ?? (incoming.state as NodeMetadataState | undefined) ?? (existing.state as NodeMetadataState | undefined) ?? 'not_processed';
  const capturedMethod =
    normalizedString(input.captured_method)
    ?? normalizedString(incoming.captured_method)
    ?? normalizedString(existing.captured_method);
  const capturedBy =
    input.captured_by
    ?? (incoming.captured_by as NodeCapturedBy | undefined)
    ?? (existing.captured_by as NodeCapturedBy | undefined)
    ?? 'human';

  const sourceMetadata = {
    ...normalizeSourceMetadata(existing.source_metadata),
    ...normalizeSourceMetadata(incoming.source_metadata),
    ...normalizeSourceMetadata(input.source_metadata),
  };

  const merged: CanonicalNodeMetadata = {
    ...existing,
    ...incoming,
    source_metadata: sourceMetadata,
    state,
    captured_by: capturedBy,
  };

  if (type) {
    merged.type = type;
  } else {
    delete merged.type;
  }

  if (capturedMethod) {
    merged.captured_method = capturedMethod;
  } else {
    delete merged.captured_method;
  }

  return merged;
}

export function mergeNodeMetadata(existing: MetadataLike, incoming: MetadataLike): CanonicalNodeMetadata {
  return buildCanonicalNodeMetadata({ existing, metadata: incoming });
}

export function getNodeProcessedState(metadata: MetadataLike): NodeMetadataState {
  const parsed = parseNodeMetadata(metadata);
  return parsed.state === 'processed' ? 'processed' : 'not_processed';
}
