import { useEffect, useState } from 'react'
import { get, post } from '../api/client'

const DeletionRequests = () => {
  const [requests, setRequests] = useState([])
  const [loading, setLoading] = useState(true)
  const [pagination, setPagination] = useState({})
  const [filter, setFilter] = useState('all')
  const [search, setSearch] = useState('')
  const [selectedRequest, setSelectedRequest] = useState(null)
  const [showModal, setShowModal] = useState(false)
  const [processing, setProcessing] = useState(false)
  const [rejectReason, setRejectReason] = useState('')

  const fetchRequests = async (page = 1) => {
    setLoading(true)
    try {
      const params = new URLSearchParams()
      params.append('page', page)
      if (filter !== 'all') params.append('status', filter)
      if (search) params.append('search', search)

      const data = await get(`/admin/deletion-requests?${params.toString()}`)
      setRequests(data.data || [])
      setPagination({
        current: data.current_page,
        last: data.last_page,
        total: data.total,
      })
    } catch (err) {
      console.error('Failed to fetch deletion requests:', err)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchRequests()
  }, [filter])

  const handleSearch = (e) => {
    e.preventDefault()
    fetchRequests()
  }

  const openModal = (request) => {
    setSelectedRequest(request)
    setRejectReason('')
    setShowModal(true)
  }

  const closeModal = () => {
    setShowModal(false)
    setSelectedRequest(null)
    setRejectReason('')
  }

  const handleProcess = async (action) => {
    if (!selectedRequest) return

    setProcessing(true)
    try {
      await post(`/admin/deletion-requests/${selectedRequest.id}/process`, {
        action,
        reason: action === 'reject' ? rejectReason : null,
      })

      fetchRequests()
      closeModal()
    } catch (err) {
      console.error('Failed to process request:', err)
      alert('Failed to process request. Please try again.')
    } finally {
      setProcessing(false)
    }
  }

  const getStatusBadge = (status) => {
    const styles = {
      pending: { background: '#FEF3C7', color: '#92400E' },
      processing: { background: '#DBEAFE', color: '#1E40AF' },
      completed: { background: '#D1FAE5', color: '#065F46' },
      rejected: { background: '#FEE2E2', color: '#991B1B' },
    }
    const style = styles[status] || styles.pending
    return (
      <span
        className="badge"
        style={{
          ...style,
          padding: '4px 10px',
          borderRadius: '12px',
          fontSize: '12px',
          fontWeight: '500',
          textTransform: 'capitalize',
        }}
      >
        {status}
      </span>
    )
  }

  const formatDate = (dateStr) => {
    if (!dateStr) return '-'
    return new Date(dateStr).toLocaleString()
  }

  return (
    <div className="page">
      <div className="page-header">
        <h1>Account Deletion Requests</h1>
        <p className="muted">Manage user account deletion requests</p>
      </div>

      <div className="card">
        <div className="filters" style={{ display: 'flex', gap: '16px', marginBottom: '20px', flexWrap: 'wrap' }}>
          <form onSubmit={handleSearch} style={{ display: 'flex', gap: '8px', flex: 1, minWidth: '200px' }}>
            <input
              type="text"
              placeholder="Search by email, phone, or reference..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{ flex: 1 }}
            />
            <button type="submit" className="button">
              Search
            </button>
          </form>

          <select value={filter} onChange={(e) => setFilter(e.target.value)} style={{ minWidth: '150px' }}>
            <option value="all">All Status</option>
            <option value="pending">Pending</option>
            <option value="processing">Processing</option>
            <option value="completed">Completed</option>
            <option value="rejected">Rejected</option>
          </select>
        </div>

        {loading ? (
          <div className="loading">Loading...</div>
        ) : requests.length === 0 ? (
          <div className="empty-state">
            <p>No deletion requests found</p>
          </div>
        ) : (
          <>
            <div className="table-wrapper">
              <table>
                <thead>
                  <tr>
                    <th>Reference</th>
                    <th>Email</th>
                    <th>Account Type</th>
                    <th>Reason</th>
                    <th>Status</th>
                    <th>Submitted</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {requests.map((request) => (
                    <tr key={request.id}>
                      <td>
                        <code style={{ fontSize: '12px', background: '#f3f4f6', padding: '2px 6px', borderRadius: '4px' }}>
                          {request.reference}
                        </code>
                      </td>
                      <td>{request.email}</td>
                      <td style={{ textTransform: 'capitalize' }}>
                        {request.account_type === 'job_seeker' ? 'Job Seeker' : 'Employer'}
                      </td>
                      <td>{request.reason || '-'}</td>
                      <td>{getStatusBadge(request.status)}</td>
                      <td>{formatDate(request.created_at)}</td>
                      <td>
                        <button
                          className="ghost-button"
                          onClick={() => openModal(request)}
                          style={{ padding: '6px 12px', fontSize: '13px' }}
                        >
                          {request.status === 'pending' ? 'Process' : 'View'}
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {pagination.last > 1 && (
              <div className="pagination" style={{ marginTop: '20px', display: 'flex', gap: '8px', justifyContent: 'center' }}>
                {Array.from({ length: pagination.last }, (_, i) => i + 1).map((page) => (
                  <button
                    key={page}
                    className={page === pagination.current ? 'button' : 'ghost-button'}
                    onClick={() => fetchRequests(page)}
                    style={{ padding: '6px 12px', minWidth: '36px' }}
                  >
                    {page}
                  </button>
                ))}
              </div>
            )}
          </>
        )}
      </div>

      {/* Modal */}
      {showModal && selectedRequest && (
        <div className="modal-overlay" onClick={closeModal}>
          <div className="modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '500px' }}>
            <div className="modal-header">
              <h2>Deletion Request Details</h2>
              <button className="modal-close" onClick={closeModal}>
                &times;
              </button>
            </div>
            <div className="modal-body">
              <div style={{ display: 'grid', gap: '16px' }}>
                <div>
                  <label className="muted" style={{ fontSize: '12px', display: 'block', marginBottom: '4px' }}>
                    Reference
                  </label>
                  <code style={{ fontSize: '14px', background: '#f3f4f6', padding: '4px 8px', borderRadius: '4px' }}>
                    {selectedRequest.reference}
                  </code>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                  <div>
                    <label className="muted" style={{ fontSize: '12px', display: 'block', marginBottom: '4px' }}>
                      Email
                    </label>
                    <p style={{ margin: 0 }}>{selectedRequest.email}</p>
                  </div>
                  <div>
                    <label className="muted" style={{ fontSize: '12px', display: 'block', marginBottom: '4px' }}>
                      Phone
                    </label>
                    <p style={{ margin: 0 }}>{selectedRequest.phone || 'Not provided'}</p>
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                  <div>
                    <label className="muted" style={{ fontSize: '12px', display: 'block', marginBottom: '4px' }}>
                      Account Type
                    </label>
                    <p style={{ margin: 0, textTransform: 'capitalize' }}>
                      {selectedRequest.account_type === 'job_seeker' ? 'Job Seeker' : 'Employer'}
                    </p>
                  </div>
                  <div>
                    <label className="muted" style={{ fontSize: '12px', display: 'block', marginBottom: '4px' }}>
                      Status
                    </label>
                    {getStatusBadge(selectedRequest.status)}
                  </div>
                </div>

                <div>
                  <label className="muted" style={{ fontSize: '12px', display: 'block', marginBottom: '4px' }}>
                    Reason
                  </label>
                  <p style={{ margin: 0 }}>{selectedRequest.reason || 'Not specified'}</p>
                </div>

                {selectedRequest.comments && (
                  <div>
                    <label className="muted" style={{ fontSize: '12px', display: 'block', marginBottom: '4px' }}>
                      Comments
                    </label>
                    <p style={{ margin: 0, whiteSpace: 'pre-wrap' }}>{selectedRequest.comments}</p>
                  </div>
                )}

                <div>
                  <label className="muted" style={{ fontSize: '12px', display: 'block', marginBottom: '4px' }}>
                    Submitted At
                  </label>
                  <p style={{ margin: 0 }}>{formatDate(selectedRequest.created_at)}</p>
                </div>

                {selectedRequest.processed_at && (
                  <div>
                    <label className="muted" style={{ fontSize: '12px', display: 'block', marginBottom: '4px' }}>
                      Processed At
                    </label>
                    <p style={{ margin: 0 }}>{formatDate(selectedRequest.processed_at)}</p>
                  </div>
                )}

                {selectedRequest.status === 'pending' && (
                  <>
                    <hr style={{ margin: '8px 0', border: 'none', borderTop: '1px solid #e5e7eb' }} />

                    <div>
                      <label className="muted" style={{ fontSize: '12px', display: 'block', marginBottom: '4px' }}>
                        Rejection Reason (if rejecting)
                      </label>
                      <textarea
                        value={rejectReason}
                        onChange={(e) => setRejectReason(e.target.value)}
                        placeholder="Enter reason for rejection..."
                        rows={3}
                        style={{ width: '100%', resize: 'vertical' }}
                      />
                    </div>

                    <div style={{ display: 'flex', gap: '12px', marginTop: '8px' }}>
                      <button
                        className="button"
                        onClick={() => handleProcess('approve')}
                        disabled={processing}
                        style={{
                          flex: 1,
                          background: '#DC2626',
                          borderColor: '#DC2626',
                        }}
                      >
                        {processing ? 'Processing...' : 'Approve & Delete Account'}
                      </button>
                      <button
                        className="ghost-button"
                        onClick={() => handleProcess('reject')}
                        disabled={processing}
                        style={{ flex: 1 }}
                      >
                        {processing ? 'Processing...' : 'Reject Request'}
                      </button>
                    </div>

                    <p className="muted" style={{ fontSize: '12px', textAlign: 'center', margin: '8px 0 0' }}>
                      Warning: Approving will permanently delete the user&apos;s account and all data.
                    </p>
                  </>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default DeletionRequests
