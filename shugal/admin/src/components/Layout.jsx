import { useEffect, useState } from 'react'
import { NavLink, Outlet, useNavigate } from 'react-router-dom'
import {
  IconActivityLog,
  IconCandidates,
  IconCompanies,
  IconDashboard,
  IconDeletion,
  IconJobs,
  IconCountries,
  IconLookups,
  IconQuestions,
  IconSettings,
  IconTransactions,
} from './Icons'
import { get, setToken } from '../api/client'
import { useTheme } from './ThemeProvider'

const Layout = () => {
  const navigate = useNavigate()
  const { theme, setTheme } = useTheme()
  const [branding, setBranding] = useState({
    app_name: 'Shugal Admin',
    app_logo: '',
    app_logo_light: '/logo-dark.png',
    app_logo_dark: '/logo-light.png',
    app_tagline: 'Recruitment platform',
  })

  // Get the appropriate logo based on theme
  // app_logo_dark = light-colored logo shown on dark theme
  // app_logo_light = dark-colored logo shown on light theme
  // Theme-specific logos take priority over generic app_logo
  const themeLogo = theme === 'dark' ? branding.app_logo_dark : branding.app_logo_light
  const currentLogo = themeLogo || branding.app_logo
  const [adminUser, setAdminUser] = useState(null)
  const [collapsed, setCollapsed] = useState(() =>
    localStorage.getItem('admin_sidebar_collapsed') === 'true',
  )
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)

  const navItems = [
    { to: '/', label: 'Dashboard', icon: <IconDashboard /> },
    { to: '/candidates', label: 'Candidates', icon: <IconCandidates /> },
    { to: '/companies', label: 'Companies', icon: <IconCompanies /> },
    { to: '/jobs', label: 'Jobs', icon: <IconJobs /> },
    { to: '/transactions', label: 'Transactions', icon: <IconTransactions /> },
    { to: '/activity-logs', label: 'Activity Logs', icon: <IconActivityLog /> },
    { to: '/deletion-requests', label: 'Deletion Requests', icon: <IconDeletion /> },
    { to: '/lookups', label: 'Lookups', icon: <IconLookups /> },
    { to: '/countries', label: 'Countries', icon: <IconCountries /> },
    { to: '/settings', label: 'Settings', icon: <IconSettings /> },
    { to: '/resume-questions', label: 'Resume Questions', icon: <IconQuestions /> },
  ]

  const handleLogout = () => {
    setToken(null)
    navigate('/login')
  }

  useEffect(() => {
    const loadBranding = async () => {
      try {
        const data = await get('/admin/settings?group=branding')
        const map = data.reduce((acc, item) => {
          acc[item.key] = item.value
          return acc
        }, {})
        setBranding((prev) => ({ ...prev, ...map }))
      } catch (err) {
        // Ignore branding load errors to keep layout responsive
      }
    }
    loadBranding()
  }, [])

  useEffect(() => {
    const loadUser = async () => {
      try {
        const data = await get('/auth/me')
        setAdminUser(data.user)
      } catch (err) {
        // Ignore auth errors here; layout still renders
      }
    }
    loadUser()
  }, [])

  useEffect(() => {
    localStorage.setItem('admin_sidebar_collapsed', String(collapsed))
  }, [collapsed])

  return (
    <div className="app-shell">
      {/* Mobile overlay */}
      <div
        className={`sidebar-overlay ${mobileMenuOpen ? 'visible' : ''}`}
        onClick={() => setMobileMenuOpen(false)}
      />
      <aside className={`sidebar ${collapsed ? 'collapsed' : ''} ${mobileMenuOpen ? 'mobile-open' : ''}`}>
        <div className="brand-block">
          <img className="brand-logo" src={currentLogo} alt="Shugal" />
        </div>
        <nav className="nav">
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              onClick={() => setMobileMenuOpen(false)}
            >
              <span className="nav-icon" aria-hidden="true">
                {item.icon}
              </span>
              <span className="nav-label">{item.label}</span>
            </NavLink>
          ))}
        </nav>
      </aside>
      <main className="main">
        <header className="topbar">
          <div className="topbar-left">
            <button
              className="mobile-menu-btn"
              onClick={() => setMobileMenuOpen((prev) => !prev)}
              title="Menu"
            >
              ☰
            </button>
            <span className="muted topbar-email">
              {adminUser?.email ? `Signed in as ${adminUser.email}` : 'Admin Console'}
            </span>
          </div>
          <div className="topbar-actions">
            <button
              className="ghost-button sidebar-toggle"
              onClick={() => setCollapsed((prev) => !prev)}
              title={collapsed ? 'Show sidebar' : 'Hide sidebar'}
            >
              {collapsed ? '☰' : '⟨⟨'}
            </button>
            <button
              className="theme-toggle"
              onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
            >
              {theme === 'dark' ? 'Light mode' : 'Dark mode'}
            </button>
            <button className="ghost-button" onClick={handleLogout}>
              Log out
            </button>
          </div>
        </header>
        <section className="content">
          <Outlet />
        </section>
      </main>
    </div>
  )
}

export default Layout
