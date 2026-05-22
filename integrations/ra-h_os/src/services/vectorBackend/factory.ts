import { getVectorBackendType, type VectorBackend } from './index';

let instance: VectorBackend | null = null;
let instanceType: string | null = null;

export async function getVectorBackend(): Promise<VectorBackend> {
  const type = getVectorBackendType();
  if (instance && instanceType === type) return instance;

  if (type === 'qdrant') {
    const { QdrantBackend } = await import('./qdrant');
    instance = new QdrantBackend();
  } else {
    const { SqliteVecBackend } = await import('./sqlite-vec-backend');
    instance = new SqliteVecBackend();
  }

  instanceType = type;
  return instance;
}
