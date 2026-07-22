const SECRET_PATTERNS = [
  /(api[_-]?key|token|secret|password|passwd|authorization)\s*[:=]\s*['"]?([^\s'"]+)/gi,
  /(Bearer)\s+[A-Za-z0-9\-._~+/]+=*/gi,
  /(postgres|mysql|mongodb|redis):\/\/[^\s'"]+/gi,
  /([?&](?:access_token|refresh_token|id_token|sig|signature|key)=)[^&\s'"]+/gi,
];

export function sanitizeText(value) {
  if (value == null) return value;
  let text = String(value);
  for (const pattern of SECRET_PATTERNS) {
    text = text.replace(pattern, (match, p1) => {
      if (/^Bearer$/i.test(p1)) return 'Bearer [REDACTED]';
      if (/:\/\//.test(match)) {
        return match.replace(/:\/\/.+$/, '://[REDACTED]');
      }
      if (typeof p1 === 'string' && p1.startsWith('?') || (typeof p1 === 'string' && p1.startsWith('&'))) {
        return `${p1}[REDACTED]`;
      }
      return `${p1}=[REDACTED]`;
    });
  }
  return text;
}

export function sanitizeDeep(value) {
  if (Array.isArray(value)) return value.map(sanitizeDeep);
  if (value && typeof value === 'object') {
    const out = {};
    for (const [key, nested] of Object.entries(value)) {
      out[key] = sanitizeDeep(nested);
    }
    return out;
  }
  if (typeof value === 'string') return sanitizeText(value);
  return value;
}
