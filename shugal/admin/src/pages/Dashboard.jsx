import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Chart as ChartJS,
  ArcElement,
  BarElement,
  CategoryScale,
  Legend,
  LineElement,
  LinearScale,
  PointElement,
  Tooltip,
} from 'chart.js'
import {
  IconCandidates,
  IconCompanies,
  IconJobs,
  IconRevenue,
} from '../components/Icons'
import { Bar, Line, Pie } from 'react-chartjs-2'
import { get } from '../api/client'

ChartJS.register(
  ArcElement,
  BarElement,
  CategoryScale,
  Legend,
  LineElement,
  LinearScale,
  PointElement,
  Tooltip,
)

const Dashboard = () => {
  const [stats, setStats] = useState(null)
  const [recentJobs, setRecentJobs] = useState([])
  const [recentTransactions, setRecentTransactions] = useState([])
  const [error, setError] = useState('')
  const navigate = useNavigate()

  const chartPalette = {
    primary: '#075056',
    secondary: '#0a9ba5',
    accent: '#8ab4b7',
    success: '#10b981',
  }

  const userSplitData = useMemo(() => {
    if (!stats) return null
    return {
      labels: ['Candidates', 'Companies'],
      datasets: [
        {
          data: [stats.candidates, stats.companies],
          backgroundColor: [chartPalette.primary, chartPalette.secondary],
          borderWidth: 0,
        },
      ],
    }
  }, [stats])

  const jobsStatusData = useMemo(() => {
    const statusCounts = recentJobs.reduce(
      (acc, job) => {
        const status = job.status || 'open'
        acc[status] = (acc[status] || 0) + 1
        return acc
      },
      { open: 0, closed: 0, draft: 0 },
    )
    return {
      labels: Object.keys(statusCounts),
      datasets: [
        {
          label: 'Jobs',
          data: Object.values(statusCounts),
          backgroundColor: [
            chartPalette.success,
            chartPalette.primary,
            chartPalette.accent,
          ],
        },
      ],
    }
  }, [recentJobs])

  const transactionTrendData = useMemo(() => {
    const sorted = [...recentTransactions].reverse()
    return {
      labels: sorted.map((tx, index) => `T${index + 1}`),
      datasets: [
        {
          label: 'Revenue',
          data: sorted.map((tx) => Number(tx.amount || 0)),
          borderColor: chartPalette.primary,
          backgroundColor: 'rgba(7, 80, 86, 0.2)',
          tension: 0.35,
          fill: true,
        },
      ],
    }
  }, [recentTransactions])

  useEffect(() => {
    const load = async () => {
      try {
        const data = await get('/admin/dashboard/stats')
        const jobs = await get('/admin/jobs?per_page=5')
        const transactions = await get('/admin/transactions?per_page=5')
        setStats(data)
        setRecentJobs(jobs.data || [])
        setRecentTransactions(transactions.data || [])
      } catch (err) {
        setError(err.message)
      }
    }
    load()
  }, [])

  return (
    <div>
      <h2>Dashboard</h2>
      {error && <div className="error">{error}</div>}
      {stats ? (
        <>
          <div className="stats-grid">
            <div className="stat-card">
              <div className="stat-head">
                <span className="stat-icon">
                  <IconCandidates />
                </span>
                <h3>Candidates</h3>
              </div>
              <p className="stat-value">{stats.candidates}</p>
            </div>
            <div className="stat-card">
              <div className="stat-head">
                <span className="stat-icon">
                  <IconCompanies />
                </span>
                <h3>Companies</h3>
              </div>
              <p className="stat-value">{stats.companies}</p>
            </div>
            <div className="stat-card">
              <div className="stat-head">
                <span className="stat-icon">
                  <IconJobs />
                </span>
                <h3>Jobs</h3>
              </div>
              <p className="stat-value">{stats.jobs}</p>
            </div>
            <div className="stat-card">
              <div className="stat-head">
                <span className="stat-icon">
                  <IconRevenue />
                </span>
                <h3>Revenue</h3>
              </div>
              <p className="stat-value">KWD {stats.revenue}</p>
            </div>
          </div>
          <div className="dashboard-grid">
            <div className="card">
              <div className="section-title">Recent Jobs</div>
              <div className="table-wrapper">
                <table>
                  <thead>
                    <tr>
                      <th>Title</th>
                      <th>Company</th>
                      <th>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {recentJobs.map((job) => (
                      <tr key={job.id}>
                        <td>{job.title}</td>
                        <td>{job.company?.name || job.company_id}</td>
                        <td>{job.status}</td>
                      </tr>
                    ))}
                    {!recentJobs.length && (
                      <tr>
                        <td colSpan="3">No jobs yet.</td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
            <div className="card">
              <div className="section-title">Recent Transactions</div>
              <div className="table-wrapper">
                <table>
                  <thead>
                    <tr>
                      <th>User</th>
                      <th>Type</th>
                      <th>Amount</th>
                    </tr>
                  </thead>
                  <tbody>
                    {recentTransactions.map((tx) => (
                      <tr key={tx.id}>
                        <td>{tx.user?.email || tx.user_id}</td>
                        <td>{tx.type}</td>
                        <td>
                          {tx.currency} {tx.amount}
                        </td>
                      </tr>
                    ))}
                    {!recentTransactions.length && (
                      <tr>
                        <td colSpan="3">No transactions yet.</td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
            <div className="card">
              <div className="section-title">Quick Actions</div>
              <p className="muted">Jump to key admin tasks.</p>
              <div className="toolbar">
                <button className="primary-button" onClick={() => navigate('/jobs')}>
                  Create Job
                </button>
                <button className="ghost-button" onClick={() => navigate('/candidates')}>
                  Add Candidate
                </button>
                <button className="ghost-button" onClick={() => navigate('/companies')}>
                  Add Company
                </button>
              </div>
            </div>
            <div className="card">
              <div className="section-title">Users Split</div>
              {userSplitData ? (
                <div className="chart-box">
                  <Pie data={userSplitData} />
                </div>
              ) : (
                <p>Loading...</p>
              )}
            </div>
          </div>
          <div className="dashboard-grid">
            <div className="card">
              <div className="section-title">Jobs by Status</div>
              <div className="chart-box">
                <Bar data={jobsStatusData} />
              </div>
            </div>
            <div className="card">
              <div className="section-title">Revenue Trend</div>
              <div className="chart-box">
                <Line data={transactionTrendData} />
              </div>
            </div>
          </div>
        </>
      ) : (
        <p>Loading...</p>
      )}
    </div>
  )
}

export default Dashboard
