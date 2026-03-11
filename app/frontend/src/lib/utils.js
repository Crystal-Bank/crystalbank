export function formatDate(str) {
  if (!str) return ''
  try {
    return new Date(str).toLocaleDateString('en-US', {
      month: 'short', day: 'numeric', year: 'numeric',
      hour: '2-digit', minute: '2-digit',
    })
  } catch { return str }
}

export function shortId(id) {
  return id ? id.substring(0, 8) + '...' : ''
}
