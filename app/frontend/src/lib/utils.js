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

export function statusBadgeClass(status) {
  if (status === 'active') return 'badge-green'
  if (status === 'pending_approval') return 'badge-amber'
  if (status === 'revoked') return 'badge-red'
  if (status === 'accepted') return 'badge-green'
  return 'badge-zinc'
}

export function formatStatus(status) {
  if (status === 'pending_approval') return 'Pending Approval'
  if (!status) return '—'
  return status.charAt(0).toUpperCase() + status.slice(1)
}
