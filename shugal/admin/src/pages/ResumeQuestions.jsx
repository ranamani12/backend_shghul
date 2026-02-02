import { useEffect, useState } from 'react'
import Modal from '../components/Modal'
import { IconEdit, IconToggle, IconTrash } from '../components/Icons'
import { del, get, post, put } from '../api/client'

const ResumeQuestions = () => {
  const [questions, setQuestions] = useState([])
  const [form, setForm] = useState({
    question: '',
    type: 'text',
    sort_order: 0,
    is_active: true,
  })
  const [editingId, setEditingId] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [error, setError] = useState('')

  const load = async () => {
    setError('')
    try {
      const data = await get('/admin/resume-questions')
      setQuestions(data)
    } catch (err) {
      setError(err.message)
    }
  }

  useEffect(() => {
    load()
  }, [])

  const handleChange = (event) => {
    setForm((prev) => ({ ...prev, [event.target.name]: event.target.value }))
  }

  const handleSubmit = async (event) => {
    event.preventDefault()
    setError('')
    try {
      const payload = {
        ...form,
        sort_order: Number(form.sort_order || 0),
        is_active: form.is_active === true || form.is_active === 'true',
      }
      if (editingId) {
        await put(`/admin/resume-questions/${editingId}`, payload)
      } else {
        await post('/admin/resume-questions', payload)
      }
      setForm({ question: '', type: 'text', sort_order: 0, is_active: true })
      setEditingId(null)
      setIsModalOpen(false)
      load()
    } catch (err) {
      setError(err.message)
    }
  }

  const handleEdit = (question) => {
    setEditingId(question.id)
    setForm({
      question: question.question || '',
      type: question.type || 'text',
      sort_order: question.sort_order || 0,
      is_active: question.is_active ? 'true' : 'false',
    })
    setIsModalOpen(true)
  }

  const handleCancelEdit = () => {
    setEditingId(null)
    setForm({ question: '', type: 'text', sort_order: 0, is_active: true })
    setIsModalOpen(false)
  }

  const handleToggle = async (question) => {
    try {
      await put(`/admin/resume-questions/${question.id}`, {
        is_active: !question.is_active,
      })
      load()
    } catch (err) {
      setError(err.message)
    }
  }

  const handleDelete = async (question) => {
    if (!window.confirm('Delete this question?')) return
    try {
      await del(`/admin/resume-questions/${question.id}`)
      load()
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <div>
      <h2>Resume Questions</h2>
      {error && <div className="error">{error}</div>}
      <Modal
        isOpen={isModalOpen}
        title={editingId ? 'Edit Question' : 'Add Question'}
        onClose={handleCancelEdit}
      >
        <form className="form-grid" onSubmit={handleSubmit}>
          <input
            name="question"
            placeholder="Question text"
            value={form.question}
            onChange={handleChange}
            required
          />
          <select name="type" value={form.type} onChange={handleChange}>
            <option value="text">Text</option>
            <option value="select">Select</option>
            <option value="multiselect">Multi-select</option>
          </select>
          <input
            name="sort_order"
            type="number"
            placeholder="Order"
            value={form.sort_order}
            onChange={handleChange}
          />
          <select name="is_active" value={form.is_active} onChange={handleChange}>
            <option value="true">Active</option>
            <option value="false">Inactive</option>
          </select>
          <button className="primary-button" type="submit">
            {editingId ? 'Update' : 'Add'}
          </button>
        </form>
      </Modal>
      <div className="toolbar">
        <button
          className="primary-button"
          onClick={() => {
            setEditingId(null)
            setForm({ question: '', type: 'text', sort_order: 0, is_active: true })
            setIsModalOpen(true)
          }}
        >
          Add Question
        </button>
      </div>
      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th>Question</th>
              <th>Type</th>
              <th>Order</th>
              <th>Active</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {questions.map((question) => (
              <tr key={question.id}>
                <td>{question.question}</td>
                <td>{question.type}</td>
                <td>{question.sort_order}</td>
                <td>{question.is_active ? 'Yes' : 'No'}</td>
                <td className="actions">
                  <button
                    className="ghost-button"
                    onClick={() => handleEdit(question)}
                    title="Edit"
                    aria-label="Edit"
                  >
                    <span className="action-icon" aria-hidden="true">
                      <IconEdit />
                    </span>
                  </button>
                  <button
                    className="ghost-button"
                    onClick={() => handleToggle(question)}
                    title={question.is_active ? 'Deactivate' : 'Activate'}
                    aria-label={question.is_active ? 'Deactivate' : 'Activate'}
                  >
                    <span className="action-icon" aria-hidden="true">
                      <IconToggle />
                    </span>
                  </button>
                  <button
                    className="danger-button"
                    onClick={() => handleDelete(question)}
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
            {!questions.length && (
              <tr>
                <td colSpan="5">No questions found.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}

export default ResumeQuestions
