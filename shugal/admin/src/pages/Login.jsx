import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { get, post, setToken } from '../api/client'

const Login = () => {
  const navigate = useNavigate()
  const [form, setForm] = useState({ email: '', password: '' })
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [logo, setLogo] = useState('/logo-light.png')

  useEffect(() => {
    const loadBranding = async () => {
      try {
        const data = await get('/settings?group=branding')
        // Use dark theme logo (light-colored) for the dark login background
        const logoSetting = data.find((item) => item.key === 'app_logo_dark')
        if (logoSetting?.value) {
          setLogo(logoSetting.value)
        }
      } catch {
        // Use default logo if branding fetch fails
      }
    }
    loadBranding()
  }, [])

  const handleChange = (event) => {
    setForm((prev) => ({ ...prev, [event.target.name]: event.target.value }))
  }

  const handleSubmit = async (event) => {
    event.preventDefault()
    setError('')
    setLoading(true)
    try {
      const response = await post('/auth/admin/login', form)
      setToken(response.token)
      navigate('/', { replace: true })
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="login-page">
      <div className="login-left">
        <img src={logo} alt="Shugal" className="login-logo" />
      </div>
      <div className="login-right">
        <form className="login-form" onSubmit={handleSubmit}>
          <div className="login-form-header">
            <h2>Welcome Back</h2>
            <p className="muted">Sign in to your admin account</p>
          </div>
          <fieldset disabled={loading} className="login-fieldset">
            <label>
              <span>Email Address</span>
              <input
                type="email"
                name="email"
                placeholder="admin@shugal.com"
                value={form.email}
                onChange={handleChange}
                required
              />
            </label>
            <label>
              <span>Password</span>
              <input
                type="password"
                name="password"
                placeholder="Enter your password"
                value={form.password}
                onChange={handleChange}
                required
              />
            </label>
            {error && (
              <div className="error error-dismissible">
                <span>{error}</span>
                <button
                  type="button"
                  className="error-close"
                  onClick={() => setError('')}
                >
                  x
                </button>
              </div>
            )}
            <button className="primary-button login-button" type="submit" disabled={loading}>
              {loading ? (
                <>
                  <span className="spinner"></span>
                  Signing in...
                </>
              ) : (
                'Sign In'
              )}
            </button>
          </fieldset>
          <p className="login-footer muted">
            Shugal Admin Panel v1.0
          </p>
        </form>
      </div>
    </div>
  )
}

export default Login
