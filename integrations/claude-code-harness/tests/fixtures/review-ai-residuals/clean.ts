export const apiBaseUrl = process.env.API_BASE_URL ?? "";

export function getDisplayName(name: string): string {
  return name.trim();
}
