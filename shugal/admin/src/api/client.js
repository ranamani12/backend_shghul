const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api'
const STORAGE_BASE = API_URL.replace('/api', '')
const TOKEN_KEY = 'shugul_admin_token'

/**
 * Normalizes a storage URL to use the configured API server.
 * Converts URLs with different hosts to use STORAGE_BASE.
 */
export const normalizeStorageUrl = (url) => {
  if (!url) return null

  // If URL is relative (starts with /storage), make it absolute
  if (url.startsWith('/storage')) {
    return `${STORAGE_BASE}${url}`
  }

  // If it's already a full URL, replace host with our configured server
  try {
    const parsed = new URL(url)
    const storageUrl = new URL(STORAGE_BASE)
    // Keep the path but use our configured host
    return `${storageUrl.origin}${parsed.pathname}`
  } catch {
    return url
  }
}

export const getToken = () => localStorage.getItem(TOKEN_KEY)

export const setToken = (token) => {
  if (token) {
    localStorage.setItem(TOKEN_KEY, token)
  } else {
    localStorage.removeItem(TOKEN_KEY)
  }
}

const buildHeaders = (headers = {}, includeContentType = true) => {
  const token = getToken()
  return {
    ...(includeContentType ? { 'Content-Type': 'application/json' } : {}),
    Accept: 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...headers,
  }
}

export const apiFetch = async (path, options = {}) => {
  const isFormData =
    options.body && typeof FormData !== 'undefined' && options.body instanceof FormData
  const response = await fetch(`${API_URL}${path}`, {
    ...options,
    headers: buildHeaders(options.headers, !isFormData),
  })

  const contentType = response.headers.get('content-type') || ''
  const payload = contentType.includes('application/json')
    ? await response.json()
    : await response.text()

  if (!response.ok) {
    // Handle Laravel validation errors (422)
    if (payload?.errors) {
      const errorMessages = Object.values(payload.errors).flat().join(', ')
      throw new Error(errorMessages || payload?.message || 'Validation failed')
    }
    const message =
      payload?.message ||
      (typeof payload === 'string' ? payload : 'Request failed')
    throw new Error(message)
  }

  return payload
}

export const get = (path) => apiFetch(path)
export const post = (path, body) =>
  apiFetch(path, { method: 'POST', body: JSON.stringify(body) })
export const put = (path, body) =>
  apiFetch(path, { method: 'PUT', body: JSON.stringify(body) })
export const patch = (path, body) =>
  apiFetch(path, { method: 'PATCH', body: JSON.stringify(body) })
export const del = (path) => apiFetch(path, { method: 'DELETE' })

export const upload = (path, formData, method = 'POST') =>
  apiFetch(path, { method, body: formData })

export default API_URL
