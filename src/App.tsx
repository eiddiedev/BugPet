import { appWindow } from '@tauri-apps/api/window'
import petImage from './assets/bugpet-pet.png'
import './App.css'

function App() {
  const handlePointerDown = async () => {
    await appWindow.startDragging()
  }

  return (
    <main className="app-shell">
      <section className="pet-scene" aria-label="BugPet desktop pet">
        <div className="bubble" aria-hidden="true">
          <p className="bubble-label">BugPet</p>
          <p className="bubble-text">我先在这盯着你写代码。</p>
        </div>

        <div className="pet-wrap" onMouseDown={handlePointerDown}>
          <div className="pet-shadow" />
          <img className="pet-art" src={petImage} alt="BugPet pet" draggable={false} />
        </div>
      </section>
    </main>
  )
}

export default App
