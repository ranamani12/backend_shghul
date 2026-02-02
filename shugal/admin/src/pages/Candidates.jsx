import { useEffect, useState, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import Modal from '../components/Modal'
import { IconEdit, IconEye, IconToggle, IconTrash } from '../components/Icons'
import { del, get, patch, upload, normalizeStorageUrl } from '../api/client'

const emptyForm = {
  name: '',
  email: '',
  password: '',
  status: 'active',
  major_ids: [],
  years_of_experience_id: '',
  mobile_number: '',
  education_id: '',
  nationality_country_id: '',
  resident_country_id: '',
  skills: [],
  profile_image: null,
  cv_file: null,
  existing_profile_image: '',
  existing_cv: '',
  availability: '',
  summary: '',
  public_slug: '',
  upwork_profile_url: '',
}

const TagInput = ({ value, onChange, placeholder }) => {
  const [input, setInput] = useState('')

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' || e.key === ',') {
      e.preventDefault()
      const trimmed = input.trim()
      if (trimmed && !value.includes(trimmed)) {
        onChange([...value, trimmed])
      }
      setInput('')
    } else if (e.key === 'Backspace' && !input && value.length > 0) {
      onChange(value.slice(0, -1))
    }
  }

  const removeTag = (index) => {
    onChange(value.filter((_, i) => i !== index))
  }

  return (
    <div className="tag-input-container">
      <div className="tag-input-tags">
        {value.map((tag, index) => (
          <span key={index} className="tag">
            {tag}
            <button type="button" className="tag-remove" onClick={() => removeTag(index)}>
              ×
            </button>
          </span>
        ))}
        <input
          className="tag-input"
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder={value.length === 0 ? placeholder : ''}
        />
      </div>
    </div>
  )
}

const SearchableSelect = ({
  value,
  onChange,
  options,
  placeholder,
  renderOption,
}) => {
  const [query, setQuery] = useState('')
  const [open, setOpen] = useState(false)

  const current = options.find((option) => option.value === value)
  const displayValue = open ? query : current?.label || ''

  const filtered = options.filter((option) =>
    option.label.toLowerCase().includes(query.toLowerCase()),
  )

  const handleSelect = (option) => {
    onChange(option.value)
    setQuery(option.label)
    setOpen(false)
  }

  return (
    <div className="search-select">
      <input
        className="search-input"
        value={displayValue}
        placeholder={placeholder}
        onChange={(event) => {
          setQuery(event.target.value)
          setOpen(true)
        }}
        onFocus={() => setOpen(true)}
        onBlur={() => setTimeout(() => setOpen(false), 150)}
      />
      {open && (
        <div className="search-dropdown">
          {filtered.length ? (
            filtered.map((option) => (
              <button
                key={option.value}
                type="button"
                className="search-option"
                onClick={() => handleSelect(option)}
              >
                {renderOption ? renderOption(option) : option.label}
              </button>
            ))
          ) : (
            <div className="search-empty">No results</div>
          )}
        </div>
      )}
    </div>
  )
}

const SearchableMultiSelect = ({ value, onChange, options, placeholder }) => {
  const [query, setQuery] = useState('')
  const [open, setOpen] = useState(false)

  const filtered = options.filter((option) =>
    option.label.toLowerCase().includes(query.toLowerCase()),
  )

  const toggleValue = (optionValue) => {
    const current = value || []
    if (current.includes(optionValue)) {
      onChange(current.filter((v) => v !== optionValue))
    } else {
      onChange([...current, optionValue])
    }
  }

  const selectedLabels = (value || [])
    .map((v) => options.find((opt) => opt.value === v)?.label)
    .filter(Boolean)
    .join(', ')

  const displayValue = open ? query : selectedLabels || ''

  return (
    <div className="search-select">
      <input
        className="search-input"
        value={displayValue}
        placeholder={placeholder}
        onChange={(event) => {
          setQuery(event.target.value)
          setOpen(true)
        }}
        onFocus={() => setOpen(true)}
        onBlur={() => setTimeout(() => setOpen(false), 150)}
      />
      {open && (
        <div className="search-dropdown">
          {filtered.length ? (
            filtered.map((option) => {
              const checked = (value || []).includes(option.value)
              return (
                <button
                  key={option.value}
                  type="button"
                  className="search-option"
                  onClick={() => toggleValue(option.value)}
                >
                  <input
                    className="search-option-checkbox"
                    type="checkbox"
                    checked={checked}
                    readOnly
                  />
                  <span>{option.label}</span>
                </button>
              )
            })
          ) : (
            <div className="search-empty">No results</div>
          )}
        </div>
      )}
    </div>
  )
}

