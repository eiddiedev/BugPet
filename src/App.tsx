import { useEffect, useRef, useState } from 'react'
import { appWindow } from '@tauri-apps/api/window'
import type { MouseEvent, PointerEvent as ReactPointerEvent } from 'react'
import traePet from './assets/bugpet-pet.png'
import traePetLevel2 from './assets/bugpet-pet-level2.png'
import traePetLevel3 from './assets/bugpet-pet-level3.png'
import codexPet from './assets/codex-pet-cutout.png'
import claudePet from './assets/claudecode-pet-cutout.png'
import './App.css'
import { ActivityMonitor } from './utils/activityMonitor'
import type { ToolKind } from './utils/activityMonitor'
import { GrowthEngine, getLevelLabel } from './utils/growth'
import type { GrowthSnapshot, PetLevel } from './utils/growth'
import { StateEngine, getStatusLabel } from './utils/stateEngine'
import type { PetViewModel } from './utils/stateEngine'

type SpeechKind = 'state' | 'levelup'

interface SpeechState {
  message: string
  bubbleVisibleUntil: number
  kind: SpeechKind
}

const PET_OPTIONS: Array<{ tool: ToolKind; name: string; hint: string }> = [
  { tool: 'trae', name: 'TRAE SOLO', hint: '基础小宠物' },
  { tool: 'codex', name: 'Codex', hint: '蓝色云朵款' },
  { tool: 'claudecode', name: 'Claude Code', hint: '小像素怪' },
]

const INITIAL_VIEW_MODEL: PetViewModel = {
  appName: 'BugPet',
  windowTitle: '',
  idleSeconds: 0,
  toolKind: 'other',
  state: 'focused',
  switchCount: 0,
  recentMessage: '我先在这盯着你写代码。',
  bubbleVisibleUntil: Date.now() + 5_000,
  toolLabel: 'BugPet',
}

const INITIAL_SPEECH: SpeechState = {
  message: INITIAL_VIEW_MODEL.recentMessage,
  bubbleVisibleUntil: INITIAL_VIEW_MODEL.bubbleVisibleUntil,
  kind: 'state',
}

const TOOL_LABELS: Record<ToolKind, string> = {
  trae: 'TRAE SOLO',
  codex: 'Codex',
  claudecode: 'Claude Code',
  other: 'BugPet',
}

