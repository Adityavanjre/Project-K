import Database from 'better-sqlite3';
import fs from 'fs';
import os from 'os';
import path from 'path';

export type VectorCapability =
  | {
      available: true;
      backend: 'sqlite-vec';
      extensionPath: string;
      detail: string;
    }
  | {
      available: false;
      backend: 'none';
      extensionPath: string;
      reason: string;
    };

const VECTOR_CAPABILITY_KEY = '__rahVectorCapability';

function getHomeDirectory(): string {
  return os.homedir() || process.env.HOME || '~';
}

export function getDefaultDbPath(): string {
  const homeDir = getHomeDirectory();

  if (process.platform === 'win32') {
    const appData = process.env.APPDATA || path.join(homeDir, 'AppData', 'Roaming');
    return path.join(appData, 'RA-H', 'db', 'rah.sqlite');
  }

  if (process.platform === 'darwin') {
    return path.join(homeDir, 'Library', 'Application Support', 'RA-H', 'db', 'rah.sqlite');
  }

  return path.join(
    process.env.XDG_DATA_HOME || path.join(homeDir, '.local', 'share'),
    'RA-H',
    'db',
    'rah.sqlite'
  );
}

export function getDatabasePath(): string {
  return process.env.SQLITE_DB_PATH || getDefaultDbPath();
}

export function getDefaultVecExtensionPath(): string {
  const extension = process.platform === 'darwin'
    ? 'dylib'
    : process.platform === 'win32'
      ? 'dll'
      : 'so';

  return path.join(process.cwd(), 'vendor', 'sqlite-extensions', `vec0.${extension}`);
}

export function getVecExtensionPath(): string {
  return process.env.SQLITE_VEC_EXTENSION_PATH || getDefaultVecExtensionPath();
}

export function ensureDatabaseDirectory(dbPath: string): void {
  const dbDirectory = path.dirname(dbPath);
  if (!fs.existsSync(dbDirectory)) {
    fs.mkdirSync(dbDirectory, { recursive: true });
  }
}

function buildVectorFailureReason(error: unknown, extensionPath: string): string {
  const message = error instanceof Error ? error.message : String(error);

  if (process.platform === 'win32') {
    return `sqlite-vec failed to load from ${extensionPath}. On Windows, install vec0.dll or switch to Qdrant. Original error: ${message}`;
  }

  if (process.platform === 'linux') {
    return `sqlite-vec failed to load from ${extensionPath}. Alpine/musl builds are unsupported; use Qdrant there. Original error: ${message}`;
  }

  return `sqlite-vec failed to load from ${extensionPath}. Original error: ${message}`;
}

export function loadVecExtension(db: Database.Database, extensionPath = getVecExtensionPath()): VectorCapability {
  try {
    db.loadExtension(extensionPath);
    const capability: VectorCapability = {
      available: true,
      backend: 'sqlite-vec',
      extensionPath,
      detail: 'sqlite-vec extension loaded successfully',
    };
    (db as Database.Database & Record<string, unknown>)[VECTOR_CAPABILITY_KEY] = capability;
    return capability;
  } catch (error) {
    const capability: VectorCapability = {
      available: false,
      backend: 'none',
      extensionPath,
      reason: buildVectorFailureReason(error, extensionPath),
    };
    (db as Database.Database & Record<string, unknown>)[VECTOR_CAPABILITY_KEY] = capability;
    return capability;
  }
}

export function getDbVectorCapability(db: Database.Database): VectorCapability {
  const capability = (db as Database.Database & Record<string, unknown>)[VECTOR_CAPABILITY_KEY];
  if (capability && typeof capability === 'object' && 'available' in capability) {
    return capability as VectorCapability;
  }

  return {
    available: false,
    backend: 'none',
    extensionPath: getVecExtensionPath(),
    reason: 'sqlite-vec capability was not initialized for this database connection',
  };
}
