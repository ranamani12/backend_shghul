import { useEffect, useState } from 'react'
import { get, put, upload } from '../api/client'

// Mobile app default theme colors
const MOBILE_APP_THEME = {
  light_primary: '#075056',
  light_primary_contrast: '#ffffff',
  light_surface: '#f5f5f5',
  light_panel: '#ffffff',
  light_card: '#ffffff',
  light_text: '#1a1a1a',
  light_muted: '#666666',
  light_border: '#e0e0e0',
  light_accent: '#092a17',
  dark_primary: '#0a9ba5',
  dark_primary_contrast: '#ffffff',
  dark_surface: '#0a0f0f',
  dark_panel: '#0f1a1b',
  dark_card: '#152526',
  dark_text: '#e8f4f5',
  dark_muted: '#8ab4b7',
  dark_border: '#1a3536',
  dark_accent: '#075056',
}

const Settings = () => {
  const [fee, setFee] = useState('')
  const [unlockFee, setUnlockFee] = useState('')
  const [branding, setBranding] = useState({
    app_name: '',
    app_tagline: '',
    app_logo: '',
    app_logo_light: '',
    app_logo_dark: '',
    app_favicon: '',
    support_email: '',
    support_phone: '',
    support_address: '',
    facebook_url: '',
    instagram_url: '',
    linkedin_url: '',
    twitter_url: '',
  })
  const [seo, setSeo] = useState({
    favicon_url: '',
    meta_title: '',
    meta_description: '',
    meta_keywords: '',
  })
  const [theme, setTheme] = useState({ ...MOBILE_APP_THEME })
  const [faviconFile, setFaviconFile] = useState(null)
  const [lightLogoFile, setLightLogoFile] = useState(null)
  const [darkLogoFile, setDarkLogoFile] = useState(null)
  const [activeTab, setActiveTab] = useState('branding')
  const [error, setError] = useState('')
  const [saving, setSaving] = useState(false)

  const load = async () => {
    setError('')
    try {
      const [pricing, brandingSettings, seoSettings, themeSettings] = await Promise.all([
        get('/admin/settings?group=pricing'),
        get('/admin/settings?group=branding'),
        get('/admin/settings?group=seo'),
        get('/admin/settings?group=theme'),
      ])
      const activation = pricing.find((item) => item.key === 'candidate_activation_fee')
      const unlock = pricing.find((item) => item.key === 'candidate_unlock_fee')
      if (activation?.value) setFee(String(activation.value))
      if (unlock?.value) setUnlockFee(String(unlock.value))

      const brandingMap = brandingSettings.reduce((acc, item) => {
        acc[item.key] = item.value || ''
        return acc
      }, {})
      setBranding((prev) => ({ ...prev, ...brandingMap }))

      const seoMap = seoSettings.reduce((acc, item) => {
        acc[item.key] = item.value || ''
        return acc
      }, {})
      setSeo((prev) => ({
        ...prev,
        ...seoMap,
        favicon_url: seoMap.favicon_url || brandingMap.app_favicon || '',
      }))

      const themeMap = themeSettings.reduce((acc, item) => {
        const value = item.value || ''
        acc[item.key] = value.startsWith('rgba') ? '' : value
        return acc
      }, {})
      setTheme((prev) => ({ ...prev, ...themeMap }))
    } catch (err) {
      setError(err.message)
    }
  }

  useEffect(() => {
    load()
  }, [])

  const handleSave = async (event) => {
    event.preventDefault()
    setSaving(true)
    setError('')
    try {
      const brandingSettings = Object.entries(branding).map(([key, value]) => ({
        key,
        group: 'branding',
        value: value || null,
        description: `Branding setting: ${key}`,
      }))
      const seoSettings = Object.entries(seo).map(([key, value]) => ({
        key,
        group: 'seo',
        value: value || null,
        description: `SEO setting: ${key}`,
      }))
      const themeSettings = Object.entries(theme).map(([key, value]) => ({
        key,
        group: 'theme',
        value: value || null,
        description: `Theme setting: ${key}`,
      }))

      await put('/admin/settings', {
        settings: [
          {
            key: 'candidate_activation_fee',
            group: 'pricing',
            value: Number(fee || 0),
            description: 'Activation fee for candidate profiles',
          },
          {
            key: 'candidate_unlock_fee',
            group: 'pricing',
            value: Number(unlockFee || 0),
            description: 'Fee to unlock a candidate profile',
          },
          ...brandingSettings,
          ...seoSettings,
          ...themeSettings,
        ],
      })
      window.dispatchEvent(new Event('theme-settings-updated'))
    } catch (err) {
      setError(err.message)
    } finally {
      setSaving(false)
    }
  }

  const handleBrandingChange = (event) => {
    setBranding((prev) => ({ ...prev, [event.target.name]: event.target.value }))
  }

  const handleSeoChange = (event) => {
    setSeo((prev) => ({ ...prev, [event.target.name]: event.target.value }))
  }

  const handleThemeChange = (event) => {
    setTheme((prev) => ({ ...prev, [event.target.name]: event.target.value }))
  }

  const handleResetToMobileTheme = () => {
    setTheme({ ...MOBILE_APP_THEME })
  }

  const handleUpload = async (key, file) => {
    if (!file) return
    setSaving(true)
    setError('')
    try {
      const formData = new FormData()
      formData.append('key', key)
      formData.append('file', file)
      const response = await upload('/admin/settings/upload', formData)
      setBranding((prev) => ({ ...prev, [key]: response.url }))
      if (key === 'app_favicon') {
        setSeo((prev) => ({ ...prev, favicon_url: response.url }))
      }
    } catch (err) {
      setError(err.message)
    } finally {
      setSaving(false)
    }
  }

  return (
    <div>
      <h2>Settings</h2>
      {error && <div className="error">{error}</div>}
      <form className="card" onSubmit={handleSave}>
        <div className="settings-tabs">
          <button
            type="button"
            className={`tab-button ${activeTab === 'branding' ? 'active' : ''}`}
            onClick={() => setActiveTab('branding')}
          >
            Branding
          </button>
          <button
            type="button"
            className={`tab-button ${activeTab === 'contact' ? 'active' : ''}`}
            onClick={() => setActiveTab('contact')}
          >
            Contact
          </button>
          <button
            type="button"
            className={`tab-button ${activeTab === 'social' ? 'active' : ''}`}
            onClick={() => setActiveTab('social')}
          >
            Social Links
          </button>
          <button
            type="button"
            className={`tab-button ${activeTab === 'pricing' ? 'active' : ''}`}
            onClick={() => setActiveTab('pricing')}
          >
            Pricing
          </button>
          <button
            type="button"
            className={`tab-button ${activeTab === 'seo' ? 'active' : ''}`}
            onClick={() => setActiveTab('seo')}
          >
            SEO
          </button>
          <button
            type="button"
            className={`tab-button ${activeTab === 'theme' ? 'active' : ''}`}
            onClick={() => setActiveTab('theme')}
          >
            Theme
          </button>
        </div>

        {activeTab === 'branding' && (
          <div className="settings-section">
            <div className="settings-card">
              <h4>Favicon</h4>
              <div className="settings-preview">
                {branding.app_favicon ? (
                  <img src={branding.app_favicon} alt="Favicon" />
                ) : (
                  <div className="brand-logo" />
                )}
                <div>
                  <div className="section-title">Browser Icon</div>
                  <div className="muted">Upload favicon (.ico or .png)</div>
                </div>
              </div>
              <div className="file-upload">
                <input
                  id="favicon-upload"
                  className="file-input"
                  type="file"
                  accept=".ico,.png,.jpg,.jpeg,.svg"
                  onChange={(event) => setFaviconFile(event.target.files?.[0] || null)}
                />
                <label className="file-button" htmlFor="favicon-upload">
                  Choose Favicon
                </label>
                <span className="file-name">
                  {faviconFile ? faviconFile.name : 'No file selected'}
                </span>
                <button
                  className="ghost-button"
                  type="button"
                  onClick={() => handleUpload('app_favicon', faviconFile)}
                  disabled={saving || !faviconFile}
                >
                  Upload Favicon
                </button>
              </div>
            </div>
            <div className="settings-card">
              <h4>Light Theme Logo</h4>
              <p className="muted" style={{ marginBottom: '1rem' }}>
                Logo displayed when light theme is active (use dark logo for contrast).
              </p>
              <div className="settings-preview">
                {branding.app_logo_light ? (
                  <div style={{ background: '#ffffff', padding: '12px', borderRadius: '8px' }}>
                    <img src={branding.app_logo_light} alt="Light Logo" style={{ maxHeight: '48px' }} />
                  </div>
                ) : (
                  <div className="brand-logo" />
                )}
              </div>
              <div className="file-upload">
                <input
                  id="light-logo-upload"
                  className="file-input"
                  type="file"
                  accept=".png,.jpg,.jpeg,.svg"
                  onChange={(event) => setLightLogoFile(event.target.files?.[0] || null)}
                />
                <label className="file-button" htmlFor="light-logo-upload">
                  Choose Logo
                </label>
                <span className="file-name">
                  {lightLogoFile ? lightLogoFile.name : 'No file selected'}
                </span>
                <button
                  className="ghost-button"
                  type="button"
                  onClick={() => handleUpload('app_logo_light', lightLogoFile)}
                  disabled={saving || !lightLogoFile}
                >
                  Upload
                </button>
              </div>
            </div>
            <div className="settings-card">
              <h4>Dark Theme Logo</h4>
              <p className="muted" style={{ marginBottom: '1rem' }}>
                Logo displayed when dark theme is active (use light logo for contrast).
              </p>
              <div className="settings-preview">
                {branding.app_logo_dark ? (
                  <div style={{ background: '#0a0f0f', padding: '12px', borderRadius: '8px' }}>
                    <img src={branding.app_logo_dark} alt="Dark Logo" style={{ maxHeight: '48px' }} />
                  </div>
                ) : (
                  <div className="brand-logo" />
                )}
              </div>
              <div className="file-upload">
                <input
                  id="dark-logo-upload"
                  className="file-input"
                  type="file"
                  accept=".png,.jpg,.jpeg,.svg"
                  onChange={(event) => setDarkLogoFile(event.target.files?.[0] || null)}
                />
                <label className="file-button" htmlFor="dark-logo-upload">
                  Choose Logo
                </label>
                <span className="file-name">
                  {darkLogoFile ? darkLogoFile.name : 'No file selected'}
                </span>
                <button
                  className="ghost-button"
                  type="button"
                  onClick={() => handleUpload('app_logo_dark', darkLogoFile)}
                  disabled={saving || !darkLogoFile}
                >
                  Upload
                </button>
              </div>
            </div>
            <div className="settings-card">
              <h4>Brand Text</h4>
              <div className="form-grid">
                <input
                  name="app_name"
                  placeholder="App name"
                  value={branding.app_name}
                  onChange={handleBrandingChange}
                />
                <input
                  name="app_tagline"
                  placeholder="Tagline"
                  value={branding.app_tagline}
                  onChange={handleBrandingChange}
                />
              </div>
            </div>
          </div>
        )}

        {activeTab === 'contact' && (
          <div className="settings-section">
            <div className="settings-card">
              <h4>Support</h4>
              <div className="form-grid">
                <input
                  name="support_email"
                  placeholder="Support email"
                  value={branding.support_email}
                  onChange={handleBrandingChange}
                />
                <input
                  name="support_phone"
                  placeholder="Support phone"
                  value={branding.support_phone}
                  onChange={handleBrandingChange}
                />
                <input
                  name="support_address"
                  placeholder="Support address"
                  value={branding.support_address}
                  onChange={handleBrandingChange}
                />
              </div>
            </div>
          </div>
        )}

        {activeTab === 'social' && (
          <div className="settings-section">
            <div className="settings-card">
              <h4>Social Profiles</h4>
              <div className="form-grid">
                <input
                  name="facebook_url"
                  placeholder="Facebook URL"
                  value={branding.facebook_url}
                  onChange={handleBrandingChange}
                />
                <input
                  name="instagram_url"
                  placeholder="Instagram URL"
                  value={branding.instagram_url}
                  onChange={handleBrandingChange}
                />
                <input
                  name="linkedin_url"
                  placeholder="LinkedIn URL"
                  value={branding.linkedin_url}
                  onChange={handleBrandingChange}
                />
                <input
                  name="twitter_url"
                  placeholder="Twitter URL"
                  value={branding.twitter_url}
                  onChange={handleBrandingChange}
                />
              </div>
            </div>
          </div>
        )}

        {activeTab === 'pricing' && (
          <div className="settings-section">
            <div className="settings-card">
              <h4>Candidate Pricing</h4>
              <div className="form-grid">
        <label>
                  Candidate activation fee (KWD)
          <input
            type="number"
            step="0.01"
            value={fee}
            onChange={(event) => setFee(event.target.value)}
          />
        </label>
                <label>
                  Candidate unlock fee (KWD)
                  <input
                    type="number"
                    step="0.01"
                    value={unlockFee}
                    onChange={(event) => setUnlockFee(event.target.value)}
                  />
                </label>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'seo' && (
          <div className="settings-section">
            <div className="settings-card">
              <h4>SEO Metadata</h4>
              <div className="form-grid">
                <input
                  name="meta_title"
                  placeholder="Meta title"
                  value={seo.meta_title}
                  onChange={handleSeoChange}
                />
                <input
                  name="meta_keywords"
                  placeholder="Meta keywords (comma separated)"
                  value={seo.meta_keywords}
                  onChange={handleSeoChange}
                />
                <textarea
                  name="meta_description"
                  placeholder="Meta description"
                  rows="3"
                  value={seo.meta_description}
                  onChange={handleSeoChange}
                />
                <input
                  name="favicon_url"
                  placeholder="Favicon URL (.ico/.png)"
                  value={seo.favicon_url}
                  onChange={handleSeoChange}
                />
              </div>
            </div>
          </div>
        )}

        {activeTab === 'theme' && (
          <div className="settings-section">
            <div className="settings-card">
              <div className="settings-card-header">
                <h4>Theme Colors</h4>
                <button
                  type="button"
                  className="ghost-button"
                  onClick={handleResetToMobileTheme}
                >
                  Reset to Mobile App Theme
                </button>
              </div>
              <p className="muted" style={{ marginBottom: '1rem' }}>
                Default colors match the Shugal mobile app theme (Primary: #075056)
              </p>
            </div>
            <div className="settings-card">
              <h4>Light Theme</h4>
              <div className="form-grid">
                <div className="color-field">
                  <span>Primary</span>
                  <div className="color-input">
                    <input
                      type="color"
                      name="light_primary"
                      value={theme.light_primary}
                      onChange={handleThemeChange}
                    />
                    <input
                      type="text"
                      name="light_primary"
                      value={theme.light_primary}
                      onChange={handleThemeChange}
                    />
                  </div>
                </div>
                <div className="color-field">
                  <span>Primary Contrast</span>
                  <div className="color-input">
                    <input
                      type="color"
                      name="light_primary_contrast"
                      value={theme.light_primary_contrast}
                      onChange={handleThemeChange}
                    />
                    <input
                      type="text"
                      name="light_primary_contrast"
                      value={theme.light_primary_contrast}
                      onChange={handleThemeChange}
                    />
                  </div>
                </div>
                <div className="color-field">
                  <span>Surface</span>
                  <div className="color-input">
                    <input
                      type="color"
                      name="light_surface"
                      value={theme.light_surface}
                      onChange={handleThemeChange}
                    />
                    <input
                      type="text"
                      name="light_surface"
                      value={theme.light_surface}
                      onChange={handleThemeChange}
                    />
                  </div>
                </div>
                <div className="color-field">
                  <span>Panel</span>
                  <div className="color-input">
                    <input
                      type="color"
                      name="light_panel"
                      value={theme.light_panel}
                      onChange={handleThemeChange}
                    />
                    <input
                      type="text"
                      name="light_panel"
                      value={theme.light_panel}
                      onChange={handleThemeChange}
                    />
                  </div>
                </div>
                <div className="color-field">
                  <span>Card</span>
                  <div className="color-input">
                    <input
                      type="color"
                      name="light_card"
                      value={theme.light_card}
                      onChange={handleThemeChange}
                    />
                    <input
                      type="text"
                      name="light_card"
                      value={theme.light_card}
                      onChange={handleThemeChange}
                    />
                  </div>
                </div>
                <div className="color-field">
                  <span>Text</span>
                  <div className="color-input">
                    <input
                      type="color"
                      name="light_text"
                      value={theme.light_text}
                      onChange={handleThemeChange}
                    />
                    <input
                      type="text"
                      name="light_text"
                      value={theme.light_text}
                      onChange={handleThemeChange}
                    />
                  </div>
                </div>
                <div className="color-field">
                  <span>Muted</span>
                  <div className="color-input">
                    <input
                      type="color"
                      name="light_muted"
                      value={theme.light_muted}
                      onChange={handleThemeChange}
                    />
                    <input
                      type="text"
                      name="light_muted"
                      value={theme.light_muted}
                      onChange={handleThemeChange}
                    />
                  </div>
                </div>
                <div className="color-field">
                  <span>Border</span>
                  <div className="color-input">
                    <input
                      type="color"
                      name="light_border"
                      value={theme.light_border}
                      onChange={handleThemeChange}
                    />
                    <input
                      type="text"
                      name="light_border"
                      value={theme.light_border}
                      onChange={handleThemeChange}
                    />
                  </div>
                </div>
                <div className="color-field">
                  <span>Accent</span>
                  <div className="color-input">
                    <input
                      type="color"
                      name="light_accent"
                      value={theme.light_accent}
                      onChange={handleThemeChange}
                    />
                    <input
                      type="text"
                      name="light_accent"
                      value={theme.light_accent}
                      onChange={handleThemeChange}
                    />
                  </div>
                </div>
              </div>
            </div>
            <div className="settings-card">
              <h4>Dark Theme</h4>
              <div className="form-grid">
                <div className="color-field">
                  <span>Primary</span>
                  <div className="color-input">
                    <input
                      type="color"
                      name="dark_primary"
                      value={theme.dark_primary}
                      onChange={handleThemeChange}
                    />
                    <input
                      type="text"
                      name="dark_primary"
                      value={theme.dark_primary}
                      onChange={handleThemeChange}
                    />
                  </div>
                </div>
                <div className="color-field">
                  <span>Primary Contrast</span>
                  <div className="color-input">
                    <input
                      type="color"
                      name="dark_primary_contrast"
                      value={theme.dark_primary_contrast}
                      onChange={handleThemeChange}
                    />
                    <input
                      type="text"
                      name="dark_primary_contrast"
                      value={theme.dark_primary_contrast}
                      onChange={handleThemeChange}
                    />
                  </div>
                </div>
                <div className="color-field">
                  <span>Surface</span>
                  <div className="color-input">
                    <input
                      type="color"
                      name="dark_surface"
                      value={theme.dark_surface}
                      onChange={handleThemeChange}
                    />
                    <input
                      type="text"
                      name="dark_surface"
                      value={theme.dark_surface}
                      onChange={handleThemeChange}
                    />
                  </div>
                </div>
                <div className="color-field">
                  <span>Panel</span>
                  <div className="color-input">
                    <input
                      type="color"
                      name="dark_panel"
                      value={theme.dark_panel}
                      onChange={handleThemeChange}
                    />
                    <input
                      type="text"
                      name="dark_panel"
                      value={theme.dark_panel}
                      onChange={handleThemeChange}
                    />
                  </div>
                </div>
                <div className="color-field">
                  <span>Card</span>
                  <div className="color-input">
                    <input
                      type="color"
                      name="dark_card"
                      value={theme.dark_card}
                      onChange={handleThemeChange}
                    />
                    <input
                      type="text"
                      name="dark_card"
                      value={theme.dark_card}
                      onChange={handleThemeChange}
                    />
                  </div>
                </div>
                <div className="color-field">
                  <span>Text</span>
                  <div className="color-input">
                    <input
                      type="color"
                      name="dark_text"
                      value={theme.dark_text}
                      onChange={handleThemeChange}
                    />
                    <input
                      type="text"
                      name="dark_text"
                      value={theme.dark_text}
                      onChange={handleThemeChange}
                    />
                  </div>
                </div>
                <div className="color-field">
                  <span>Muted</span>
                  <div className="color-input">
                    <input
                      type="color"
                      name="dark_muted"
                      value={theme.dark_muted}
                      onChange={handleThemeChange}
                    />
                    <input
                      type="text"
                      name="dark_muted"
                      value={theme.dark_muted}
                      onChange={handleThemeChange}
                    />
                  </div>
                </div>
                <div className="color-field">
                  <span>Border</span>
                  <div className="color-input">
                    <input
                      type="color"
                      name="dark_border"
                      value={theme.dark_border}
                      onChange={handleThemeChange}
                    />
                    <input
                      type="text"
                      name="dark_border"
                      value={theme.dark_border}
                      onChange={handleThemeChange}
                    />
                  </div>
                </div>
                <div className="color-field">
                  <span>Accent</span>
                  <div className="color-input">
                    <input
                      type="color"
                      name="dark_accent"
                      value={theme.dark_accent}
                      onChange={handleThemeChange}
                    />
                    <input
                      type="text"
                      name="dark_accent"
                      value={theme.dark_accent}
                      onChange={handleThemeChange}
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        <div className="settings-footer">
        <button className="primary-button" type="submit" disabled={saving}>
            {saving ? 'Saving...' : 'Save Settings'}
        </button>
        </div>
      </form>
    </div>
  )
}

export default Settings
