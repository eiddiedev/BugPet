import { useEffect, useRef, useState } from 'react'
import { appWindow } from '@tauri-apps/api/window'
import type { MouseEvent, PointerEvent as ReactPointerEvent } from 'react'
import traePet from './assets/bugpet-pet.png'
import traePetLevel2 from './assets/bugpet-pet-level2.png'
import traePetLevel3 from './assets/bugpet-pet-level3.png'
import codexPet from './assets/codex-pet-cutout.png'
import codexPetLevel2 from './assets/codex-pet-level2.png'
import codexPetLevel3 from './assets/codex-pet-level3.png'
import claudePet from './assets/claudecode-pet-cutout.png'
import claudePetLevel2 from './assets/claudecode-pet-level2.png'
import claudePetLevel3 from './assets/claudecode-pet-level3.png'
import bugcatPet from './assets/bugcat-level1.png'
import bugcatPetLevel2 from './assets/bugcat-level2.png'
import bugcatPetLevel3 from './assets/bugcat-level3.png'
import './App.css'
import { ActivityMonitor } from './utils/activityMonitor'
import type { ToolKind } from './utils/activityMonitor'
import { GrowthEngine, getLevelLabel } from './utils/growth'
import type { GrowthSnapshot, GrowthSnapshotMap, PetLevel, PetToolKind } from './utils/growth'
import type { AppLanguage } from './utils/petVoices'
import { getLevelUpMessage, getStateMessage } from './utils/petVoices'
import { StateEngine, getStatusLabel } from './utils/stateEngine'
import type { PetViewModel } from './utils/stateEngine'

type SpeechKind = 'state' | 'levelup'

interface SpeechState {
  message: string
  bubbleVisibleUntil: number
  kind: SpeechKind
}

const PET_OPTIONS: Array<{ tool: PetToolKind; name: string }> = [
  { tool: 'bugcat', name: 'BugCat' },
  { tool: 'trae', name: 'TRAE SOLO' },
  { tool: 'codex', name: 'Codex' },
  { tool: 'claudecode', name: 'Claude Code' },
]

const INITIAL_VIEW_MODEL: PetViewModel = {
  appName: 'BugPet',
  windowTitle: '',
  idleSeconds: 0,
  toolKind: 'other',
  state: 'focused',
  switchCount: 0,
  recentMessage: '',
  bubbleVisibleUntil: 0,
  toolLabel: 'BugPet',
}

const INITIAL_SPEECH: SpeechState = {
  message: '',
  bubbleVisibleUntil: 0,
  kind: 'state',
}

const TOOL_LABELS: Record<ToolKind, string> = {
  bugcat: 'BugCat',
  trae: 'TRAE SOLO',
  codex: 'Codex',
  claudecode: 'Claude Code',
  other: 'BugPet',
}

const LANGUAGE_STORAGE_KEY = 'bugpet-language-v1'

const UI_TEXT: Record<
  AppLanguage,
  {
    growthTitle: string
    currentLevel: string
    xp: string
    maxLevel: string
    toNextLevel: string
    downgrade: string
    upgrade: string
    choosePet: string
    back: string
    language: string
  }
> = {
  zh: {
    growthTitle: '宠物养成',
    currentLevel: '当前等级',
    xp: '经验值',
    maxLevel: '已满级',
    toNextLevel: '距下一级',
    downgrade: '降级',
    upgrade: '升级',
    choosePet: '选择宠物',
    back: '返回',
    language: '语言',
  },
  en: {
    growthTitle: 'Pet Growth',
    currentLevel: 'Level',
    xp: 'XP',
    maxLevel: 'Max Level',
    toNextLevel: 'To Next',
    downgrade: 'Level Down',
    upgrade: 'Level Up',
    choosePet: 'Choose Pet',
    back: 'Back',
    language: 'Language',
  },
}

