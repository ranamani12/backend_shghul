import { useEffect, useState } from 'react'
import Modal from '../components/Modal'
import { IconEdit, IconToggle, IconTrash } from '../components/Icons'
import { del, get, post, put } from '../api/client'

const TYPES = [
  { value: 'major', label: 'Major / Field' },
  { value: 'experience_year', label: 'Year of Experience' },
  { value: 'education_level', label: 'Education Level' },
]

const Lookups = () => {
  const [currentType, setCurrentType] = useState(TYPES[0].value)
  const [items, setItems] = useState([])
  const [listError, setListError] = useState('')
  const [modalError, setModalError] = useState('')
  const [editingId, setEditingId] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState(null)
  const [form, setForm] = useState({
    translations: { en: '', ar: '' },
    sort_order: 0,
    is_active: true,
  })

  const load = async (type = currentType) => {
    setListError('')
    try {
      const data = await get(`/admin/lookups?type=${type}`)
      setItems(data)
    } catch (err) {
      setListError(err.message)
    }
  }

  useEffect(() => {
    load(currentType)
  }, [currentType])

  const handleOpenCreate = () => {
    setEditingId(null)
    setModalError('')
    const nextOrder = items.length + 1
    setForm({
      translations: { en: '', ar: '' },
      sort_order: nextOrder,
      is_active: true,
    })
    setIsModalOpen(true)
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
    setForm((prev) => ({ ...prev, [name]: value }))
  }

  const handleSubmit = async (event) => {
    event.preventDefault()
    setModalError('')
    try {
      const payload = {
        type: currentType,
        translations: {
          en: form.translations.en,
          ar: form.translations.ar,
        },
        sort_order: Number(form.sort_order || 0),
        is_active: form.is_active === true || form.is_active === 'true',
      }
      if (editingId) {
        await put(`/admin/lookups/${editingId}`, payload)
      } else {
        await post('/admin/lookups', payload)
      }
      setIsModalOpen(false)
      setEditingId(null)
      load(currentType)
    } catch (err) {
      setModalError(err.message)
    }
  }

  const handleEdit = (item) => {
    setEditingId(item.id)
    setModalError('')
    setForm({
      translations: {
        en: item.translations?.en || '',
        ar: item.translations?.ar || '',
      },
      sort_order: item.sort_order ?? 0,
      is_active: item.is_active ? 'true' : 'false',
    })
    setIsModalOpen(true)
  }

  const handleToggle = async (item) => {
    try {
      await put(`/admin/lookups/${item.id}`, {
        is_active: !item.is_active,
      })
      load(currentType)
    } catch (err) {
      setListError(err.message)
    }
  }

  const handleDelete = async (item) => {
    setDeleteTarget(item)
  }

  const confirmDelete = async () => {
    if (!deleteTarget) return
    try {
      await del(`/admin/lookups/${deleteTarget.id}`)
      load(currentType)
    } catch (err) {
      setListError(err.message)
    } finally {
      setDeleteTarget(null)
    }
  }

  return (
    <div>
      <h2>Lookup Manager</h2>
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
      <div className="tab-bar">
        {TYPES.map((type) => (
          <button
            key={type.value}
            className={`tab ${currentType === type.value ? 'active' : ''}`}
            onClick={() => setCurrentType(type.value)}
          >
            {type.label}
          </button>
        ))}
      </div>
      <Modal
        isOpen={isModalOpen}
        title={editingId ? 'Update Lookup' : 'Add Lookup'}
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
          <button className="primary-button" type="submit">
            {editingId ? 'Update' : 'Add'}
          </button>
        </form>
      </Modal>
      <div className="toolbar">
        <button className="primary-button" onClick={handleOpenCreate}>
          Add Item
        </button>
      </div>
      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
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
                <td colSpan="5">No records found.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
      <Modal
        isOpen={Boolean(deleteTarget)}
        title="Delete Lookup"
        onClose={() => setDeleteTarget(null)}
      >
        <div className="modal-content">
          <p>
            Are you sure you want to delete{' '}
            <strong>{deleteTarget?.translations?.en || 'this item'}</strong>?
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

export default Lookups
