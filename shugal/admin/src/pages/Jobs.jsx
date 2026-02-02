import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import Modal from '../components/Modal'
import { get, post, del, put } from '../api/client'
import { IconEdit, IconEye, IconTrash } from '../components/Icons'

const emptyForm = {
  company_id: '',
  title: '',
  description: '',
  salary_range: '',
  experience_level: '',
  hiring_type: '',
  employment_type: '',
  job_type: '',
  interview_type: 'Physical',
  major_ids: [],
  status: 'open',
  is_active: 'true',
}

const experienceLevels = [
  '0-1 Years',
  '1-3 Years',
  '3-5 Years',
  '5-7 Years',
  '7+ Years',
]

const hiringTypes = ['Immediate', 'Within 1 Month', 'Within 3 Months', 'Flexible']

const employmentTypes = ['Full-time', 'Part-time', 'Contract']

const jobTypes = ['Remote', 'On-site', 'Hybrid']

const interviewTypes = ['Physical', 'Online']

const Jobs = () => {
  const [jobs, setJobs] = useState([])
  const [companies, setCompanies] = useState([])
  const [majors, setMajors] = useState([])
  const [form, setForm] = useState(emptyForm)
  const [editingId, setEditingId] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [isMajorDropdownOpen, setIsMajorDropdownOpen] = useState(false)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)

  const load = async () => {
    setLoading(true)
    setError('')
    try {
      const [jobsData, companiesData, majorsData] = await Promise.all([
        get('/admin/jobs'),
        get('/admin/companies?per_page=200'),
        get('/admin/lookups?type=major'),
      ])
      setJobs(jobsData.data || [])
      setCompanies(companiesData.data || [])
      setMajors(Array.isArray(majorsData) ? majorsData : majorsData.data || [])
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
    setForm((prev) => ({ ...prev, [event.target.name]: event.target.value }))
  }

  const handleMajorChange = (majorId) => {
    setForm((prev) => {
      const currentIds = prev.major_ids || []
      if (currentIds.includes(majorId)) {
        return { ...prev, major_ids: currentIds.filter((id) => id !== majorId) }
      } else {
        return { ...prev, major_ids: [...currentIds, majorId] }
      }
    })
  }

  const getMajorName = (majorId) => {
    const major = majors.find((m) => m.id === majorId)
    return major?.translations?.en || major?.name || major?.name_en || 'Unknown'
  }

  const removeMajor = (majorId) => {
    setForm((prev) => ({
      ...prev,
      major_ids: prev.major_ids.filter((id) => id !== majorId),
    }))
  }

  const handleSubmit = async (event) => {
    event.preventDefault()
    setError('')
    setSubmitting(true)
    try {
      const payload = {
        ...form,
        company_id: Number(form.company_id),
        is_active: form.is_active === 'true',
        major_ids: form.major_ids.length > 0 ? form.major_ids : undefined,
      }
      if (editingId) {
        await put(`/admin/jobs/${editingId}`, payload)
      } else {
        await post('/admin/jobs', payload)
      }
      setForm(emptyForm)
      setEditingId(null)
      setIsModalOpen(false)
      load()
    } catch (err) {
      setError(err.message)
    } finally {
      setSubmitting(false)
    }
  }

  const handleEdit = (job) => {
    setEditingId(job.id)
    setForm({
      company_id: job.company_id || '',
      title: job.title || '',
      description: job.description || '',
      salary_range: job.salary_range || '',
      experience_level: job.experience_level || '',
      hiring_type: job.hiring_type || '',
      employment_type: job.employment_type || '',
      job_type: job.job_type || '',
      interview_type: job.interview_type || 'Physical',
      major_ids: job.major_ids || (job.majors ? job.majors.map((m) => m.id) : []),
      status: job.status || 'open',
      is_active: job.is_active ? 'true' : 'false',
    })
    setIsModalOpen(true)
  }

  const handleCancelEdit = () => {
    setEditingId(null)
    setForm(emptyForm)
    setIsModalOpen(false)
  }

  const handleDelete = async (job) => {
    if (!window.confirm('Delete this job?')) return
    try {
      await del(`/admin/jobs/${job.id}`)
      load()
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <div>
      <h2>Jobs</h2>
      <Modal
        isOpen={isModalOpen}
        title={editingId ? 'Edit Job' : 'Create Job'}
        onClose={handleCancelEdit}
      >
        <form onSubmit={handleSubmit}>
          <fieldset className="form-grid" disabled={submitting}>
          <label>
            <span>Company</span>
            <select
              name="company_id"
              value={form.company_id}
              onChange={handleChange}
              required
            >
              <option value="">Select company</option>
              {companies.map((company) => (
                <option key={company.id} value={company.id}>
                  {company.company_profile?.company_name || company.name} (
                  {company.email})
                </option>
              ))}
            </select>
          </label>
          <label>
            <span>Job Title</span>
            <input
              name="title"
              placeholder="Enter job title"
              value={form.title}
              onChange={handleChange}
              required
            />
          </label>
          <label>
            <span>Salary Range</span>
            <input
              name="salary_range"
              placeholder="e.g., 500-1000 KWD"
              value={form.salary_range}
              onChange={handleChange}
            />
          </label>
          <label>
            <span>Experience Level</span>
            <select
              name="experience_level"
              value={form.experience_level}
              onChange={handleChange}
            >
              <option value="">Select experience level</option>
              {experienceLevels.map((level) => (
                <option key={level} value={level}>
                  {level}
                </option>
              ))}
            </select>
          </label>
          <label>
            <span>Hiring Type</span>
            <select
              name="hiring_type"
              value={form.hiring_type}
              onChange={handleChange}
            >
              <option value="">Select hiring type</option>
              {hiringTypes.map((type) => (
                <option key={type} value={type}>
                  {type}
                </option>
              ))}
            </select>
          </label>
          <label>
            <span>Employment Type</span>
            <select
              name="employment_type"
              value={form.employment_type}
              onChange={handleChange}
            >
              <option value="">Select employment type</option>
              {employmentTypes.map((type) => (
                <option key={type} value={type}>
                  {type}
                </option>
              ))}
            </select>
          </label>
          <label>
            <span>Work Location</span>
            <select name="job_type" value={form.job_type} onChange={handleChange}>
              <option value="">Select work location</option>
              {jobTypes.map((type) => (
                <option key={type} value={type}>
                  {type}
                </option>
              ))}
            </select>
          </label>
          <label>
            <span>Interview Type</span>
            <select
              name="interview_type"
              value={form.interview_type}
              onChange={handleChange}
            >
              {interviewTypes.map((type) => (
                <option key={type} value={type}>
                  {type}
                </option>
              ))}
            </select>
          </label>
          <label>
            <span>Status</span>
            <select name="status" value={form.status} onChange={handleChange}>
              <option value="open">Open</option>
              <option value="closed">Closed</option>
              <option value="draft">Draft</option>
            </select>
          </label>
          <label>
            <span>Active</span>
            <select name="is_active" value={form.is_active} onChange={handleChange}>
              <option value="true">Active</option>
              <option value="false">Inactive</option>
            </select>
          </label>
          <label className="full-row">
            <span>Job Description</span>
            <textarea
              name="description"
              placeholder="Enter job description"
              rows="3"
              value={form.description}
              onChange={handleChange}
              required
            />
          </label>
          <div className="form-field-full">
            <span className="field-label">Majors</span>
            <div className="multi-select-container">
              <div
                className="multi-select-trigger"
                onClick={() => setIsMajorDropdownOpen(!isMajorDropdownOpen)}
              >
                {form.major_ids.length === 0 ? (
                  <span className="multi-select-placeholder">Select majors</span>
                ) : (
                  <div className="selected-tags">
                    {form.major_ids.map((id) => (
                      <span key={id} className="selected-tag">
                        {getMajorName(id)}
                        <button
                          type="button"
                          className="tag-remove"
                          onClick={(e) => {
                            e.stopPropagation()
                            removeMajor(id)
                          }}
                        >
                          ×
                        </button>
                      </span>
                    ))}
                  </div>
                )}
                <span className="multi-select-arrow">▼</span>
              </div>
              {isMajorDropdownOpen && (
                <div className="multi-select-dropdown">
                  {majors.map((major) => (
                    <label key={major.id} className="dropdown-option">
                      <input
                        type="checkbox"
                        checked={form.major_ids.includes(major.id)}
                        onChange={() => handleMajorChange(major.id)}
                      />
                      {major.translations?.en || major.name || major.name_en || 'Unknown'}
                    </label>
                  ))}
                  {majors.length === 0 && (
                    <span className="dropdown-empty">No majors available</span>
                  )}
                </div>
              )}
            </div>
          </div>
          <button className="primary-button" type="submit" disabled={submitting}>
            {submitting ? (
              <>
                <span className="spinner"></span>
                {editingId ? 'Updating...' : 'Creating...'}
              </>
            ) : (
              editingId ? 'Update' : 'Create'
            )}
          </button>
          </fieldset>
        </form>
      </Modal>
      {error && <div className="error">{error}</div>}
      <div className="toolbar">
        <button
          className="primary-button"
          onClick={() => {
            setEditingId(null)
            setForm(emptyForm)
            setIsModalOpen(true)
          }}
        >
          Create Job
        </button>
      </div>
      {loading ? (
        <p>Loading...</p>
      ) : (
        <div className="table-wrapper">
          <table>
            <thead>
              <tr>
                <th>Title</th>
                <th>Company</th>
                <th>Status</th>
                <th>Created</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {jobs.map((job) => (
                <tr key={job.id}>
                  <td>{job.title}</td>
                  <td>{job.company?.name || job.company_id}</td>
                  <td>
                    <span className={`status-pill ${job.status}`}>
                      {job.status}
                    </span>
                  </td>
                  <td>{new Date(job.created_at).toLocaleDateString()}</td>
                  <td className="actions">
                    <Link
                      to={`/jobs/${job.id}`}
                      className="ghost-button"
                      title="View"
                      aria-label="View"
                    >
                      <span className="action-icon" aria-hidden="true">
                        <IconEye />
                      </span>
                    </Link>
                    <button
                      className="ghost-button"
                      onClick={() => handleEdit(job)}
                      title="Edit"
                      aria-label="Edit"
                    >
                      <span className="action-icon" aria-hidden="true">
                        <IconEdit />
                      </span>
                    </button>
                    <button
                      className="danger-button"
                      onClick={() => handleDelete(job)}
                      title="Delete"
                      aria-label="Delete"
                    >
                      <span className="action-icon" aria-hidden="true">
                        <IconTrash />
                      </span>
                    </button>
                  </td>
                </tr>
              ))}
              {!jobs.length && (
                <tr>
                  <td colSpan="5">No jobs found.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

export default Jobs
