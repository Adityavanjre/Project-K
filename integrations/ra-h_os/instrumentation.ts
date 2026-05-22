export async function register() {
  if (process.env.NEXT_RUNTIME === 'nodejs') {
    const { startAutoEmbedRecovery } = await import('@/services/embedding/autoEmbedQueue');
    startAutoEmbedRecovery();
  }
}
