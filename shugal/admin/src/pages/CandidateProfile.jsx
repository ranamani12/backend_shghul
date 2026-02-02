import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { get, normalizeStorageUrl } from '../api/client'

const CandidateProfile = () => {
  const { id } = useParams()
  const [profile, setProfile] = useState(null)
  const [activeTab, setActiveTab] = useState('overview')
  const [error, setError] = useState('')

  useEffect(() => {
    const load = async () => {
      setError('')
      try {
        const data = await get(`/admin/candidates/${id}`)
        setProfile(data)
      } catch (err) {
        setError(err.message)
      }
    }
    load()
  }, [id])

  const candidate = profile?.candidate
  const profileData = candidate?.candidate_profile
  const nationalityCountry = profileData?.nationality_country
  const residentCountry = profileData?.resident_country
  const nationalityName = nationalityCountry?.translations?.find((t) => t.locale === 'en')?.name || nationalityCountry?.code || '-'
  const residentName = residentCountry?.translations?.find((t) => t.locale === 'en')?.name || residentCountry?.code || '-'
  const yearsOfExperience = profileData?.years_of_experience
  const yearsOfExperienceName = yearsOfExperience?.translations?.find((t) => t.locale === 'en')?.name || '-'
  const educationLevel = profileData?.education_level
  const educationLevelName = educationLevel?.translations?.find((t) => t.locale === 'en')?.name || '-'
  const majorLookups = profileData?.major_lookups || []
  const majorNames = majorLookups.map((lookup) => lookup.translations?.find((t) => t.locale === 'en')?.name || '').filter(Boolean)

  return (
    <div>
      <div className="toolbar">
        <Link className="ghost-button" to="/candidates">
          Back to Candidates
        </Link>
      </div>
      <h2>Candidate Profile</h2>
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
                <h4>Candidate Profile</h4>
                <div className="profile-header">
                  <img
                    className="profile-avatar"
                    src={normalizeStorageUrl(profileData?.profile_image_path) || '/placeholder-avatar.svg'}
                    alt="Candidate"
                  />
                  <div className="profile-meta">
                    <h3>{candidate?.name || '-'}</h3>
                    <div className="profile-meta-row">
                      <span className={`status-pill ${candidate?.status || ''}`}>
                        {candidate?.status || '-'}
                      </span>
                      <span className="muted">Code: {candidate?.unique_code || '-'}</span>
                      {profileData?.is_activated && (
                        <span className="status-pill active">Activated</span>
                      )}
                    </div>
                    <span className="muted">{candidate?.email || '-'}</span>
                  </div>
                </div>
              </div>

              <div className="settings-card">
                <h4>Personal Details</h4>
                <div className="detail-grid">
                  <div className="detail-item">
                    <span className="detail-label">Full Name</span>
                    <span className="detail-value">{candidate?.name || '-'}</span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Email</span>
                    <span className="detail-value">{candidate?.email || '-'}</span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Mobile Number</span>
                    <span className="detail-value">{profileData?.mobile_number || '-'}</span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Nationality</span>
                    <span className="detail-value">
                      {nationalityCountry?.flag_path ? (
                        <span className="search-option-content">
                          <img className="flag-thumb" src={nationalityCountry.flag_path} alt="" />
                          {nationalityName}
                        </span>
                      ) : (
                        nationalityName
                      )}
                    </span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Resident Country</span>
                    <span className="detail-value">
                      {residentCountry?.flag_path ? (
                        <span className="search-option-content">
                          <img className="flag-thumb" src={residentCountry.flag_path} alt="" />
                          {residentName}
                        </span>
                      ) : (
                        residentName
                      )}
                    </span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Status</span>
                    <span className="detail-value">
                      <span className={`status-pill ${candidate?.status || ''}`}>
                        {candidate?.status || '-'}
                      </span>
                    </span>
                  </div>
                </div>
              </div>

              <div className="settings-card">
                <h4>Experience & Education</h4>
                <div className="detail-grid">
                  <div className="detail-item">
                    <span className="detail-label">Years of Experience</span>
                    <span className="detail-value">
                      {yearsOfExperienceName !== '-' ? yearsOfExperienceName : '-'}
                    </span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Education Level</span>
                    <span className="detail-value">
                      {educationLevelName !== '-' ? educationLevelName : '-'}
                    </span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Availability</span>
                    <span className="detail-value">{profileData?.availability || '-'}</span>
                  </div>
                </div>
              </div>

              <div className="settings-card">
                <h4>Professional Details</h4>
                <div className="detail-grid">
                  <div className="detail-item full-row">
                    <span className="detail-label">Major/Field</span>
                    <span className="detail-value">
                      {majorNames.length ? (
                        <div className="skills-list">
                          {majorNames.map((name, idx) => (
                            <span key={idx} className="skill-tag">
                              {name}
                            </span>
                          ))}
                        </div>
                      ) : (
                        '-'
                      )}
                    </span>
                  </div>
                  <div className="detail-item full-row">
                    <span className="detail-label">Skills</span>
                    <span className="detail-value">
                      {profileData?.skills?.length ? (
                        <div className="skills-list">
                          {profileData.skills.map((skill, idx) => (
                            <span key={idx} className="skill-tag">
                              {skill}
                            </span>
                          ))}
                        </div>
                      ) : (
                        '-'
                      )}
                    </span>
                  </div>
                  <div className="detail-item full-row">
                    <span className="detail-label">Summary</span>
                    <span className="detail-value">{profileData?.summary || '-'}</span>
                  </div>
                </div>
              </div>

              <div className="settings-card">
                <h4>Documents</h4>
                <div className="detail-grid">
                  <div className="detail-item">
                    <span className="detail-label">Profile Image</span>
                    {profileData?.profile_image_path ? (
                      <div className="flag-preview">
                        <img src={normalizeStorageUrl(profileData.profile_image_path)} alt="Profile" />
                        <span className="muted">Profile image</span>
                      </div>
                    ) : (
                      <span className="detail-value">-</span>
                    )}
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">CV/Resume</span>
                    {profileData?.cv_path ? (
                      <div className="license-preview">
                        <a href={normalizeStorageUrl(profileData.cv_path)} target="_blank" rel="noreferrer">
                          View CV/Resume
                        </a>
                      </div>
                    ) : (
                      <span className="detail-value">-</span>
                    )}
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Public Slug</span>
                    <span className="detail-value">{profileData?.public_slug || '-'}</span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Upwork Profile</span>
                    <span className="detail-value">
                      {profileData?.upwork_profile_url ? (
                        <a href={profileData.upwork_profile_url} target="_blank" rel="noreferrer">
                          {profileData.upwork_profile_url}
                        </a>
                      ) : (
                        '-'
                      )}
                    </span>
                  </div>
                  {profileData?.activated_at && (
                    <div className="detail-item">
                      <span className="detail-label">Activated At</span>
                      <span className="detail-value">
                        {new Date(profileData.activated_at).toLocaleString()}
                      </span>
                    </div>
                  )}
                </div>
              </div>
            </div>
          )}

          {activeTab === 'unlocks' && (
            <div className="settings-card">
              <h4>Unlocked By Companies</h4>
              <div className="table-wrapper">
                <table>
                  <thead>
                    <tr>
                      <th>Company</th>
                      <th>Unlocked At</th>
                      <th>Transaction</th>
                    </tr>
                  </thead>
                  <tbody>
                    {profile.unlocks?.map((unlock) => (
                      <tr key={unlock.id}>
                        <td>
                          {unlock.company?.company_profile?.company_name ||
                            unlock.company?.name}
                        </td>
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
                      <th>Company</th>
                      <th>Status</th>
                      <th>Applied</th>
                    </tr>
                  </thead>
                  <tbody>
                    {profile.applications?.map((app) => (
                      <tr key={app.id}>
                        <td>{app.job?.title || '-'}</td>
                        <td>
                          {app.job?.company?.company_profile?.company_name ||
                            app.job?.company?.name ||
                            '-'}
                        </td>
                        <td>
                          <span className={`status-pill ${app.status || ''}`}>
                            {app.status || '-'}
                          </span>
                        </td>
                        <td>
                          {app.applied_at
                            ? new Date(app.applied_at).toLocaleDateString()
                            : '-'}
                        </td>
                      </tr>
                    ))}
                    {!profile.applications?.length && (
                      <tr>
                        <td colSpan="4">No applications yet.</td>
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
                      <th>Reference</th>
                      <th>Created</th>
                    </tr>
                  </thead>
                  <tbody>
                    {profile.transactions?.map((tx) => (
                      <tr key={tx.id}>
                        <td>{tx.type || '-'}</td>
                        <td>
                          {tx.currency || 'KWD'} {tx.amount || '0.00'}
                        </td>
                        <td>
                          <span className={`status-pill ${tx.status || ''}`}>
                            {tx.status || '-'}
                          </span>
                        </td>
                        <td>{tx.reference || '-'}</td>
                        <td>
                          {tx.created_at
                            ? new Date(tx.created_at).toLocaleDateString()
                            : '-'}
                        </td>
                      </tr>
                    ))}
                    {!profile.transactions?.length && (
                      <tr>
                        <td colSpan="5">No transactions yet.</td>
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

export default CandidateProfile
