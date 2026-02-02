import { useEffect, useState } from 'react'
import { get } from '../api/client'

const Transactions = () => {
  const [transactions, setTransactions] = useState([])
  const [filters, setFilters] = useState({
    user_type: '',
    method: '',
    status: '',
    from: '',
    to: '',
  })
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)

  const load = async () => {
    setLoading(true)
    setError('')
    try {
      const params = new URLSearchParams()
      Object.entries(filters).forEach(([key, value]) => {
        if (value) params.set(key, value)
      })
      const data = await get(`/admin/transactions?${params.toString()}`)
      setTransactions(data.data || [])
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

  return (
    <div>
      <h2>Transactions</h2>
      <div className="toolbar">
        <select name="user_type" value={filters.user_type} onChange={handleChange}>
          <option value="">All users</option>
          <option value="candidate">Candidate</option>
          <option value="company">Company</option>
          <option value="admin">Admin</option>
        </select>
        <input
          name="method"
          placeholder="Payment method"
          value={filters.method}
          onChange={handleChange}
        />
        <input
          name="status"
          placeholder="Status"
          value={filters.status}
          onChange={handleChange}
        />
        <input name="from" type="date" value={filters.from} onChange={handleChange} />
        <input name="to" type="date" value={filters.to} onChange={handleChange} />
        <button className="primary-button" onClick={load}>
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
                <th>Type</th>
                <th>Amount</th>
                <th>Method</th>
                <th>Status</th>
                <th>Created</th>
              </tr>
            </thead>
            <tbody>
              {transactions.map((tx) => (
                <tr key={tx.id}>
                  <td>{tx.user?.email || tx.user_id}</td>
                  <td>{tx.type}</td>
                  <td>
                    {tx.currency} {tx.amount}
                  </td>
                  <td>{tx.method || '-'}</td>
                  <td>
                    <span className={`status-pill ${tx.status}`}>{tx.status}</span>
                  </td>
                  <td>{new Date(tx.created_at).toLocaleDateString()}</td>
                </tr>
              ))}
              {!transactions.length && (
                <tr>
                  <td colSpan="6">No transactions found.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

export default Transactions
