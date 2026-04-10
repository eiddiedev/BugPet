import { appWindow } from '@tauri-apps/api/window'
import type { MouseEvent } from 'react'
import petImage from './assets/bugpet-pet.png'
import './App.css'

function App() {
  const handlePointerDown = async (event: MouseEvent<HTMLElement>) => {
    if (event.button !== 0) {
      return
    }

    await appWindow.startDragging()
  }

  return (
    <main className="app-shell" onMouseDown={handlePointerDown}>
      <section className="pet-scene" aria-label="BugPet desktop pet">
        <div className="bubble" aria-hidden="true">
          <p className="bubble-label">BugPet</p>
          <p className="bubble-text">我先在这盯着你写代码。</p>
        </div>

        <div className="pet-wrap">
          <div className="pet-shadow" />
          <img className="pet-art" src={petImage} alt="BugPet pet" draggable={false} />
        </div>
      </section>
    </main>
  )
}

export default App
