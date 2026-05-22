import { createEmbeddingProvider } from '@/services/embedding/provider';
import { createUtilityLlmProvider } from '@/services/llm/provider';
import { getSQLiteClient } from '@/services/database/sqlite-client';
import { getVectorBackend } from '@/services/vectorBackend/factory';

async function main() {
  const sqlite = getSQLiteClient();
  const utility = createUtilityLlmProvider();
  const embedding = createEmbeddingProvider();
  const vectorBackend = await getVectorBackend();

  const [utilityHealth, embeddingHealth, vectorHealth] = await Promise.all([
    utility.healthCheck(),
    embedding.healthCheck(),
    vectorBackend.healthCheck(),
  ]);
  const profileStatus = sqlite.getEmbeddingProfileStatus();

  console.log(JSON.stringify({
    ok: utilityHealth.ok && embeddingHealth.ok && vectorHealth.ok && !profileStatus.rebuild_required,
    utility_llm: utilityHealth,
    embedding_provider: embeddingHealth,
    vector_backend: vectorHealth,
    embedding_profile: profileStatus,
    next_action: profileStatus.rebuild_required
      ? 'Run npm run rebuild:embeddings after confirming your embedding provider/model/dimensions.'
      : 'Local AI/vector configuration is ready.',
  }, null, 2));

  if (!utilityHealth.ok || !embeddingHealth.ok || !vectorHealth.ok || profileStatus.rebuild_required) {
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
