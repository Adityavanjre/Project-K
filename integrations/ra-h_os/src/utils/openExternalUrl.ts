"use client";

const LOCAL_HOSTS = new Set(["127.0.0.1", "localhost", "0.0.0.0"]);

function resolveUrl(rawUrl: string): URL | null {
  if (typeof window === "undefined") return null;

  try {
    return new URL(rawUrl, window.location.href);
  } catch (error) {
    console.error("[external] failed to parse url", rawUrl, error);
    return null;
  }
}

function isLocalAppUrl(url: URL) {
  if (!["http:", "https:"].includes(url.protocol)) {
    return false;
  }

  return LOCAL_HOSTS.has(url.hostname) || url.hostname === window.location.hostname;
}

export async function openExternalUrl(url: string) {
  if (typeof window === "undefined") return;

  const resolvedUrl = resolveUrl(url)?.toString() ?? url;
  const newWindow = window.open(resolvedUrl, "_blank", "noopener,noreferrer");
  if (!newWindow) {
    throw new Error("browser_open_blocked");
  }
}

export function shouldOpenExternally(rawUrl: string) {
  if (typeof window === "undefined") return false;

  const resolved = resolveUrl(rawUrl);
  if (!resolved) {
    return false;
  }

  if (!["http:", "https:"].includes(resolved.protocol)) {
    return false;
  }

  return !isLocalAppUrl(resolved);
}
