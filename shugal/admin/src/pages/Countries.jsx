import { useEffect, useState } from 'react'
import Modal from '../components/Modal'
import { IconEdit, IconToggle, IconTrash } from '../components/Icons'
import { del, get, post, put } from '../api/client'

const Countries = () => {
  const [items, setItems] = useState([])
  const [listError, setListError] = useState('')
  const [modalError, setModalError] = useState('')
  const [editingId, setEditingId] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState(null)
  const [deleteError, setDeleteError] = useState('')
  const [form, setForm] = useState({
    code: '',
    translations: { en: '', ar: '' },
    sort_order: 0,
    is_active: true,
    flag_path: '',
  })

  const load = async () => {
    setListError('')
    try {
      const data = await get('/admin/countries')
      setItems(data)
    } catch (err) {
      setListError(err.message)
    }
  }

  useEffect(() => {
    load()
  }, [])

  const handleOpenCreate = () => {
    setEditingId(null)
    setModalError('')
    const nextOrder = items.length + 1
    setForm({
      code: '',
      translations: { en: '', ar: '' },
      sort_order: nextOrder,
      is_active: true,
      flag_path: '',
    })
    setIsModalOpen(true)
  }

  const buildFlagUrl = (code) => {
    if (!code) return ''
    return `https://flagcdn.com/w40/${code.toLowerCase()}.png`
  }

  const handleChange = (event) => {
    const { name, value } = event.target
    if (name === 'en' || name === 'ar') {
      setForm((prev) => ({
        ...prev,
        translations: { ...prev.translations, [name]: value },
      }))
      return
    }
    if (name === 'code') {
      const nextCode = value.toUpperCase()
      setForm((prev) => ({
        ...prev,
        code: nextCode,
        flag_path: buildFlagUrl(nextCode),
      }))
      return
    }
    setForm((prev) => ({ ...prev, [name]: value }))
  }


  const handleSubmit = async (event) => {
    event.preventDefault()
    setModalError('')
    try {
      const payload = {
        code: form.code || null,
        translations: {
          en: form.translations.en,
          ar: form.translations.ar,
        },
        sort_order: Number(form.sort_order || 0),
        is_active: form.is_active === true || form.is_active === 'true',
        flag_path: form.flag_path || null,
      }
      if (editingId) {
        await put(`/admin/countries/${editingId}`, payload)
      } else {
        await post('/admin/countries', payload)
      }
      setIsModalOpen(false)
      setEditingId(null)
      load()
    } catch (err) {
      setModalError(err.message)
    }
  }

  const handleEdit = (item) => {
    setEditingId(item.id)
    setModalError('')
    setForm({
      code: item.code || '',
      translations: {
        en: item.translations?.en || '',
        ar: item.translations?.ar || '',
      },
      sort_order: item.sort_order ?? 0,
      is_active: item.is_active ? 'true' : 'false',
      flag_path: item.flag_path || '',
    })
    setIsModalOpen(true)
  }

  const handleToggle = async (item) => {
    try {
      await put(`/admin/countries/${item.id}`, {
        is_active: !item.is_active,
      })
      load()
    } catch (err) {
      setListError(err.message)
    }
  }

  const handleDelete = async (item) => {
    setDeleteError('')
    setDeleteTarget(item)
  }

  const confirmDelete = async () => {
    if (!deleteTarget) return
    try {
      await del(`/admin/countries/${deleteTarget.id}`)
      load()
      setDeleteTarget(null)
      setDeleteError('')
    } catch (err) {
      setDeleteError(err.message)
    }
  }

  return (
    <div>
      <h2>Countries</h2>
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
      <Modal
        isOpen={isModalOpen}
        title={editingId ? 'Update Country' : 'Add Country'}
        onClose={() => setIsModalOpen(false)}
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
        <form className="form-grid" onSubmit={handleSubmit}>
          <label>
            <span>Country code</span>
            <input
              name="code"
              placeholder="Country code (e.g. KW)"
              value={form.code}
              onChange={handleChange}
            />
          </label>
          <label>
            <span>English name</span>
            <input
              name="en"
              placeholder="English name"
              value={form.translations.en}
              onChange={handleChange}
              required
            />
          </label>
          <label>
            <span>Arabic name</span>
            <input
              name="ar"
              placeholder="Arabic name"
              value={form.translations.ar}
              onChange={handleChange}
              required
            />
          </label>
          <label>
            <span>Order</span>
            <input
              name="sort_order"
              type="number"
              placeholder="Order"
              value={form.sort_order}
              onChange={handleChange}
            />
          </label>
          <label>
            <span>Status</span>
            <select name="is_active" value={form.is_active} onChange={handleChange}>
              <option value="true">Active</option>
              <option value="false">Inactive</option>
            </select>
          </label>
          
          {form.flag_path && (
            <div className="flag-preview">
              <img src={form.flag_path} alt="Flag" />
              <span className="muted">Flag preview</span>
            </div>
          )}
          <button className="primary-button" type="submit">
            {editingId ? 'Update' : 'Add'}
          </button>
        </form>
      </Modal>
      <div className="toolbar">
        <button className="primary-button" onClick={handleOpenCreate}>
          Add Country
        </button>
      </div>
      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th>Flag</th>
              <th>Code</th>
              <th>English</th>
              <th>Arabic</th>
              <th>Order</th>
              <th>Active</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {items.map((item) => (
              <tr key={item.id}>
                <td>
                  {item.flag_path ? (
                    <img className="flag-thumb" src={item.flag_path} alt="Flag" />
                  ) : (
                    '-'
                  )}
                </td>
                <td>{item.code || '-'}</td>
                <td>{item.translations?.en || '-'}</td>
                <td>{item.translations?.ar || '-'}</td>
                <td>{item.sort_order}</td>
                <td>{item.is_active ? 'Yes' : 'No'}</td>
                <td className="actions">
                  <button
                    className="ghost-button"
                    onClick={() => handleEdit(item)}
                    title="Edit"
                    aria-label="Edit"
                  >
                    <span className="action-icon" aria-hidden="true">
                      <IconEdit />
                    </span>
                  </button>
                  <button
                    className="ghost-button"
                    onClick={() => handleToggle(item)}
                    title={item.is_active ? 'Deactivate' : 'Activate'}
                    aria-label={item.is_active ? 'Deactivate' : 'Activate'}
                  >
                    <span className="action-icon" aria-hidden="true">
                      <IconToggle />
                    </span>
                  </button>
                  <button
                    className="danger-button"
                    onClick={() => handleDelete(item)}
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
            {!items.length && (
              <tr>
                <td colSpan="7">No countries found.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
      <Modal
        isOpen={Boolean(deleteTarget)}
        title="Delete Country"
        onClose={() => setDeleteTarget(null)}
      >
        <div className="modal-content">
          {deleteError && (
            <div className="error error-dismissible">
              <span>{deleteError}</span>
              <button
                type="button"
                className="error-close"
                onClick={() => setDeleteError('')}
                aria-label="Dismiss error"
              >
                ×
              </button>
            </div>
          )}
          <p>
            Are you sure you want to delete{' '}
            <strong>{deleteTarget?.translations?.en || 'this country'}</strong>?
          </p>
          <div className="modal-actions">
            <button className="ghost-button" onClick={() => setDeleteTarget(null)}>
              Cancel
            </button>
            <button className="danger-button" onClick={confirmDelete}>
              Delete
            </button>
          </div>
        </div>
      </Modal>
    </div>
  )
}

export default Countries
