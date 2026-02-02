import { useEffect, useState } from 'react'
import { get } from '../api/client'

const ActivityLogs = () => {
  const [logs, setLogs] = useState([])
  const [pagination, setPagination] = useState({
    current_page: 1,
    last_page: 1,
    per_page: 20,
    total: 0,
  })
  const [filters, setFilters] = useState({
    action: '',
  })
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)

  const load = async (page = 1) => {
    setLoading(true)
    setError('')
    try {
      const params = new URLSearchParams()
      params.set('page', page)
      params.set('per_page', 20)
      Object.entries(filters).forEach(([key, value]) => {
        if (value) params.set(key, value)
      })
      const data = await get(`/admin/activity-logs?${params.toString()}`)
      setLogs(data.data || [])
      setPagination({
        current_page: data.current_page || 1,
        last_page: data.last_page || 1,
        per_page: data.per_page || 20,
        total: data.total || 0,
      })
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
  }, [])

  const handleChange = (event) => {
    setFilters((prev) => ({ ...prev, [event.target.name]: event.target.value }))
  }

  const getActionColor = (action) => {
    const lowerAction = action?.toLowerCase() || ''
    if (lowerAction.includes('login')) return 'active'
    if (lowerAction.includes('logout')) return 'draft'
    if (lowerAction.includes('create') || lowerAction.includes('register') || lowerAction.includes('sent')) return 'open'
    if (lowerAction.includes('update') || lowerAction.includes('edit')) return 'reviewed'
    if (lowerAction.includes('delete') || lowerAction.includes('remove')) return 'closed'
    return ''
  }

  const formatAction = (action) => {
    if (!action) return '-'
    // Convert 'message.sent' or 'user_login' to 'Message Sent' or 'User Login'
    return action
      .replace(/[._-]/g, ' ')
      .replace(/\b\w/g, (char) => char.toUpperCase())
  }

  const goToPage = (page) => {
    if (page >= 1 && page <= pagination.last_page) {
      load(page)
    }
  }

  const formatKey = (key) => {
    // Convert 'to' to 'To', 'job_id' to 'Job', etc.
    const keyMap = {
      to: 'To',
      from: 'From',
      job_id: 'Job',
      company_id: 'Company',
      candidate_id: 'Candidate',
      user_id: 'User',
      application_id: 'Application',
      status: 'Status',
      old_status: 'Previous Status',
      new_status: 'New Status',
      ip: 'IP Address',
      browser: 'Browser',
      device: 'Device',
    }
    if (keyMap[key]) return keyMap[key]
    return key
      .replace(/[._-]/g, ' ')
      .replace(/\b\w/g, (char) => char.toUpperCase())
  }

  const formatMetaValue = (key, value) => {
    if (value === null || value === undefined) return '-'
    if (typeof value === 'boolean') return value ? 'Yes' : 'No'
    if (typeof value === 'object') return JSON.stringify(value)
    return String(value)
  }

  const formatMeta = (meta) => {
    if (!meta) return '-'
    if (typeof meta === 'string') return meta
    try {
      const entries = Object.entries(meta)
      if (entries.length === 0) return '-'
      return entries
        .slice(0, 3)
        .map(([key, value]) => `${formatKey(key)}: ${formatMetaValue(key, value)}`)
        .join(' • ')
    } catch {
      return '-'
    }
  }

  return (
    <div>
      <h2>Activity Logs</h2>
      <div className="toolbar">
        <input
          name="action"
          placeholder="Filter by action..."
          value={filters.action}
          onChange={handleChange}
        />
        <button className="primary-button" onClick={() => load(1)}>
          Filter
        </button>
      </div>
      {error && <div className="error">{error}</div>}
      {loading ? (
        <p>Loading...</p>
      ) : (
        <div className="table-wrapper">
          <table>
            <thead>
              <tr>
                <th>User</th>
                <th>Action</th>
                <th>Details</th>
                <th>IP Address</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody>
              {logs.map((log) => (
                <tr key={log.id}>
                  <td>
                    <div className="applicant-details">
                      <span className="name">{log.user?.name || 'System'}</span>
                      <span className="email">{log.user?.email || '-'}</span>
                    </div>
                  </td>
                  <td>
                    <span className={`status-pill ${getActionColor(log.action)}`}>
                      {formatAction(log.action)}
                    </span>
                  </td>
                  <td>
                    <span className="muted" style={{ fontSize: '12px' }}>
                      {formatMeta(log.meta)}
                    </span>
                  </td>
                  <td>
                    <span className="muted">{log.ip_address || '-'}</span>
                  </td>
                  <td>{new Date(log.created_at).toLocaleString()}</td>
                </tr>
              ))}
              {!logs.length && (
                <tr>
                  <td colSpan="5">No activity logs found.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
      {pagination.last_page > 1 && (
        <div className="pagination">
          <button
            className="ghost-button"
            onClick={() => goToPage(pagination.current_page - 1)}
            disabled={pagination.current_page === 1}
          >
            Previous
          </button>
          <span className="pagination-info">
            Page {pagination.current_page} of {pagination.last_page} ({pagination.total} total)
          </span>
          <button
            className="ghost-button"
            onClick={() => goToPage(pagination.current_page + 1)}
            disabled={pagination.current_page === pagination.last_page}
          >
            Next
          </button>
        </div>
      )}
    </div>
  )
}

export default ActivityLogs
