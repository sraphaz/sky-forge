export function logStep(step, { json = false } = {}) {
  if (json) return;
  console.error(`[sky-archify] ${step}`);
}

export function logWarn(message, { json = false } = {}) {
  if (json) return;
  console.error(`[sky-archify] warn: ${message}`);
}
