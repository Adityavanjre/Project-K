/**
 * IndexedDB persistence for RAG chunks (embeddings).
 *
 * localStorage is too small for embedding vectors (768 floats × N chunks).
 * IndexedDB has no practical size limit and works identically in Tauri WebView.
 *
 * Schema:
 *   DB: "locally-uncensored-rag" (v1)
 *   ObjectStore: "chunks"  — key: documentId, value: TextChunk[]
 */

import type { TextChunk } from "../types/rag"

const DB_NAME = "locally-uncensored-rag"
const DB_VERSION = 1
const STORE_NAME = "chunks"

let dbPromise: Promise<IDBDatabase> | null = null

function openDB(): Promise<IDBDatabase> {
  if (dbPromise) return dbPromise

  dbPromise = new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION)

    request.onupgradeneeded = () => {
      const db = request.result
      if (!db.objectStoreNames.contains(STORE_NAME)) {
        db.createObjectStore(STORE_NAME)
      }
    }

    request.onsuccess = () => resolve(request.result)
    request.onerror = () => {
      dbPromise = null
      reject(request.error)
    }
  })

  return dbPromise
}

function tx(mode: IDBTransactionMode): Promise<IDBObjectStore> {
  return openDB().then((db) => {
    const transaction = db.transaction(STORE_NAME, mode)
    return transaction.objectStore(STORE_NAME)
  })
}

function idbRequest<T>(req: IDBRequest<T>): Promise<T> {
  return new Promise((resolve, reject) => {
    req.onsuccess = () => resolve(req.result)
    req.onerror = () => reject(req.error)
  })
}

/** Save chunks for a document (overwrites if exists) */
export async function saveChunks(documentId: string, chunks: TextChunk[]): Promise<void> {
  const store = await tx("readwrite")
  await idbRequest(store.put(chunks, documentId))
}

/** Load chunks for specific document IDs */
export async function loadChunks(documentIds: string[]): Promise<TextChunk[]> {
  if (documentIds.length === 0) return []

  const store = await tx("readonly")
  const results: TextChunk[] = []

  for (const docId of documentIds) {
    const chunks = await idbRequest(store.get(docId)) as TextChunk[] | undefined
    if (chunks) results.push(...chunks)
  }

  return results
}

/** Delete chunks for a document */
export async function deleteChunks(documentId: string): Promise<void> {
  const store = await tx("readwrite")
  await idbRequest(store.delete(documentId))
}

/** Delete all chunks (e.g., when clearing all data) */
export async function clearAllChunks(): Promise<void> {
  const store = await tx("readwrite")
  await idbRequest(store.clear())
}