function App() {
  const monitorRef = useRef(new ActivityMonitor())
  const engineRef = useRef(new StateEngine())
  const growthRef = useRef(new GrowthEngine())
  const pickerRef = useRef<HTMLDivElement | null>(null)
  const lastStateMessageRef = useRef('')
  const levelUpVisibleUntilRef = useRef(0)
  const [viewModel, setViewModel] = useState<PetViewModel>(INITIAL_VIEW_MODEL)
  const [growthSnapshots, setGrowthSnapshots] = useState<GrowthSnapshotMap>(() => growthRef.current.getAllSnapshots())
  const [speech, setSpeech] = useState<SpeechState>(INITIAL_SPEECH)
  const [isHovered, setIsHovered] = useState(false)
  const [isBubbleVisible, setIsBubbleVisible] = useState(false)
  const [selectedTool, setSelectedTool] = useState<PetToolKind>('bugcat')
  const [isPickerOpen, setIsPickerOpen] = useState(false)
  const [pickerPage, setPickerPage] = useState(1)
  const [language, setLanguage] = useState<AppLanguage>(loadLanguage)

  const handlePetDrag = async (event: MouseEvent<HTMLElement>) => {
    if (event.button !== 0) {
      return
    }
    event.stopPropagation()
    await appWindow.startDragging()
  }

  const handleContextMenu = (event: MouseEvent<HTMLElement>) => {
    event.preventDefault()
    event.stopPropagation()
    setIsPickerOpen(true)
    setPickerPage(1)
  }

  useEffect(() => {
    let cancelled = false

    const refresh = async () => {
      try {
        const reading = await monitorRef.current.read()
        const selectedSnapshot = growthRef.current.getSnapshot(selectedTool)
        const nextViewModel = engineRef.current.update(reading, selectedTool, selectedSnapshot.level, language)
        const nextGrowthSnapshot = growthRef.current.update(nextViewModel.state, reading.toolKind, selectedTool)

        if (cancelled) {
          return
        }

        setViewModel(nextViewModel)
        setGrowthSnapshots(growthRef.current.getAllSnapshots())

        let nextSpeech: SpeechState | null = null

        if (nextViewModel.recentMessage !== lastStateMessageRef.current && Date.now() >= levelUpVisibleUntilRef.current) {
          lastStateMessageRef.current = nextViewModel.recentMessage
          nextSpeech = {
            message: nextViewModel.recentMessage,
            bubbleVisibleUntil: nextViewModel.bubbleVisibleUntil,
            kind: 'state',
          }
        }

        if (nextGrowthSnapshot.leveledUp && isLevelUpTarget(nextGrowthSnapshot.level)) {
          levelUpVisibleUntilRef.current = Date.now() + 5_000
          nextSpeech = {
            message: getLevelUpMessage(selectedTool, nextGrowthSnapshot.level, language),
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

    return () => {
      cancelled = true
      window.clearInterval(pollingTimer)
    }
  }, [language, selectedTool])

  useEffect(() => {
    let bubbleTimer: number | null = null

    const updateBubbleVisibility = () => {
      const shouldBeVisible = !isPickerOpen && !!speech.message.trim() && (isHovered || speech.bubbleVisibleUntil > Date.now())
      setIsBubbleVisible(shouldBeVisible)

      if (shouldBeVisible && speech.bubbleVisibleUntil > Date.now()) {
        bubbleTimer = window.setTimeout(updateBubbleVisibility, 100)
      }
    }

    updateBubbleVisibility()

    return () => {
      if (bubbleTimer !== null) {
        window.clearTimeout(bubbleTimer)
      }
    }
  }, [speech, isHovered, isPickerOpen])

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

  const growthSnapshot = growthSnapshots[selectedTool]
  const petImage = getPetImage(selectedTool, growthSnapshot.level)
  const statusLabel = getStatusLabel(viewModel.state, language)
  const currentToolLabel = TOOL_LABELS[selectedTool]
  const bubbleLabel = statusLabel
  const uiText = UI_TEXT[language]
  const xpTarget = growthSnapshot.nextLevelXp ?? growthSnapshot.xp
  const progressText = `${growthSnapshot.xp} / ${xpTarget} XP`
  const progressLabel = growthSnapshot.nextLevelXp === null ? uiText.maxLevel : `${uiText.toNextLevel} ${growthSnapshot.xpToNext ?? 0} XP`

  const handleSelectTool = (tool: PetToolKind) => {
    const selectedSnapshot = growthSnapshots[tool]
    const nextMessage = getStateMessage(tool, selectedSnapshot.level, viewModel.state, language, speech.message)
    const visibleUntil = Date.now() + 2_400

    lastStateMessageRef.current = nextMessage
    engineRef.current.overrideMessage(nextMessage, visibleUntil)
    setSelectedTool(tool)
    setIsPickerOpen(false)
    setPickerPage(1)
    setSpeech({
      message: nextMessage,
      bubbleVisibleUntil: visibleUntil,
      kind: 'state',
    })
  }

  const stopPickerPropagation = (event: ReactPointerEvent<HTMLDivElement>) => {
    event.stopPropagation()
  }

  const applyGrowthSnapshot = (nextGrowthSnapshot: GrowthSnapshot) => {
    setGrowthSnapshots(growthRef.current.getAllSnapshots())

    if (nextGrowthSnapshot.leveledUp && isLevelUpTarget(nextGrowthSnapshot.level)) {
      setIsPickerOpen(false)
      levelUpVisibleUntilRef.current = Date.now() + 5_000
      setSpeech({
        message: getLevelUpMessage(selectedTool, nextGrowthSnapshot.level, language),
        bubbleVisibleUntil: levelUpVisibleUntilRef.current,
        kind: 'levelup',
      })
    }
  }

  const handleChangeLanguage = (nextLanguage: AppLanguage) => {
    if (nextLanguage === language) {
      return
    }

    saveLanguage(nextLanguage)
    setLanguage(nextLanguage)

    const selectedSnapshot = growthRef.current.getSnapshot(selectedTool)
    if (
      speech.kind === 'levelup' &&
      Date.now() < levelUpVisibleUntilRef.current &&
      isLevelUpTarget(selectedSnapshot.level)
    ) {
      const nextLevel = selectedSnapshot.level

      setSpeech({
        message: getLevelUpMessage(selectedTool, nextLevel, nextLanguage),
        bubbleVisibleUntil: levelUpVisibleUntilRef.current,
        kind: 'levelup',
      })
      return
    }

    const visibleUntil = Date.now() + 2_400
    const nextMessage = getStateMessage(selectedTool, selectedSnapshot.level, viewModel.state, nextLanguage)

    lastStateMessageRef.current = nextMessage
    engineRef.current.overrideMessage(nextMessage, visibleUntil)
    setSpeech({
      message: nextMessage,
      bubbleVisibleUntil: visibleUntil,
      kind: 'state',
    })
  }

  const handleJumpToNextLevel = () => {
    const nextGrowthSnapshot = growthRef.current.jumpToNextLevel(selectedTool)
    applyGrowthSnapshot(nextGrowthSnapshot)
  }

  const handleJumpToPreviousLevel = () => {
    const nextGrowthSnapshot = growthRef.current.jumpToPreviousLevel(selectedTool)
    applyGrowthSnapshot(nextGrowthSnapshot)
  }

  const handleMainContextMenu = (event: MouseEvent<HTMLElement>) => {
    event.preventDefault()
  }

  return (
    <main className="app-shell" onContextMenu={handleMainContextMenu}>
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
            {pickerPage === 1 && (
              <button
                className="pet-picker-close"
                type="button"
                onClick={() => setIsPickerOpen(false)}
              >
                ×
              </button>
            )}

            {pickerPage === 1 ? (
              <>
                <div className="pet-picker-toolbar">
                  <p className="pet-picker-title">{uiText.growthTitle}</p>
                  <div className="language-toggle" aria-label={uiText.language}>
                    <button
                      className={`language-toggle-button ${language === 'zh' ? 'language-toggle-button-active' : ''}`}
                      type="button"
                      onClick={() => handleChangeLanguage('zh')}
                    >
                      中
                    </button>
                    <button
                      className={`language-toggle-button ${language === 'en' ? 'language-toggle-button-active' : ''}`}
                      type="button"
                      onClick={() => handleChangeLanguage('en')}
                    >
                      EN
                    </button>
                  </div>
                </div>
                <div className="growth-card">
                  <div className="growth-head">
                    <div>
                      <p className="growth-label">{uiText.currentLevel}</p>
                      <p className="growth-level">{getLevelLabel(growthSnapshot.level)}</p>
                    </div>
                    <div className="growth-xp-block">
                      <p className="growth-label">{uiText.xp}</p>
                      <p className="growth-xp">{growthSnapshot.xp} XP</p>
                    </div>
                  </div>

                  <div className="growth-bar" aria-hidden="true">
                    <div className="growth-bar-fill" style={{ width: `${growthSnapshot.progressRatio * 100}%` }} />
                  </div>

                  <div className="growth-meta">
                    <span>{progressText}</span>
                    <span>{progressLabel}</span>
                  </div>
                </div>

                <div className="debug-tools">
                  <button
                    className="debug-button debug-button-small"
                    type="button"
                    onClick={handleJumpToPreviousLevel}
                    disabled={growthSnapshot.isMinLevel}
                  >
                    {growthSnapshot.isMinLevel ? 'Lv.1' : uiText.downgrade}
                  </button>
                  <button
                    className="debug-button debug-button-small"
                    type="button"
                    onClick={handleJumpToNextLevel}
                    disabled={growthSnapshot.isMaxLevel}
                  >
                    {growthSnapshot.isMaxLevel ? uiText.maxLevel : uiText.upgrade}
                  </button>
                </div>

                <button
                  className="pet-picker-nav"
                  type="button"
                  onClick={() => setPickerPage(2)}
                >
                  {uiText.choosePet} →
                </button>
              </>
            ) : (
              <>
                <div className="pet-picker-toolbar pet-picker-toolbar-page">
                  <button
                    className="pet-picker-nav pet-picker-nav-back"
                    type="button"
                    onClick={() => setPickerPage(1)}
                  >
                    ← {uiText.back}
                  </button>
                  <div className="language-toggle" aria-label={uiText.language}>
                    <button
                      className={`language-toggle-button ${language === 'zh' ? 'language-toggle-button-active' : ''}`}
                      type="button"
                      onClick={() => handleChangeLanguage('zh')}
                    >
                      中
                    </button>
                    <button
                      className={`language-toggle-button ${language === 'en' ? 'language-toggle-button-active' : ''}`}
                      type="button"
                      onClick={() => handleChangeLanguage('en')}
                    >
                      EN
                    </button>
                  </div>
                </div>
                <p className="pet-picker-subtitle">{uiText.choosePet}</p>
                <div className="pet-picker-list">
                  {PET_OPTIONS.map((option) => (
                    <button
                      key={option.tool}
                      className={`pet-picker-item ${selectedTool === option.tool ? 'pet-picker-item-active' : ''}`}
                      type="button"
                      onClick={() => handleSelectTool(option.tool)}
                    >
                      <div className="pet-picker-item-content">
                        <span className="pet-picker-name">
                          {option.name}
                          <span className="pet-picker-level-chip">{getLevelLabel(growthSnapshots[option.tool].level)}</span>
                        </span>
                        <img
                          className="pet-picker-preview"
                          src={getPetImage(option.tool, growthSnapshots[option.tool].level)}
                          alt={option.name}
                        />
                      </div>
                    </button>
                  ))}
                </div>
              </>
            )}
          </div>
        ) : null}

        <div className="pet-wrap" onContextMenu={handleContextMenu}>
          <div className="pet-shadow" />
          <img
            key={`${selectedTool}-${growthSnapshot.level}`}
            className="pet-art"
            src={petImage}
            alt={`${currentToolLabel} pet`}
            draggable={false}
            onMouseDown={handlePetDrag}
          />
        </div>
      </section>
    </main>
  )
}

function getPetImage(tool: PetToolKind, level: PetLevel): string {
  if (tool === 'bugcat') {
    if (level === 2) {
      return bugcatPetLevel2
    }

    if (level === 3) {
      return bugcatPetLevel3
    }

    return bugcatPet
  }

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
    if (level === 2) {
      return codexPetLevel2
    }

    if (level === 3) {
      return codexPetLevel3
    }

    return codexPet
  }

  if (tool === 'claudecode') {
    if (level === 2) {
      return claudePetLevel2
    }

    if (level === 3) {
      return claudePetLevel3
    }

    return claudePet
  }

  return bugcatPet
}

function isLevelUpTarget(level: PetLevel): level is 2 | 3 {
  return level === 2 || level === 3
}

function loadLanguage(): AppLanguage {
  if (typeof window === 'undefined') {
    return 'zh'
  }

  const saved = window.localStorage.getItem(LANGUAGE_STORAGE_KEY)
  return saved === 'en' ? 'en' : 'zh'
}

function saveLanguage(language: AppLanguage): void {
  if (typeof window === 'undefined') {
    return
  }

  window.localStorage.setItem(LANGUAGE_STORAGE_KEY, language)
}

export default App
