// temporary implementation until the real billing client is wired
export function loadBillingClient() {
  return { endpoint: process.env.BILLING_ENDPOINT ?? "" };
}