function App() {
  const monitorRef = useRef(new ActivityMonitor())
  const engineRef = useRef(new StateEngine())
  const growthRef = useRef(new GrowthEngine())
  const pickerRef = useRef<HTMLDivElement | null>(null)
  const lastStateMessageRef = useRef(INITIAL_VIEW_MODEL.recentMessage)
  const levelUpVisibleUntilRef = useRef(0)
  const [viewModel, setViewModel] = useState<PetViewModel>(INITIAL_VIEW_MODEL)
  const [growthSnapshot, setGrowthSnapshot] = useState<GrowthSnapshot>(() => growthRef.current.getSnapshot())
  const [speech, setSpeech] = useState<SpeechState>(INITIAL_SPEECH)
  const [isHovered, setIsHovered] = useState(false)
  const [clock, setClock] = useState(Date.now())
  const [selectedTool, setSelectedTool] = useState<ToolKind>('trae')
  const [isPickerOpen, setIsPickerOpen] = useState(false)

  const handlePointerDown = async (event: MouseEvent<HTMLElement>) => {
    if (event.button !== 0) {
      return
    }

    if ((event.target as HTMLElement).closest('.pet-picker')) {
      return
    }

    await appWindow.startDragging()
  }

  const handleContextMenu = (event: MouseEvent<HTMLElement>) => {
    event.preventDefault()
    setIsPickerOpen(true)
  }

  useEffect(() => {
    let cancelled = false

    const refresh = async () => {
      try {
        const reading = await monitorRef.current.read()
        const nextViewModel = engineRef.current.update(reading)
        const nextGrowthSnapshot = growthRef.current.update(nextViewModel.state, reading.toolKind)

        if (cancelled) {
          return
        }

        setViewModel(nextViewModel)
        setGrowthSnapshot(nextGrowthSnapshot)

        let nextSpeech: SpeechState | null = null

        if (nextViewModel.recentMessage !== lastStateMessageRef.current && Date.now() >= levelUpVisibleUntilRef.current) {
          lastStateMessageRef.current = nextViewModel.recentMessage
          nextSpeech = {
            message: nextViewModel.recentMessage,
            bubbleVisibleUntil: nextViewModel.bubbleVisibleUntil,
            kind: 'state',
          }
        }

        if (nextGrowthSnapshot.leveledUp && nextGrowthSnapshot.levelUpMessage) {
          levelUpVisibleUntilRef.current = Date.now() + 5_000
          nextSpeech = {
            message: nextGrowthSnapshot.levelUpMessage,
            bubbleVisibleUntil: levelUpVisibleUntilRef.current,
            kind: 'levelup',
          }
        }

        if (nextSpeech) {
          setSpeech(nextSpeech)
        }
      } catch (error) {
        console.error('Failed to refresh BugPet activity snapshot.', error)
      }
    }

    void refresh()

    const pollingTimer = window.setInterval(() => {
      void refresh()
    }, 3_000)

    const clockTimer = window.setInterval(() => {
      setClock(Date.now())
    }, 250)

    return () => {
      cancelled = true
      window.clearInterval(pollingTimer)
      window.clearInterval(clockTimer)
    }
  }, [])

  useEffect(() => {
    if (!isPickerOpen) {
      return
    }

    const handleWindowPointerDown = (event: PointerEvent) => {
      const target = event.target as Node | null
      if (pickerRef.current?.contains(target)) {
        return
      }

      setIsPickerOpen(false)
    }

    window.addEventListener('pointerdown', handleWindowPointerDown)

    return () => {
      window.removeEventListener('pointerdown', handleWindowPointerDown)
    }
  }, [isPickerOpen])

  const isBubbleVisible = !isPickerOpen && !!speech.message.trim() && (isHovered || speech.bubbleVisibleUntil > clock)
  const petImage = getPetImage(selectedTool, growthSnapshot.level)
  const statusLabel = getStatusLabel(viewModel.state)
  const currentToolLabel = TOOL_LABELS[selectedTool]
  const bubbleLabel =
    speech.kind === 'levelup'
      ? `${currentToolLabel} · ${getLevelLabel(growthSnapshot.level)}`
      : `${currentToolLabel} · ${statusLabel}`
  const xpTarget = growthSnapshot.nextLevelXp ?? growthSnapshot.xp
  const progressText = `${growthSnapshot.xp} / ${xpTarget} XP`
  const showTraeLevelVisuals = selectedTool === 'trae'
  const petHaloClassName = getPetHaloClassName(selectedTool, growthSnapshot.level)

  const handleSelectTool = (tool: ToolKind) => {
    setSelectedTool(tool)
    setIsPickerOpen(false)
    setSpeech((previous) => ({
      ...previous,
      bubbleVisibleUntil: Date.now() + 2_400,
    }))
  }

  const stopPickerPropagation = (event: ReactPointerEvent<HTMLDivElement>) => {
    event.stopPropagation()
  }

  const applyGrowthSnapshot = (nextGrowthSnapshot: GrowthSnapshot) => {
    setGrowthSnapshot(nextGrowthSnapshot)

    if (nextGrowthSnapshot.leveledUp && nextGrowthSnapshot.levelUpMessage) {
      setIsPickerOpen(false)
      levelUpVisibleUntilRef.current = Date.now() + 5_000
      setSpeech({
        message: nextGrowthSnapshot.levelUpMessage,
        bubbleVisibleUntil: levelUpVisibleUntilRef.current,
        kind: 'levelup',
      })
    }
  }

  const handleDebugXp = (amount: number) => {
    const nextGrowthSnapshot = growthRef.current.applyDebugXp(amount)
    applyGrowthSnapshot(nextGrowthSnapshot)
  }

  const handleJumpToNextLevel = () => {
    const nextGrowthSnapshot = growthRef.current.jumpToNextLevel()
    applyGrowthSnapshot(nextGrowthSnapshot)
  }

  const handleJumpToPreviousLevel = () => {
    const nextGrowthSnapshot = growthRef.current.jumpToPreviousLevel()
    applyGrowthSnapshot(nextGrowthSnapshot)
  }

  return (
    <main className="app-shell" onMouseDown={handlePointerDown} onContextMenu={handleContextMenu}>
      <section
        className="pet-scene"
        aria-label="BugPet desktop pet"
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => setIsHovered(false)}
      >
        {isBubbleVisible ? (
          <div className="bubble bubble-visible" aria-hidden={false}>
            <p className="bubble-label">{bubbleLabel}</p>
            <p className="bubble-text">{speech.message}</p>
          </div>
        ) : null}

        {isPickerOpen ? (
          <div
            ref={pickerRef}
            className="pet-picker"
            onPointerDown={stopPickerPropagation}
            onContextMenu={(event) => event.preventDefault()}
          >
            <p className="pet-picker-title">宠物养成</p>

            <div className="growth-card">
              <div className="growth-head">
                <div>
                  <p className="growth-label">当前等级</p>
                  <p className="growth-level">{getLevelLabel(growthSnapshot.level)}</p>
                </div>
                <div className="growth-xp-block">
                  <p className="growth-label">经验值</p>
                  <p className="growth-xp">{growthSnapshot.xp} XP</p>
                </div>
              </div>

              <div className="growth-bar" aria-hidden="true">
                <div className="growth-bar-fill" style={{ width: `${growthSnapshot.progressRatio * 100}%` }} />
              </div>

              <div className="growth-meta">
                <span>{progressText}</span>
                <span>{growthSnapshot.progressLabel}</span>
              </div>
            </div>

            <div className="debug-tools">
              <button className="debug-button" type="button" onClick={() => handleDebugXp(-10)}>
                -10 XP
              </button>
              <button className="debug-button" type="button" onClick={() => handleDebugXp(-50)}>
                -50 XP
              </button>
              <button className="debug-button" type="button" onClick={() => handleDebugXp(10)}>
                +10 XP
              </button>
              <button className="debug-button" type="button" onClick={() => handleDebugXp(50)}>
                +50 XP
              </button>
              <button
                className="debug-button debug-button-wide"
                type="button"
                onClick={handleJumpToPreviousLevel}
                disabled={growthSnapshot.isMinLevel}
              >
                {growthSnapshot.isMinLevel ? '已经是 Lv.1' : '降一级'}
              </button>
              <button
                className="debug-button debug-button-wide"
                type="button"
                onClick={handleJumpToNextLevel}
                disabled={growthSnapshot.isMaxLevel}
              >
                {growthSnapshot.isMaxLevel ? '已满级' : '升一级'}
              </button>
            </div>

            <p className="pet-picker-subtitle">选择宠物</p>
            <div className="pet-picker-list">
              {PET_OPTIONS.map((option) => (
                <button
                  key={option.tool}
                  className={`pet-picker-item ${selectedTool === option.tool ? 'pet-picker-item-active' : ''}`}
                  type="button"
                  onClick={() => handleSelectTool(option.tool)}
                >
                  <span className="pet-picker-name">{option.name}</span>
                  <span className="pet-picker-hint">{option.hint}</span>
                </button>
              ))}
            </div>
          </div>
        ) : null}

        <div className="pet-wrap">
          {showTraeLevelVisuals ? <div className={petHaloClassName} aria-hidden="true" /> : null}
          <div className="pet-shadow" />
          <img className="pet-art" src={petImage} alt={`${currentToolLabel} pet`} draggable={false} />
          <div className="level-badge">{getLevelLabel(growthSnapshot.level)}</div>
        </div>
      </section>
    </main>
  )
}

function getPetImage(tool: ToolKind, level: PetLevel): string {
  if (tool === 'trae') {
    if (level === 2) {
      return traePetLevel2
    }

    if (level === 3) {
      return traePetLevel3
    }

    return traePet
  }

  if (tool === 'codex') {
    return codexPet
  }

  if (tool === 'claudecode') {
    return claudePet
  }

  return traePet
}

function getPetHaloClassName(tool: ToolKind, level: PetLevel): string {
  const classNames = ['pet-halo']

  if (tool === 'trae') {
    classNames.push(`pet-halo-level-${level}`)
  }

  return classNames.join(' ')
}

export default App
