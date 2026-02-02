import { createContext, useContext, useEffect, useMemo, useState } from 'react'
import { get } from '../api/client'

const ThemeContext = createContext({ theme: 'dark', setTheme: () => {} })

export const ThemeProvider = ({ children }) => {
  const [theme, setTheme] = useState(() => localStorage.getItem('admin_theme') || 'dark')
  const [themeSettings, setThemeSettings] = useState({})

  useEffect(() => {
    document.body.dataset.theme = theme
    localStorage.setItem('admin_theme', theme)
  }, [theme])

  useEffect(() => {
    const loadThemeSettings = async () => {
      try {
        const data = await get('/admin/settings?group=theme')
        const map = data.reduce((acc, item) => {
          acc[item.key] = item.value
          return acc
        }, {})
        setThemeSettings(map)
      } catch (err) {
        // Ignore if not authenticated yet
      }
    }
    loadThemeSettings()
    const handleRefresh = () => loadThemeSettings()
    window.addEventListener('theme-settings-updated', handleRefresh)
    return () => window.removeEventListener('theme-settings-updated', handleRefresh)
  }, [])

  useEffect(() => {
    const defaults = {
      light: {
        surface: '#f5f5f5',
        panel: '#ffffff',
        card: '#ffffff',
        text: '#1a1a1a',
        muted: '#666666',
        border: '#e0e0e0',
        primary: '#075056',
        primary_contrast: '#ffffff',
        accent: '#092a17',
      },
      dark: {
        surface: '#0a0f0f',
        panel: '#0f1a1b',
        card: '#152526',
        text: '#e8f4f5',
        muted: '#8ab4b7',
        border: 'rgba(7, 80, 86, 0.3)',
        primary: '#0a9ba5',
        primary_contrast: '#ffffff',
        accent: '#075056',
      },
    }

    const hexToRgba = (hex, alpha) => {
      const normalized = hex.replace('#', '')
      if (normalized.length !== 6) return null
      const r = parseInt(normalized.slice(0, 2), 16)
      const g = parseInt(normalized.slice(2, 4), 16)
      const b = parseInt(normalized.slice(4, 6), 16)
      return `rgba(${r}, ${g}, ${b}, ${alpha})`
    }

    const applyVar = (name, value, fallback) => {
      const finalValue = value || fallback
      if (finalValue) document.body.style.setProperty(name, finalValue)
    }

    if (theme === 'light') {
      applyVar('--surface', themeSettings.light_surface, defaults.light.surface)
      applyVar('--panel', themeSettings.light_panel, defaults.light.panel)
      applyVar('--card', themeSettings.light_card, defaults.light.card)
      applyVar('--text', themeSettings.light_text, defaults.light.text)
      applyVar('--muted', themeSettings.light_muted, defaults.light.muted)
      applyVar('--border', themeSettings.light_border, defaults.light.border)
      applyVar('--primary', themeSettings.light_primary, defaults.light.primary)
      applyVar(
        '--primary-contrast',
        themeSettings.light_primary_contrast,
        defaults.light.primary_contrast,
      )
      applyVar('--accent', themeSettings.light_accent, defaults.light.accent)
      const accentSoft = themeSettings.light_accent
        ? hexToRgba(themeSettings.light_accent, 0.12)
        : hexToRgba(defaults.light.accent, 0.12)
      applyVar('--accent-soft', accentSoft)
    } else {
      applyVar('--surface', themeSettings.dark_surface, defaults.dark.surface)
      applyVar('--panel', themeSettings.dark_panel, defaults.dark.panel)
      applyVar('--card', themeSettings.dark_card, defaults.dark.card)
      applyVar('--text', themeSettings.dark_text, defaults.dark.text)
      applyVar('--muted', themeSettings.dark_muted, defaults.dark.muted)
      applyVar('--border', themeSettings.dark_border, defaults.dark.border)
      applyVar('--primary', themeSettings.dark_primary, defaults.dark.primary)
      applyVar(
        '--primary-contrast',
        themeSettings.dark_primary_contrast,
        defaults.dark.primary_contrast,
      )
      applyVar('--accent', themeSettings.dark_accent, defaults.dark.accent)
      const accentSoft = themeSettings.dark_accent
        ? hexToRgba(themeSettings.dark_accent, 0.2)
        : hexToRgba(defaults.dark.accent, 0.2)
      applyVar('--accent-soft', accentSoft)
    }
  }, [theme, themeSettings])

  const value = useMemo(() => ({ theme, setTheme }), [theme])

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>
}

export const useTheme = () => useContext(ThemeContext)
