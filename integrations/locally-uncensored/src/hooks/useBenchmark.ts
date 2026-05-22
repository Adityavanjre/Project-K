/**
 * Benchmark Runner — runs standardized prompts against a model and measures performance.
 */

import { useCallback, useRef } from 'react'
import { useBenchmarkStore } from '../stores/benchmarkStore'
import { getProviderForModel } from '../api/providers'
import { BENCHMARK_PROMPTS } from '../lib/benchmark-prompts'
import type { ChatMessage } from '../api/providers/types'

export function useBenchmark() {
  const store = useBenchmarkStore()
  const abortRef = useRef<AbortController | null>(null)

  const runBenchmark = useCallback(async (modelName: string) => {
    if (store.isRunning) return

    store.setRunning(true, modelName, BENCHMARK_PROMPTS.length)

    for (let i = 0; i < BENCHMARK_PROMPTS.length; i++) {
      const prompt = BENCHMARK_PROMPTS[i]
      store.setStep(i + 1)

      abortRef.current = new AbortController()

      try {
        const { provider, modelId } = getProviderForModel(modelName)
        const messages: ChatMessage[] = [
          { role: 'user', content: prompt.prompt },
        ]

        const startTime = performance.now()
        let firstTokenTime = 0
        let tokenCount = 0

        const stream = provider.chatStream(modelId, messages, {
          temperature: 0.7,
          signal: abortRef.current.signal,
        })

        for await (const chunk of stream) {
          if (chunk.content) {
            if (tokenCount === 0) {
              firstTokenTime = performance.now() - startTime
            }
            tokenCount++
          }
        }

        const totalTime = performance.now() - startTime

        store.addResult({
          modelName,
          promptId: prompt.id,
          tokensPerSec: totalTime > 0 ? (tokenCount / totalTime) * 1000 : 0,
          timeToFirstToken: firstTokenTime,
          totalTime,
          totalTokens: tokenCount,
          timestamp: Date.now(),
        })
      } catch {
        // Aborted or error — skip this prompt
      }
    }

    store.setRunning(false)
  }, [store])

  const stopBenchmark = useCallback(() => {
    abortRef.current?.abort()
    store.setRunning(false)
  }, [store])

  return { runBenchmark, stopBenchmark }
}
