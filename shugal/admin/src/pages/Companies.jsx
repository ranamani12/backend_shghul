import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import Modal from '../components/Modal'
import { IconEdit, IconEye, IconToggle, IconTrash } from '../components/Icons'
import { del, get, normalizeStorageUrl, patch, post, put, upload } from '../api/client'

const emptyForm = {
  email: '',
  password: '',
  status: 'active',
  company_name: '',
  country_id: '',
  mobile_number: '',
  civil_id: '',
  majors: [],
  website: '',
  description: '',
  logo_path: '',
  license_path: '',
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
    if (value.includes(optionValue)) {
      onChange(value.filter((item) => item !== optionValue))
    } else {
      onChange([...value, optionValue])
    }
  }

  const displayValue = value.length ? `${value.length} selected` : ''

  return (
    <div className="search-select">
      <input
        className="search-input"
        value={open ? query : displayValue}
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
              const checked = value.includes(option.value)
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

const Companies = () => {
  const [companies, setCompanies] = useState([])
  const [query, setQuery] = useState('')
  const [status, setStatus] = useState('')
  const [form, setForm] = useState(emptyForm)
  const [editingId, setEditingId] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [listError, setListError] = useState('')
  const [modalError, setModalError] = useState('')
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [countries, setCountries] = useState([])
  const [majors, setMajors] = useState([])
  const navigate = useNavigate()

  const load = async () => {
    setLoading(true)
    setListError('')
    try {
      const params = new URLSearchParams()
      if (query) params.set('q', query)
      if (status) params.set('status', status)
      const data = await get(`/admin/companies?${params.toString()}`)
      setCompanies(data.data || [])
    } catch (err) {
      setListError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
    loadCountries()
    loadMajors()
  }, [])

  const loadCountries = async () => {
    try {
      const data = await get('/admin/countries')
      setCountries(data)
    } catch (err) {
      // Optional
    }
  }

  const loadMajors = async () => {
    try {
      const data = await get('/admin/lookups?type=major')
      setMajors(data)
    } catch (err) {
      // Optional
    }
  }

  const handleStatus = async (company, nextStatus) => {
    try {
      await patch(`/admin/companies/${company.id}/status`, {
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

  const handleMajorsChange = (event) => {
    const selected = Array.from(event.target.selectedOptions).map((option) => option.value)
    setForm((prev) => ({ ...prev, majors: selected }))
  }

  const handleEdit = (company) => {
    setEditingId(company.id)
    setModalError('')
    setForm({
      email: company.email || '',
      password: '',
      status: company.status || 'active',
      company_name: company.company_profile?.company_name || '',
      country_id: company.company_profile?.country_id || '',
      mobile_number: company.company_profile?.mobile_number || '',
      civil_id: company.company_profile?.civil_id || '',
      majors: company.company_profile?.majors || [],
      website: company.company_profile?.website || '',
      description: company.company_profile?.description || '',
      logo_path: company.company_profile?.logo_path || '',
      license_path: company.company_profile?.license_path || '',
    })
    setIsModalOpen(true)
  }

  const handleCancelEdit = () => {
    setEditingId(null)
    setForm(emptyForm)
    setIsModalOpen(false)
    setModalError('')
  }

  const handleSubmit = async (event) => {
    event.preventDefault()
    setModalError('')
    setSubmitting(true)
    const payload = {
      email: form.email,
      status: form.status,
      company_name: form.company_name,
      profile: {
        country_id: form.country_id || null,
        mobile_number: form.mobile_number || null,
        civil_id: form.civil_id || null,
        majors: form.majors || [],
        website: form.website || null,
        description: form.description || null,
        logo_path: form.logo_path || null,
        license_path: form.license_path || null,
      },
    }

    if (form.password) {
      payload.password = form.password
    }

    try {
      if (editingId) {
        await put(`/admin/companies/${editingId}`, payload)
      } else {
        await post('/admin/companies', payload)
      }
      handleCancelEdit()
      load()
    } catch (err) {
      setModalError(err.message)
    } finally {
      setSubmitting(false)
    }
  }

  const handleDelete = async (company) => {
    if (!window.confirm('Delete this company?')) return
    try {
      await del(`/admin/companies/${company.id}`)
      load()
    } catch (err) {
      setListError(err.message)
    }
  }

  const handleViewProfile = (company) => {
    navigate(`/companies/${company.id}`)
  }

  return (
    <div>
      <h2>Companies</h2>
      <Modal
        isOpen={isModalOpen}
        title={editingId ? 'Edit Company' : 'Add Company'}
        onClose={handleCancelEdit}
      >
        {modalError && (
          <div className="error error-dismissible">
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
        <form onSubmit={handleSubmit}>
          <fieldset className="form-grid" disabled={submitting}>
          <label>
            <span>Company name</span>
            <input
              name="company_name"
              placeholder="Company name"
              value={form.company_name}
              onChange={handleFormChange}
              required
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
            <span>Country</span>
            <SearchableSelect
              value={form.country_id}
              onChange={(value) => setForm((prev) => ({ ...prev, country_id: value }))}
              options={countries.map((country) => ({
                value: String(country.id),
                label: country.translations?.en || country.code || `Country ${country.id}`,
                flag: country.flag_path,
              }))}
              placeholder="Select country"
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
            <span>Mobile number</span>
            <input
              name="mobile_number"
              placeholder="Mobile number (+123456789)"
              value={form.mobile_number}
              onChange={handleFormChange}
            />
          </label>
          <label>
            <span>Civil ID</span>
            <input
              name="civil_id"
              placeholder="Civil ID"
              value={form.civil_id}
              onChange={handleFormChange}
            />
          </label>
          <label>
            <span>Majors</span>
            <SearchableMultiSelect
              value={form.majors}
              onChange={(value) => setForm((prev) => ({ ...prev, majors: value }))}
              options={majors.map((item) => ({
                value: item.translations?.en || '',
                label: item.translations?.en || '',
              }))}
              placeholder="Select majors"
            />
          </label>
          <label>
            <span>Website</span>
            <input
              name="website"
              placeholder="Website"
              value={form.website}
              onChange={handleFormChange}
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
          <label className="full-row">
            <span>Description</span>
            <textarea
              name="description"
              placeholder="Description"
              value={form.description}
              onChange={handleFormChange}
              rows="3"
            />
          </label>
          <label>
            <span>Company logo</span>
            <div className="file-upload">
              <label className="file-button" htmlFor="companyLogoUpload">
                Upload logo
              </label>
              <input
                id="companyLogoUpload"
                className="file-input"
                type="file"
                accept="image/png,image/jpeg,image/svg+xml"
                onChange={async (event) => {
                  const file = event.target.files?.[0]
                  if (!file) return
                  try {
                    const formData = new FormData()
                    formData.append('logo', file)
                    const response = await upload('/admin/companies/upload/logo', formData)
                    setForm((prev) => ({ ...prev, logo_path: response.url }))
                  } catch (err) {
                    setModalError(err.message)
                  }
                }}
              />
              <span className="file-name">
                {form.logo_path ? 'Logo selected' : 'No file selected'}
              </span>
            </div>
            {form.logo_path && (
              <div className="flag-preview">
                <img src={normalizeStorageUrl(form.logo_path)} alt="Logo" />
                <span className="muted">Logo preview</span>
              </div>
            )}
          </label>
           
          <label>
            <span>License document</span>
            <div className="file-upload">
              <label className="file-button" htmlFor="companyLicenseUpload">
                Upload license
              </label>
              <input
                id="companyLicenseUpload"
                className="file-input"
                type="file"
                accept="application/pdf,image/png,image/jpeg,image/webp"
                onChange={async (event) => {
                  const file = event.target.files?.[0]
                  if (!file) return
                  try {
                    const formData = new FormData()
                    formData.append('license', file)
                    const response = await upload('/admin/companies/upload/license', formData)
                    setForm((prev) => ({ ...prev, license_path: response.url }))
                  } catch (err) {
                    setModalError(err.message)
                  }
                }}
              />
              <span className="file-name">
                {form.license_path ? 'License selected' : 'No file selected'}
              </span>
            </div>
            {form.license_path && (
              <div className="license-preview">
                <a href={normalizeStorageUrl(form.license_path)} target="_blank" rel="noreferrer">
                  View uploaded license
                </a>
              </div>
            )}
          </label>
         
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
      <div className="toolbar">
        <button
          className="primary-button"
          onClick={() => {
            setEditingId(null)
            setForm(emptyForm)
            setIsModalOpen(true)
          }}
        >
          Add Company
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
                <th>Company</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {companies.map((company) => (
                <tr key={company.id}>
                  <td>{company.name}</td>
                  <td>{company.email}</td>
                  <td>{company.unique_code || '-'}</td>
                  <td>{company.company_profile?.company_name || '-'}</td>
                  <td>
                    <span className={`status-pill ${company.status}`}>
                      {company.status}
                    </span>
                  </td>
                  <td className="actions">
                    <button
                      className="ghost-button"
                      onClick={() => handleViewProfile(company)}
                      title="View"
                      aria-label="View"
                    >
                      <span className="action-icon" aria-hidden="true">
                        <IconEye />
                      </span>
                    </button>
                    <button
                      className="ghost-button"
                      onClick={() => handleEdit(company)}
                      title="Edit"
                      aria-label="Edit"
                    >
                      <span className="action-icon" aria-hidden="true">
                        <IconEdit />
                      </span>
                    </button>
                    {company.status === 'active' ? (
                      <button
                        className="ghost-button"
                        onClick={() => handleStatus(company, 'suspended')}
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
                        onClick={() => handleStatus(company, 'active')}
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
                      onClick={() => handleDelete(company)}
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
              {!companies.length && (
                <tr>
                  <td colSpan="6">No companies found.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

export default Companies
