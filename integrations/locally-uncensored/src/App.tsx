import { useEffect } from 'react'
import { AppShell } from './components/layout/AppShell'

function App() {
  useEffect(() => {
    // In Tauri: show the window once React has rendered (window starts hidden)
    if (window.__TAURI_INTERNALS__) {
      import('@tauri-apps/api/core').then(({ invoke }) => {
        invoke('show_window').catch(() => {})
      })
    }
  }, [])

  return <AppShell />
}

export default App
