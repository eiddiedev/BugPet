import type { ActivityReading, ToolKind } from './activityMonitor'
import type { PetLevel, PetToolKind } from './growth'
import type { AppLanguage } from './petVoices'
import { getStateMessage } from './petVoices'

export type PetState = 'idle' | 'focused' | 'chaotic'

export interface PetViewModel extends ActivityReading {
  state: PetState
  switchCount: number
  recentMessage: string
  bubbleVisibleUntil: number
  toolLabel: string
}

const STATUS_LABELS: Record<PetState, string> = {
  idle: 'Idle',
  focused: 'Focused',
  chaotic: 'Chaotic',
}

const TOOL_LABELS: Record<ToolKind, string> = {
  bugcat: 'BugCat',
  trae: 'TRAE SOLO',
  codex: 'Codex',
  claudecode: 'Claude Code',
  other: 'Watching',
}

export class StateEngine {
  private currentState: PetState | null = null
  private lastTrackedAppName = ''
  private switchTimestamps: number[] = []
  private recentMessage = ''
  private nextSpeakAt = Date.now() + 45_000
  private bubbleVisibleUntil = 0

  update(reading: ActivityReading, selectedTool: PetToolKind, level: PetLevel, language: AppLanguage): PetViewModel {
    const now = Date.now()
    const appName = reading.appName.trim().toLowerCase()
    const shouldIgnoreApp = this.isIgnoredApp(appName)

    // Only count true app switches between non-BugPet apps.
    if (!shouldIgnoreApp && this.lastTrackedAppName && appName && appName !== this.lastTrackedAppName) {
      this.switchTimestamps.push(now)
    }

    if (!shouldIgnoreApp && appName) {
      this.lastTrackedAppName = appName
    }

    this.switchTimestamps = this.switchTimestamps.filter((timestamp) => now - timestamp <= 60_000)

    const switchCount = this.switchTimestamps.length
    const nextState = this.resolveState(reading.idleSeconds, switchCount)
    const stateChanged = this.currentState === null || nextState !== this.currentState

    if (stateChanged || this.shouldRepeatMessage(now, nextState, reading.idleSeconds)) {
      this.recentMessage = this.pickMessage(selectedTool, level, nextState, language)
      this.nextSpeakAt = now + this.nextCooldown(nextState)
      this.bubbleVisibleUntil = now + 5_000
    }

    this.currentState = nextState

    return {
      ...reading,
      state: nextState,
      switchCount,
      recentMessage: this.recentMessage,
      bubbleVisibleUntil: this.bubbleVisibleUntil,
      toolLabel: reading.toolKind === 'other' ? reading.appName || TOOL_LABELS.other : TOOL_LABELS[reading.toolKind],
    }
  }

  overrideMessage(message: string, visibleUntil = Date.now() + 2_400): void {
    this.recentMessage = message
    this.bubbleVisibleUntil = visibleUntil
  }

  private resolveState(idleSeconds: number, switchCount: number): PetState {
    if (idleSeconds >= 60) {
      return 'idle'
    }

    if (switchCount >= 8) {
      return 'chaotic'
    }

    return 'focused'
  }

  private pickMessage(tool: PetToolKind, level: PetLevel, state: PetState, language: AppLanguage): string {
    return getStateMessage(tool, level, state, language, this.recentMessage)
  }

  private shouldRepeatMessage(now: number, state: PetState, idleSeconds: number): boolean {
    if (now < this.nextSpeakAt) {
      return false
    }

    // Focused can gently rotate lines when the user is clearly active.
    if (state === 'focused') {
      return idleSeconds < 10
    }

    // Idle can occasionally repeat if the user has truly been away for a while.
    if (state === 'idle') {
      return idleSeconds >= 120
    }

    // Chaotic can repeat, but only after cooldown.
    return state === 'chaotic'
  }

  private nextCooldown(state: PetState): number {
    switch (state) {
      case 'idle':
        return randomInRange(90_000, 150_000)
      case 'chaotic':
        return randomInRange(45_000, 75_000)
      case 'focused':
      default:
        return randomInRange(55_000, 90_000)
    }
  }

  private isIgnoredApp(appName: string): boolean {
    return appName === '' || appName.includes('bugpet')
  }
}

function randomInRange(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min
}

export function getStatusLabel(state: PetState, language: AppLanguage): string {
  if (language === 'en') {
    return STATUS_LABELS[state]
  }

  if (state === 'idle') {
    return '发呆中'
  }

  if (state === 'focused') {
    return '专注中'
  }

  return '有点乱'
}
