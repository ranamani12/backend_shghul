import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import Modal from '../components/Modal'
import { get, post, put, normalizeStorageUrl } from '../api/client'
import { IconEdit, IconEye } from '../components/Icons'

const JobDetail = () => {
  const { id } = useParams()
  const [job, setJob] = useState(null)
  const [applicants, setApplicants] = useState([])
  const [activeTab, setActiveTab] = useState('details')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)

  // Candidate detail modal
  const [selectedCandidate, setSelectedCandidate] = useState(null)
  const [candidateModalOpen, setCandidateModalOpen] = useState(false)

  // Meeting scheduling modal
  const [meetingModalOpen, setMeetingModalOpen] = useState(false)
  const [meetingForm, setMeetingForm] = useState({
    application_id: '',
    candidate_id: '',
    scheduled_at: '',
    meeting_type: 'Physical',
    meeting_link: '',
    location: '',
    notes: '',
  })
  const [meetingError, setMeetingError] = useState('')
  const [isRescheduling, setIsRescheduling] = useState(false)
  const [existingMeetingId, setExistingMeetingId] = useState(null)

  const loadJob = async () => {
    setLoading(true)
    setError('')
    try {
      const jobData = await get(`/admin/jobs/${id}`)
      setJob(jobData.data || jobData)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  const loadApplicants = async () => {
    try {
      const data = await get(`/admin/jobs/${id}/applications`)
      setApplicants(data.data || data || [])
    } catch (err) {
      console.error('Failed to load applicants:', err)
    }
  }

  useEffect(() => {
    loadJob()
    loadApplicants()
  }, [id])

  const handleViewCandidate = (application) => {
    setSelectedCandidate(application)
    setCandidateModalOpen(true)
  }

  const handleScheduleMeeting = (application) => {
    setIsRescheduling(false)
    setExistingMeetingId(null)
    setMeetingForm({
      application_id: application.id,
      candidate_id: application.candidate_id,
      scheduled_at: '',
      meeting_type: job?.interview_type || 'Physical',
      meeting_link: '',
      location: '',
      notes: '',
    })
    setMeetingError('')
    setMeetingModalOpen(true)
  }

  const handleRescheduleMeeting = (application, meeting) => {
    setIsRescheduling(true)
    setExistingMeetingId(meeting.id)
    const scheduledDate = meeting.scheduled_at
      ? new Date(meeting.scheduled_at).toISOString().slice(0, 16)
      : ''
    setMeetingForm({
      application_id: application.id,
      candidate_id: application.candidate_id,
      scheduled_at: scheduledDate,
      meeting_type: meeting.meeting_type || 'Physical',
      meeting_link: meeting.meeting_link || '',
      location: meeting.location || '',
      notes: meeting.notes || '',
    })
    setMeetingError('')
    setMeetingModalOpen(true)
  }

  const handleMeetingFormChange = (e) => {
    setMeetingForm((prev) => ({ ...prev, [e.target.name]: e.target.value }))
  }

  const handleMeetingSubmit = async (e) => {
    e.preventDefault()
    setMeetingError('')
    try {
      const payload = {
        ...meetingForm,
        job_id: parseInt(id),
      }
      if (isRescheduling && existingMeetingId) {
        await put(`/admin/interviews/${existingMeetingId}`, payload)
      } else {
        await post('/admin/interviews', payload)
      }
      setMeetingModalOpen(false)
      loadApplicants()
    } catch (err) {
      setMeetingError(err.message)
    }
  }

  const handleUpdateApplicationStatus = async (applicationId, status) => {
    try {
      await put(`/admin/applications/${applicationId}`, { status })
      loadApplicants()
    } catch (err) {
      setError(err.message)
    }
  }

  const getStatusColor = (status) => {
    switch (status) {
      case 'pending':
        return 'draft'
      case 'reviewed':
        return 'open'
      case 'shortlisted':
        return 'open'
      case 'interviewed':
        return 'open'
      case 'hired':
        return 'active'
      case 'rejected':
        return 'closed'
      default:
        return ''
    }
  }

  const candidate = selectedCandidate?.candidate
  const candidateProfile = candidate?.candidate_profile

  if (loading) {
    return (
      <div>
        <div className="toolbar">
          <Link className="ghost-button" to="/jobs">
            Back to Jobs
          </Link>
        </div>
        <p>Loading...</p>
      </div>
    )
  }

  return (
    <div>
      <div className="toolbar">
        <Link className="ghost-button" to="/jobs">
          Back to Jobs
        </Link>
      </div>
      <h2>Job Details</h2>
      {error && <div className="error">{error}</div>}

      {job && (
        <div className="settings-section">
          <div className="settings-tabs">
            <button
              type="button"
              className={`tab-button ${activeTab === 'details' ? 'active' : ''}`}
              onClick={() => setActiveTab('details')}
            >
              Job Details
            </button>
            <button
              type="button"
              className={`tab-button ${activeTab === 'applicants' ? 'active' : ''}`}
              onClick={() => setActiveTab('applicants')}
            >
              Applicants ({applicants.length})
            </button>
          </div>

          {activeTab === 'details' && (
            <div className="settings-section">
              <div className="settings-card">
                <h4>Basic Information</h4>
                <div className="detail-grid">
                  <div className="detail-item">
                    <span className="detail-label">Job Title</span>
                    <span className="detail-value">{job.title || '-'}</span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Company</span>
                    <span className="detail-value">
                      {job.company?.company_profile?.company_name ||
                        job.company?.name ||
                        '-'}
                    </span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Status</span>
                    <span className="detail-value">
                      <span className={`status-pill ${job.status || ''}`}>
                        {job.status || '-'}
                      </span>
                    </span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Active</span>
                    <span className="detail-value">
                      <span
                        className={`status-pill ${job.is_active ? 'active' : 'closed'}`}
                      >
                        {job.is_active ? 'Yes' : 'No'}
                      </span>
                    </span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Salary Range</span>
                    <span className="detail-value">{job.salary_range || '-'}</span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Experience Level</span>
                    <span className="detail-value">{job.experience_level || '-'}</span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Employment Type</span>
                    <span className="detail-value">{job.employment_type || '-'}</span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Work Location</span>
                    <span className="detail-value">{job.job_type || '-'}</span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Hiring Type</span>
                    <span className="detail-value">{job.hiring_type || '-'}</span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Interview Type</span>
                    <span className="detail-value">{job.interview_type || '-'}</span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Created</span>
                    <span className="detail-value">
                      {job.created_at
                        ? new Date(job.created_at).toLocaleDateString()
                        : '-'}
                    </span>
                  </div>
                  <div className="detail-item">
                    <span className="detail-label">Updated</span>
                    <span className="detail-value">
                      {job.updated_at
                        ? new Date(job.updated_at).toLocaleDateString()
                        : '-'}
                    </span>
                  </div>
                </div>
              </div>

              <div className="settings-card">
                <h4>Description</h4>
                <div className="detail-grid">
                  <div className="detail-item full-row">
                    <span className="detail-label">Job Description</span>
                    <span className="detail-value" style={{ whiteSpace: 'pre-wrap' }}>
                      {job.description || '-'}
                    </span>
                  </div>
                </div>
              </div>

              {job.majors && job.majors.length > 0 && (
                <div className="settings-card">
                  <h4>Required Majors</h4>
                  <div className="skills-list">
                    {job.majors.map((major) => (
                      <span key={major.id} className="skill-tag">
                        {major.translations?.en ||
                          major.translations?.find((t) => t.locale === 'en')?.name ||
                          major.name ||
                          'Unknown'}
                      </span>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}

          {activeTab === 'applicants' && (
            <div className="settings-card">
              <h4>Applicants</h4>
              <div className="table-wrapper">
                <table className="applicants-table">
                  <thead>
                    <tr>
                      <th>Candidate</th>
                      <th>Applied</th>
                      <th>Status</th>
                      <th>Interview</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {applicants.map((app) => (
                      <tr key={app.id}>
                        <td>
                          <div className="applicant-name">
                            <img
                              className="applicant-avatar"
                              src={
                                app.candidate?.candidate_profile?.profile_image_path
                                  ? normalizeStorageUrl(
                                      app.candidate.candidate_profile.profile_image_path
                                    )
                                  : '/placeholder-avatar.svg'
                              }
                              alt=""
                            />
                            <div className="applicant-details">
                              <span className="name">{app.candidate?.name || '-'}</span>
                              <span className="email">{app.candidate?.email || '-'}</span>
                            </div>
                          </div>
                        </td>
                        <td>
                          {app.applied_at
                            ? new Date(app.applied_at).toLocaleDateString()
                            : app.created_at
                              ? new Date(app.created_at).toLocaleDateString()
                              : '-'}
                        </td>
                        <td>
                          <select
                            className={`status-select-sm ${app.status || 'pending'}`}
                            value={app.status || 'pending'}
                            onChange={(e) =>
                              handleUpdateApplicationStatus(app.id, e.target.value)
                            }
                          >
                            <option value="pending">Pending</option>
                            <option value="reviewed">Reviewed</option>
                            <option value="shortlisted">Shortlisted</option>
                            <option value="interviewed">Interviewed</option>
                            <option value="hired">Hired</option>
                            <option value="rejected">Rejected</option>
                          </select>
                        </td>
                        <td>
                          {app.interview ? (
                            <div className="interview-info">
                              <span
                                className={`status-pill ${app.interview.status || 'requested'}`}
                              >
                                {app.interview.status
                                  ? app.interview.status.charAt(0).toUpperCase() +
                                    app.interview.status.slice(1)
                                  : 'Scheduled'}
                              </span>
                              <span className="interview-time">
                                {app.interview.scheduled_at
                                  ? new Date(app.interview.scheduled_at).toLocaleString()
                                  : '-'}
                              </span>
                            </div>
                          ) : (
                            <span className="muted">—</span>
                          )}
                        </td>
                        <td>
                          <div className="actions">
                            <button
                              className="ghost-button"
                              onClick={() => handleViewCandidate(app)}
                              title="View Candidate"
                              aria-label="View Candidate"
                            >
                              <span className="action-icon" aria-hidden="true">
                                <IconEye />
                              </span>
                            </button>
                            {app.interview ? (
                              <button
                                className="ghost-button"
                                onClick={() => handleRescheduleMeeting(app, app.interview)}
                                title="Reschedule Interview"
                                aria-label="Reschedule Interview"
                              >
                                <span className="action-icon" aria-hidden="true">
                                  <IconEdit />
                                </span>
                              </button>
                            ) : (
                              <button
                                className="ghost-button primary-text"
                                onClick={() => handleScheduleMeeting(app)}
                                title="Schedule Interview"
                                aria-label="Schedule Interview"
                                style={{ fontSize: '11px', padding: '4px 8px', width: 'auto' }}
                              >
                                Schedule
                              </button>
                            )}
                          </div>
                        </td>
                      </tr>
                    ))}
                    {!applicants.length && (
                      <tr>
                        <td colSpan="5">No applicants yet.</td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Candidate Detail Modal */}
      <Modal
        isOpen={candidateModalOpen}
        title="Candidate Details"
        onClose={() => setCandidateModalOpen(false)}
      >
        {selectedCandidate && candidate && (
          <div className="candidate-detail-modal">
            <div className="profile-header" style={{ marginBottom: '20px' }}>
              <img
                className="profile-avatar"
                src={
                  normalizeStorageUrl(candidateProfile?.profile_image_path) ||
                  '/placeholder-avatar.svg'
                }
                alt="Candidate"
                style={{ width: '64px', height: '64px' }}
              />
              <div className="profile-meta">
                <h3 style={{ margin: 0 }}>{candidate.name || '-'}</h3>
                <span className="muted">{candidate.email || '-'}</span>
                <div style={{ marginTop: '4px' }}>
                  <span
                    className={`status-pill ${getStatusColor(selectedCandidate.status)}`}
                  >
                    {selectedCandidate.status || 'pending'}
                  </span>
                </div>
              </div>
            </div>

            <div className="detail-grid" style={{ marginBottom: '16px' }}>
              <div className="detail-item">
                <span className="detail-label">Mobile</span>
                <span className="detail-value">
                  {candidateProfile?.mobile_number || '-'}
                </span>
              </div>
              <div className="detail-item">
                <span className="detail-label">Experience</span>
                <span className="detail-value">
                  {candidateProfile?.years_of_experience?.translations?.find(
                    (t) => t.locale === 'en'
                  )?.name || '-'}
                </span>
              </div>
              <div className="detail-item">
                <span className="detail-label">Education</span>
                <span className="detail-value">
                  {candidateProfile?.education_level?.translations?.find(
                    (t) => t.locale === 'en'
                  )?.name || '-'}
                </span>
              </div>
              <div className="detail-item">
                <span className="detail-label">Availability</span>
                <span className="detail-value">
                  {candidateProfile?.availability || '-'}
                </span>
              </div>
            </div>

            {candidateProfile?.major_lookups?.length > 0 && (
              <div style={{ marginBottom: '16px' }}>
                <span
                  className="detail-label"
                  style={{ display: 'block', marginBottom: '8px' }}
                >
                  Majors
                </span>
                <div className="skills-list">
                  {candidateProfile.major_lookups.map((major) => (
                    <span key={major.id} className="skill-tag">
                      {major.translations?.find((t) => t.locale === 'en')?.name ||
                        'Unknown'}
                    </span>
                  ))}
                </div>
              </div>
            )}

            {candidateProfile?.skills?.length > 0 && (
              <div style={{ marginBottom: '16px' }}>
                <span
                  className="detail-label"
                  style={{ display: 'block', marginBottom: '8px' }}
                >
                  Skills
                </span>
                <div className="skills-list">
                  {candidateProfile.skills.map((skill, idx) => (
                    <span key={idx} className="skill-tag">
                      {skill}
                    </span>
                  ))}
                </div>
              </div>
            )}

            {candidateProfile?.summary && (
              <div style={{ marginBottom: '16px' }}>
                <span
                  className="detail-label"
                  style={{ display: 'block', marginBottom: '8px' }}
                >
                  Summary
                </span>
                <p style={{ margin: 0, whiteSpace: 'pre-wrap' }}>
                  {candidateProfile.summary}
                </p>
              </div>
            )}

            <div className="modal-actions">
              {candidateProfile?.cv_path && (
                <a
                  href={normalizeStorageUrl(candidateProfile.cv_path)}
                  target="_blank"
                  rel="noreferrer"
                  className="ghost-button"
                >
                  View CV
                </a>
              )}
              <Link
                to={`/candidates/${candidate.id}`}
                className="primary-button"
                onClick={() => setCandidateModalOpen(false)}
              >
                Full Profile
              </Link>
            </div>
          </div>
        )}
      </Modal>

      {/* Meeting Scheduling Modal */}
      <Modal
        isOpen={meetingModalOpen}
        title={isRescheduling ? 'Reschedule Interview' : 'Schedule Interview'}
        onClose={() => setMeetingModalOpen(false)}
      >
        {meetingError && <div className="error">{meetingError}</div>}
        <form className="form-grid" onSubmit={handleMeetingSubmit}>
          <label>
            <span>Date & Time</span>
            <input
              type="datetime-local"
              name="scheduled_at"
              value={meetingForm.scheduled_at}
              onChange={handleMeetingFormChange}
              required
            />
          </label>
          <label>
            <span>Interview Type</span>
            <select
              name="meeting_type"
              value={meetingForm.meeting_type}
              onChange={handleMeetingFormChange}
            >
              <option value="Physical">Physical</option>
              <option value="Online">Online</option>
            </select>
          </label>
          {meetingForm.meeting_type === 'Online' && (
            <label className="full-row">
              <span>Meeting Link</span>
              <input
                type="url"
                name="meeting_link"
                placeholder="https://meet.google.com/..."
                value={meetingForm.meeting_link}
                onChange={handleMeetingFormChange}
              />
            </label>
          )}
          {meetingForm.meeting_type === 'Physical' && (
            <label className="full-row">
              <span>Location</span>
              <input
                type="text"
                name="location"
                placeholder="Office address or location"
                value={meetingForm.location}
                onChange={handleMeetingFormChange}
              />
            </label>
          )}
          <label className="full-row">
            <span>Notes</span>
            <textarea
              name="notes"
              placeholder="Additional notes for the interview..."
              rows="3"
              value={meetingForm.notes}
              onChange={handleMeetingFormChange}
            />
          </label>
          <button className="primary-button" type="submit">
            {isRescheduling ? 'Reschedule' : 'Schedule Interview'}
          </button>
        </form>
      </Modal>
    </div>
  )
}

export default JobDetail