const Candidates = () => {
  const [candidates, setCandidates] = useState([])
  const [query, setQuery] = useState('')
  const [status, setStatus] = useState('')
  const [form, setForm] = useState(emptyForm)
  const [editingId, setEditingId] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [listError, setListError] = useState('')
  const [modalError, setModalError] = useState('')
  const [loading, setLoading] = useState(true)
  const [countries, setCountries] = useState([])
  const [lookups, setLookups] = useState({
    majors: [],
    experiences: [],
    education: [],
  })
  const [imagePreview, setImagePreview] = useState(null)
  const [submitting, setSubmitting] = useState(false)
  const profileImageRef = useRef(null)
  const cvFileRef = useRef(null)
  const navigate = useNavigate()

  const load = async () => {
    setLoading(true)
    setListError('')
    try {
      const params = new URLSearchParams()
      if (query) params.set('q', query)
      if (status) params.set('status', status)
      const data = await get(`/admin/candidates?${params.toString()}`)
      setCandidates(data.data || [])
    } catch (err) {
      setListError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
    loadCountries()
    loadLookups()
  }, [])

  const loadCountries = async () => {
    try {
      const data = await get('/admin/countries')
      setCountries(data)
    } catch (err) {
      // Countries are optional for candidate creation
    }
  }

  const loadLookups = async () => {
    try {
      const [majors, experiences, education] = await Promise.all([
        get('/admin/lookups?type=major'),
        get('/admin/lookups?type=experience_year'),
        get('/admin/lookups?type=education_level'),
      ])
      setLookups({ majors, experiences, education })
    } catch (err) {
      // Lookups are optional for candidate creation
    }
  }

  const handleStatus = async (candidate, nextStatus) => {
    try {
      await patch(`/admin/candidates/${candidate.id}/status`, {
        status: nextStatus,
      })
      load()
    } catch (err) {
      setListError(err.message)
    }
  }

  const handleFormChange = (event) => {
    setForm((prev) => ({ ...prev, [event.target.name]: event.target.value }))
  }

  const handleEdit = (candidate) => {
    setEditingId(candidate.id)
    setModalError('')
    const existingImage = candidate.candidate_profile?.profile_image_path
    setForm({
      name: candidate.name || '',
      email: candidate.email || '',
      password: '',
      status: candidate.status || 'active',
      major_ids: candidate.candidate_profile?.major_ids || [],
      years_of_experience_id: String(candidate.candidate_profile?.years_of_experience_id || ''),
      mobile_number: candidate.candidate_profile?.mobile_number || '',
      education_id: String(candidate.candidate_profile?.education_id || ''),
      nationality_country_id:
        String(candidate.candidate_profile?.nationality_country_id || ''),
      resident_country_id: String(candidate.candidate_profile?.resident_country_id || ''),
      skills: candidate.candidate_profile?.skills || [],
      profile_image: null,
      cv_file: null,
      existing_profile_image: existingImage || '',
      existing_cv: candidate.candidate_profile?.cv_path || '',
      availability: candidate.candidate_profile?.availability || '',
      summary: candidate.candidate_profile?.summary || '',
      public_slug: candidate.candidate_profile?.public_slug || '',
      upwork_profile_url: candidate.candidate_profile?.upwork_profile_url || '',
    })
    setImagePreview(existingImage ? normalizeStorageUrl(existingImage) : null)
    setIsModalOpen(true)
  }

  const handleCancelEdit = () => {
    setEditingId(null)
    setForm(emptyForm)
    setIsModalOpen(false)
    setModalError('')
    setImagePreview(null)
    setSubmitting(false)
    if (profileImageRef.current) profileImageRef.current.value = ''
    if (cvFileRef.current) cvFileRef.current.value = ''
  }

  const handleImageChange = (e) => {
    const file = e.target.files[0]
    if (file) {
      setForm((prev) => ({ ...prev, profile_image: file }))
      const reader = new FileReader()
      reader.onloadend = () => setImagePreview(reader.result)
      reader.readAsDataURL(file)
    }
  }

  const handleCvChange = (e) => {
    const file = e.target.files[0]
    if (file) {
      setForm((prev) => ({ ...prev, cv_file: file }))
    }
  }

  const handleSubmit = async (event) => {
    event.preventDefault()
    setModalError('')
    setSubmitting(true)

    const formData = new FormData()
    formData.append('name', form.name)
    formData.append('email', form.email)
    formData.append('status', form.status)

    if (form.password) {
      formData.append('password', form.password)
    }

    // Profile fields
    if (form.major_ids && form.major_ids.length) {
      form.major_ids.forEach((id) => formData.append('profile[major_ids][]', Number(id)))
    }
    if (form.years_of_experience_id) {
      formData.append('profile[years_of_experience_id]', Number(form.years_of_experience_id))
    }
    if (form.mobile_number) {
      formData.append('profile[mobile_number]', form.mobile_number)
    }
    if (form.education_id) {
      formData.append('profile[education_id]', Number(form.education_id))
    }
    if (form.nationality_country_id) {
      formData.append('profile[nationality_country_id]', Number(form.nationality_country_id))
    }
    if (form.resident_country_id) {
      formData.append('profile[resident_country_id]', Number(form.resident_country_id))
    }
    if (form.availability) {
      formData.append('profile[availability]', form.availability)
    }
    if (form.summary) {
      formData.append('profile[summary]', form.summary)
    }
    if (form.public_slug) {
      formData.append('profile[public_slug]', form.public_slug)
    }
    if (form.upwork_profile_url) {
      formData.append('profile[upwork_profile_url]', form.upwork_profile_url)
    }

    // Skills (comma-separated string) - only send if there are skills
    if (form.skills && form.skills.length > 0) {
      formData.append('skills', form.skills.join(','))
    }

    // Files
    if (form.profile_image) {
      formData.append('profile_image', form.profile_image)
    }
    if (form.cv_file) {
      formData.append('cv_file', form.cv_file)
    }

    try {
      if (editingId) {
        // Use POST directly for file uploads
        await upload(`/admin/candidates/${editingId}`, formData, 'POST')
      } else {
        await upload('/admin/candidates', formData)
      }
      handleCancelEdit()
      load()
    } catch (err) {
      setModalError(err.message)
    } finally {
      setSubmitting(false)
    }
  }

  const handleDelete = async (candidate) => {
    if (!window.confirm('Delete this candidate?')) return
    try {
      await del(`/admin/candidates/${candidate.id}`)
      load()
    } catch (err) {
      setListError(err.message)
    }
  }

  const handleViewProfile = (candidate) => {
    navigate(`/candidates/${candidate.id}`)
  }

  return (
    <div>
      <h2>Candidates</h2>
      <Modal
        isOpen={isModalOpen}
        title={editingId ? 'Edit Candidate' : 'Add Candidate'}
        onClose={handleCancelEdit}
      >
        <form onSubmit={handleSubmit}>
          <fieldset className="form-grid" disabled={submitting}>
          <label className="form-full-width">
            <span>Profile Picture</span>
            <div className="file-upload-area">
              {imagePreview && (
                <img src={imagePreview} alt="Preview" className="image-preview" />
              )}
              <input
                ref={profileImageRef}
                type="file"
                accept="image/*"
                onChange={handleImageChange}
              />
              <span className="file-hint">Max 2MB, JPG/PNG</span>
            </div>
          </label>
          <label>
            <span>Full name</span>
            <input
              name="name"
              placeholder="Full name"
              value={form.name}
              onChange={handleFormChange}
              required
            />
          </label>
          <label>
            <span>Email</span>
            <input
              name="email"
              type="email"
              placeholder="Email"
              value={form.email}
              onChange={handleFormChange}
              required
            />
          </label>
          <label>
            <span>Password</span>
            <input
              name="password"
              type="password"
              placeholder={editingId ? 'New password (optional)' : 'Password'}
              value={form.password}
              onChange={handleFormChange}
              required={!editingId}
            />
          </label>
          <label>
            <span>Status</span>
            <select name="status" value={form.status} onChange={handleFormChange}>
              <option value="active">Active</option>
              <option value="suspended">Suspended</option>
            </select>
          </label>
          <label>
            <span>Major / Field</span>
            <SearchableMultiSelect
              value={form.major_ids}
              onChange={(value) => setForm((prev) => ({ ...prev, major_ids: value }))}
              options={lookups.majors.map((item) => ({
                value: String(item.id),
                label: item.translations?.en || '',
              }))}
              placeholder="Select majors (multiple)"
            />
          </label>
          <label>
            <span>Years of experience</span>
            <SearchableSelect
              value={form.years_of_experience_id}
              onChange={(value) =>
                setForm((prev) => ({ ...prev, years_of_experience_id: value }))
              }
              options={lookups.experiences.map((item) => ({
                value: String(item.id),
                label: item.translations?.en || `Year ${item.sort_order ?? 0}`,
              }))}
              placeholder="Years of experience"
            />
          </label>
          <label>
            <span>Education level</span>
            <SearchableSelect
              value={form.education_id}
              onChange={(value) => setForm((prev) => ({ ...prev, education_id: value }))}
              options={lookups.education.map((item) => ({
                value: String(item.id),
                label: item.translations?.en || '',
              }))}
              placeholder="Education level"
            />
          </label>
          <label>
            <span>Mobile number</span>
            <input
              name="mobile_number"
              placeholder="Mobile number (+123456789)"
              value={form.mobile_number}
              onChange={handleFormChange}
            />
          </label>
          <label>
            <span>Nationality</span>
            <SearchableSelect
              value={form.nationality_country_id}
              onChange={(value) =>
                setForm((prev) => ({ ...prev, nationality_country_id: value }))
              }
              options={countries.map((country) => ({
                value: String(country.id),
                label: country.translations?.en || country.code || `Country ${country.id}`,
                flag: country.flag_path,
              }))}
              placeholder="Nationality"
              renderOption={(option) => (
                <span className="search-option-content">
                  {option.flag ? (
                    <img className="flag-thumb" src={option.flag} alt="" />
                  ) : null}
                  {option.label}
                </span>
              )}
            />
          </label>
          <label>
            <span>Resident Country</span>
            <SearchableSelect
              value={form.resident_country_id}
              onChange={(value) =>
                setForm((prev) => ({ ...prev, resident_country_id: value }))
              }
              options={countries.map((country) => ({
                value: String(country.id),
                label: country.translations?.en || country.code || `Country ${country.id}`,
                flag: country.flag_path,
              }))}
              placeholder="Resident Country"
              renderOption={(option) => (
                <span className="search-option-content">
                  {option.flag ? (
                    <img className="flag-thumb" src={option.flag} alt="" />
                  ) : null}
                  {option.label}
                </span>
              )}
            />
          </label>
          <label>
            <span>Availability</span>
            <select name="availability" value={form.availability} onChange={handleFormChange}>
              <option value="">Select availability</option>
              <option value="immediate">Immediate</option>
              <option value="1_week">1 Week</option>
              <option value="2_weeks">2 Weeks</option>
              <option value="1_month">1 Month</option>
              <option value="negotiable">Negotiable</option>
            </select>
          </label>
          <label>
            <span>Public Slug</span>
            <input
              name="public_slug"
              placeholder="e.g. john-doe"
              value={form.public_slug}
              onChange={handleFormChange}
            />
          </label>
          <label className="form-full-width">
            <span>Upwork Profile URL</span>
            <input
              name="upwork_profile_url"
              type="url"
              placeholder="https://www.upwork.com/freelancers/~username"
              value={form.upwork_profile_url}
              onChange={handleFormChange}
            />
          </label>
          <label className="form-full-width">
            <span>Summary / Bio</span>
            <textarea
              name="summary"
              placeholder="Brief professional summary..."
              value={form.summary}
              onChange={handleFormChange}
              rows={3}
            />
          </label>
          <label className="form-full-width">
            <span>Skills</span>
            <TagInput
              value={form.skills}
              onChange={(skills) => setForm((prev) => ({ ...prev, skills }))}
              placeholder="Type a skill and press Enter"
            />
          </label>
          <label className="form-full-width">
            <span>Resume / CV</span>
            <div className="file-upload-area">
              {form.existing_cv && !form.cv_file && (
                <a
                  href={normalizeStorageUrl(form.existing_cv)}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="existing-file-link"
                >
                  View current CV
                </a>
              )}
              {form.cv_file && (
                <span className="selected-file">{form.cv_file.name}</span>
              )}
              <input
                ref={cvFileRef}
                type="file"
                accept=".pdf,.doc,.docx"
                onChange={handleCvChange}
              />
              <span className="file-hint">Max 5MB, PDF/DOC/DOCX</span>
            </div>
          </label>
          {modalError && (
            <div className="error error-dismissible form-full-width" style={{ marginTop: '1rem' }}>
              <span>{modalError}</span>
              <button
                type="button"
                className="error-close"
                onClick={() => setModalError('')}
                aria-label="Dismiss error"
              >
                ×
              </button>
            </div>
          )}
          <button className="primary-button form-full-width" type="submit" disabled={submitting}>
            {submitting ? 'Saving...' : editingId ? 'Update' : 'Create'}
          </button>
          </fieldset>
        </form>
      </Modal>
      <div className="toolbar">
        <button
          className="primary-button"
          onClick={() => {
            setEditingId(null)
            setForm(emptyForm)
            setIsModalOpen(true)
          }}
        >
          Add Candidate
        </button>
        <input
          placeholder="Search by name, email, code"
          value={query}
          onChange={(event) => setQuery(event.target.value)}
        />
        <select value={status} onChange={(event) => setStatus(event.target.value)}>
          <option value="">All statuses</option>
          <option value="active">Active</option>
          <option value="suspended">Suspended</option>
        </select>
        <button className="primary-button" onClick={load}>
          Filter
        </button>
      </div>
      {listError && (
        <div className="error error-dismissible">
          <span>{listError}</span>
          <button
            type="button"
            className="error-close"
            onClick={() => setListError('')}
            aria-label="Dismiss error"
          >
            ×
          </button>
        </div>
      )}
      {loading ? (
        <p>Loading...</p>
      ) : (
        <div className="table-wrapper">
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Code</th>
                <th>Major</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {candidates.map((candidate) => (
                <tr key={candidate.id}>
                  <td>{candidate.name}</td>
                  <td>{candidate.email}</td>
                  <td>{candidate.unique_code || '-'}</td>
                  <td>
                    {candidate.candidate_profile?.major_ids?.length 
                      ? `${candidate.candidate_profile.major_ids.length} major(s)` 
                      : '-'}
                  </td>
                  <td>
                    <span className={`status-pill ${candidate.status}`}>
                      {candidate.status}
                    </span>
                  </td>
                  <td className="actions">
                    <button
                      className="ghost-button"
                      onClick={() => handleViewProfile(candidate)}
                      title="View"
                      aria-label="View"
                    >
                      <span className="action-icon" aria-hidden="true">
                        <IconEye />
                      </span>
                    </button>
                    <button
                      className="ghost-button"
                      onClick={() => handleEdit(candidate)}
                      title="Edit"
                      aria-label="Edit"
                    >
                      <span className="action-icon" aria-hidden="true">
                        <IconEdit />
                      </span>
                    </button>
                    {candidate.status === 'active' ? (
                      <button
                        className="ghost-button"
                        onClick={() => handleStatus(candidate, 'suspended')}
                        title="Suspend"
                        aria-label="Suspend"
                      >
                        <span className="action-icon" aria-hidden="true">
                          <IconToggle />
                        </span>
                      </button>
                    ) : (
                      <button
                        className="ghost-button"
                        onClick={() => handleStatus(candidate, 'active')}
                        title="Activate"
                        aria-label="Activate"
                      >
                        <span className="action-icon" aria-hidden="true">
                          <IconToggle />
                        </span>
                      </button>
                    )}
                    <button
                      className="danger-button"
                      onClick={() => handleDelete(candidate)}
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
              {!candidates.length && (
                <tr>
                  <td colSpan="6">No candidates found.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

export default Candidates
