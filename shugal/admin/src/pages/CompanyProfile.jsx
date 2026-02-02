import { useEffect, useMemo, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { get, normalizeStorageUrl } from '../api/client'

const CompanyProfile = () => {
  const { id } = useParams()
  const [profile, setProfile] = useState(null)
  const [activeTab, setActiveTab] = useState('overview')
  const [error, setError] = useState('')
  const [countries, setCountries] = useState([])

  useEffect(() => {
    const load = async () => {
      setError('')
      try {
        const data = await get(`/admin/companies/${id}`)
        setProfile(data)
      } catch (err) {
        setError(err.message)
      }
    }
    const loadCountries = async () => {
      try {
        const data = await get('/admin/countries')
        setCountries(data)
      } catch (err) {
        // Optional
      }
    }
    load()
    loadCountries()
  }, [id])

  const company = profile?.company
  const profileData = company?.company_profile || {}
  const countryName = useMemo(() => {
    if (!profileData?.country_id) return '-'
    const match = countries.find((item) => String(item.id) === String(profileData.country_id))
    return match?.translations?.en || match?.code || '-'
  }, [countries, profileData?.country_id])

  return (
    <div>
      <div className="toolbar">
        <Link className="ghost-button" to="/companies">
          Back to Companies
        </Link>
      </div>
      <h2>Company Profile</h2>
      {error && <div className="error">{error}</div>}
      {!profile ? (
        <p>Loading...</p>
      ) : (
        <div className="settings-section">
          <div className="settings-tabs">
            <button
              type="button"
              className={`tab-button ${activeTab === 'overview' ? 'active' : ''}`}
              onClick={() => setActiveTab('overview')}
            >
              Overview
            </button>
            <button
              type="button"
              className={`tab-button ${activeTab === 'jobs' ? 'active' : ''}`}
              onClick={() => setActiveTab('jobs')}
            >
              Jobs
            </button>
            <button
              type="button"
              className={`tab-button ${activeTab === 'unlocks' ? 'active' : ''}`}
              onClick={() => setActiveTab('unlocks')}
            >
              Unlocks
            </button>
            <button
              type="button"
              className={`tab-button ${activeTab === 'applications' ? 'active' : ''}`}
              onClick={() => setActiveTab('applications')}
            >
              Applications
            </button>
            <button
              type="button"
              className={`tab-button ${activeTab === 'transactions' ? 'active' : ''}`}
              onClick={() => setActiveTab('transactions')}
            >
              Transactions
            </button>
          </div>

          {activeTab === 'overview' && (
            <div className="settings-section">
              <div className="settings-card">
                <h4>Company Profile</h4>
                <div className="profile-header">
                  <img
                    className="profile-avatar"
                    src={normalizeStorageUrl(profileData.logo_path) || '/placeholder-avatar.svg'}
                    alt="Company"
                  />
                  <div className="profile-meta">
                    <h3>{profileData.company_name || company?.name || '-'}</h3>
                    <div className="profile-meta-row">
                      <span className={`status-pill ${company?.status || ''}`}>
                        {company?.status || '-'}
                      </span>
                      <span className="muted">Code: {company?.unique_code || '-'}</span>
                    </div>
                    {profileData.website ? (
                      <a className="profile-link" href={profileData.website} target="_blank" rel="noreferrer">
                        {profileData.website}
                      </a>
                    ) : (
                      <span className="muted">Website: -</span>
                    )}
                  </div>
                </div>
              </div>

              <div className="settings-card">
                <h4>Company Details</h4>
                <div className="detail-grid">
                  <div className="detail-item">
                    <span className="detail-label">Legal Name</span>
                    <span className="detail-value">{company?.name || '-'}</span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Email</span>
                    <span className="detail-value">{company?.email || '-'}</span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Company Name</span>
                    <span className="detail-value">
                      {profileData.company_name || company?.name || '-'}
                    </span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Country</span>
                    <span className="detail-value">{countryName}</span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Mobile Number</span>
                    <span className="detail-value">{profileData.mobile_number || '-'}</span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Contact Email</span>
                    <span className="detail-value">{profileData.contact_email || '-'}</span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Civil ID</span>
                    <span className="detail-value">{profileData.civil_id || '-'}</span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Majors</span>
                    <span className="detail-value">
                      {profileData.majors?.length ? profileData.majors.join(', ') : '-'}
                    </span>
                  </div>
                  <div className="detail-item full-row">
                    <span className="detail-label">Description</span>
                    <span className="detail-value">{profileData.description || '-'}</span>
                  </div>
                </div>
              </div>

              <div className="settings-card">
                <h4>Documents</h4>
                <div className="detail-grid">
                  <div className="detail-item">
                    <span className="detail-label">Company Logo</span>
                    {profileData.logo_path ? (
                      <div className="flag-preview">
                        <img src={normalizeStorageUrl(profileData.logo_path)} alt="Logo" />
                        <span className="muted">Logo</span>
                      </div>
                    ) : (
                      <span className="detail-value">-</span>
                    )}
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">License</span>
                    {profileData.license_path ? (
                      <div className="license-preview">
                        <a href={normalizeStorageUrl(profileData.license_path)} target="_blank" rel="noreferrer">
                          View license
                        </a>
                      </div>
                    ) : (
                      <span className="detail-value">-</span>
                    )}
                  </div>
                </div>
              </div>
            </div>
          )}

          {activeTab === 'jobs' && (
            <div className="settings-card">
              <h4>Jobs</h4>
              <div className="table-wrapper">
                <table>
                  <thead>
                    <tr>
                      <th>Title</th>
                      <th>Status</th>
                      <th>Applicants</th>
                    </tr>
                  </thead>
                  <tbody>
                    {profile.jobs?.map((job) => (
                      <tr key={job.id}>
                        <td>{job.title}</td>
                        <td>{job.status}</td>
                        <td>{job.applications_count}</td>
                      </tr>
                    ))}
                    {!profile.jobs?.length && (
                      <tr>
                        <td colSpan="3">No jobs yet.</td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {activeTab === 'unlocks' && (
            <div className="settings-card">
              <h4>Unlocked Candidates</h4>
              <div className="table-wrapper">
                <table>
                  <thead>
                    <tr>
                      <th>Candidate</th>
                      <th>Unlocked At</th>
                      <th>Transaction</th>
                    </tr>
                  </thead>
                  <tbody>
                    {profile.unlocks?.map((unlock) => (
                      <tr key={unlock.id}>
                        <td>{unlock.candidate?.name}</td>
                        <td>
                          {unlock.unlocked_at
                            ? new Date(unlock.unlocked_at).toLocaleString()
                            : '-'}
                        </td>
                        <td>{unlock.transaction?.reference || '-'}</td>
                      </tr>
                    ))}
                    {!profile.unlocks?.length && (
                      <tr>
                        <td colSpan="3">No unlocks yet.</td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {activeTab === 'applications' && (
            <div className="settings-card">
              <h4>Applications</h4>
              <div className="table-wrapper">
                <table>
                  <thead>
                    <tr>
                      <th>Job</th>
                      <th>Candidate</th>
                      <th>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {profile.applications?.map((app) => (
                      <tr key={app.id}>
                        <td>{app.job?.title}</td>
                        <td>{app.candidate?.name}</td>
                        <td>{app.status}</td>
                      </tr>
                    ))}
                    {!profile.applications?.length && (
                      <tr>
                        <td colSpan="3">No applications yet.</td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {activeTab === 'transactions' && (
            <div className="settings-card">
              <h4>Transactions</h4>
              <div className="table-wrapper">
                <table>
                  <thead>
                    <tr>
                      <th>Type</th>
                      <th>Amount</th>
                      <th>Status</th>
                      <th>Created</th>
                    </tr>
                  </thead>
                  <tbody>
                    {profile.transactions?.map((tx) => (
                      <tr key={tx.id}>
                        <td>{tx.type}</td>
                        <td>
                          {tx.currency} {tx.amount}
                        </td>
                        <td>{tx.status}</td>
                        <td>{new Date(tx.created_at).toLocaleDateString()}</td>
                      </tr>
                    ))}
                    {!profile.transactions?.length && (
                      <tr>
                        <td colSpan="4">No transactions yet.</td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  )
}

export default CompanyProfile
