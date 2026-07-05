/** Shared phone normalization for Tanzania (+255). */
export function normalizePhone(raw) {
  if (!raw) return null;
  let digits = String(raw).replace(/\D/g, '');
  if (digits.startsWith('0')) digits = `255${digits.slice(1)}`;
  if (digits.length === 9) digits = `255${digits}`;
  if (!digits.startsWith('255') || digits.length < 12) return null;
  return digits;
}

export function localPhone(normalized) {
  if (!normalized?.startsWith('255')) return null;
  return `0${normalized.slice(3)}`;
}

export function phoneLookupVariants(raw) {
  const trimmed = String(raw || '').trim();
  const normalized = normalizePhone(trimmed);
  const local = normalized ? localPhone(normalized) : null;
  const variants = new Set([trimmed, normalized, local].filter(Boolean));
  return [...variants];
}

export function userStatus(row) {
  return String(row?.status || 'active').trim().toLowerCase();
}
