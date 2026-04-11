import type { ActivityReading, ToolKind } from './activityMonitor'

export type PetState = 'idle' | 'focused' | 'chaotic'

export interface PetViewModel extends ActivityReading {
  state: PetState
  switchCount: number
  recentMessage: string
  bubbleVisibleUntil: number
  toolLabel: string
}

const MESSAGE_POOL: Record<PetState, string[]> = {
  idle: [
    '你怎么突然安静下来了 o.o',
    '我还在等你敲下一行呢。',
    '你是去思考了，还是去摸鱼了呀？',
    '这里一下子好安静。',
    '我先帮你守着这个窗口。',
    '咦，人呢，我刚刚还看到你。',
    '键盘都开始休息了。',
    '要不要回来看看我们写到哪啦？',
    '我在这儿，小声等你回来。',
    '这会儿像是在发呆欸。',
  ],
  focused: [
    '这个节奏很舒服，继续呀。',
    '你现在状态不错，我喜欢。',
    '嗯嗯，就是这种感觉。',
    '这段写得很顺耶。',
    '好欸，我们在推进了。',
    '手感上来了，别停。',
    '这几下敲得很有底气。',
    '我能感觉到你在认真了。',
    '很稳，很像今天要成事。',
    '现在这个状态，真不错 :>',
  ],
  chaotic: [
    '等等，我们先别乱跑呀。',
    '你刚刚切得我有点晕 @_@',
    '先盯一个地方试试看？',
    '别急别急，我们一个一个来。',
    '我知道你在找东西，但现在有点乱啦。',
    '要不先把眼前这一件做完？',
    '这几下切来切去，有点慌张哦。',
    '深呼吸，我们先抓住一个点。',
    '我还跟得上，但快跟晕了。',
    '先停一秒，再继续也不迟。',
  ],
}

const STATUS_LABELS: Record<PetState, string> = {
  idle: 'Idle',
  focused: 'Focused',
  chaotic: 'Chaotic',
}

const TOOL_LABELS: Record<ToolKind, string> = {
  trae: 'TRAE SOLO',
  codex: 'Codex',
  claudecode: 'Claude Code',
  other: 'Watching',
}

export class StateEngine {
  private currentState: PetState = 'focused'
  private lastTrackedAppName = ''
  private switchTimestamps: number[] = []
  private recentMessage = '我先在这盯着你写代码。'
  private nextSpeakAt = Date.now() + 45_000
  private bubbleVisibleUntil = 0

  update(reading: ActivityReading): PetViewModel {
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
    const stateChanged = nextState !== this.currentState

    if (stateChanged || this.shouldRepeatMessage(now, nextState, reading.idleSeconds)) {
      this.recentMessage = this.pickMessage(nextState)
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

  private resolveState(idleSeconds: number, switchCount: number): PetState {
    if (idleSeconds >= 60) {
      return 'idle'
    }

    if (switchCount >= 8) {
      return 'chaotic'
    }

    return 'focused'
  }

  private pickMessage(state: PetState): string {
    const pool = MESSAGE_POOL[state]
    const candidates = pool.filter((message) => message !== this.recentMessage)
    const source = candidates.length > 0 ? candidates : pool

    return source[Math.floor(Math.random() * source.length)]
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

export function getStatusLabel(state: PetState): string {
  return STATUS_LABELS[state]
}
