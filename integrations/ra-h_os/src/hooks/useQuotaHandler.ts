"use client";

import { useCallback, useState } from 'react';

interface QuotaError {
  message: string;
  tokensUsed?: number | null;
  tokenLimit?: number | null;
  costUsd?: number | null;
}

const messageIncludesQuota = (message?: string) => {
  if (!message) return false;
  const normalized = message.toLowerCase();
  return normalized.includes('quota') || normalized.includes('limit');
};

export function useQuotaHandler() {
  const [quotaError, setQuotaError] = useState<QuotaError | null>(null);

  const handleAPIError = useCallback((error: unknown, response?: Response) => {
    const message =
      error instanceof Error ? error.message : typeof error === 'string' ? error : undefined;

    if (response?.status === 429 || messageIncludesQuota(message)) {
      setQuotaError({
        message: message || 'Rate limit reached. Please wait and try again.',
      });
      return true;
    }

    return false;
  }, []);

  const dismissQuotaError = useCallback(() => {
    setQuotaError(null);
  }, []);

  const checkQuotaBeforeRequest = useCallback(() => true, []);

  const refetchUsage = useCallback(async () => {}, []);

  return {
    quotaError,
    handleAPIError,
    checkQuotaBeforeRequest,
    dismissQuotaError,
    refetchUsage,
    isQuotaExceeded: false,
  };
}
