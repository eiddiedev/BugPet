import type { ToolKind } from './activityMonitor'
import type { PetState } from './stateEngine'

export type PetLevel = 1 | 2 | 3

export interface BugPetProfile {
  xp: number
  level: PetLevel
  focusedMsCarry: number
  chaoticMsCarry: number
}

export interface GrowthSnapshot {
  xp: number
  level: PetLevel
  progressRatio: number
  nextLevelXp: number | null
  xpToNext: number | null
  progressLabel: string
  leveledUp: boolean
  levelUpMessage: string | null
  isMaxLevel: boolean
  isMinLevel: boolean
}

const STORAGE_KEY = 'bugpet-progress-v1'
const FOCUSED_XP_INTERVAL_MS = 60_000
const CHAOTIC_XP_INTERVAL_MS = 240_000
const LEVEL_2_XP = 600
const LEVEL_3_XP = 1_800
const MAX_XP = LEVEL_3_XP
const MAX_ELAPSED_MS = 10_000

const DEFAULT_PROFILE: BugPetProfile = {
  xp: 0,
  level: 1,
  focusedMsCarry: 0,
  chaoticMsCarry: 0,
}

const LEVEL_UP_MESSAGES: Record<Exclude<PetLevel, 1>, string[]> = {
  2: [
    '我好像长大了一点点，已经二级啦。',
    '嘿嘿，我们把我养到二级了。',
    '再陪你多写一会儿，我会越来越厉害。',
  ],
  3: [
    '金光闪闪，我现在已经满级啦。',
    '被你好好养大了，我都有点得意了。',
    '三级毕业，小宠物今天很神气。',
  ],
}

export class GrowthEngine {
  private profile: BugPetProfile
  private lastTickAt = Date.now()

  constructor() {
    this.profile = loadProfile()
  }

  getSnapshot(): GrowthSnapshot {
    return toSnapshot(this.profile)
  }

  update(state: PetState, toolKind: ToolKind, now = Date.now()): GrowthSnapshot {
    const elapsed = Math.max(0, Math.min(now - this.lastTickAt, MAX_ELAPSED_MS))
    this.lastTickAt = now

    const previousLevel = this.profile.level
    let dirty = false

    if (this.profile.xp >= MAX_XP) {
      if (this.profile.focusedMsCarry !== 0 || this.profile.chaoticMsCarry !== 0) {
        this.profile.focusedMsCarry = 0
        this.profile.chaoticMsCarry = 0
        dirty = true
      }

      if (dirty) {
        saveProfile(this.profile)
      }

      return toSnapshot(this.profile)
    }

    if (isTrackableTool(toolKind)) {
      if (state === 'focused') {
        this.profile.focusedMsCarry += elapsed
      } else if (state === 'chaotic') {
        this.profile.chaoticMsCarry += elapsed
      }

      const focusedXp = Math.floor(this.profile.focusedMsCarry / FOCUSED_XP_INTERVAL_MS)
      const chaoticXp = Math.floor(this.profile.chaoticMsCarry / CHAOTIC_XP_INTERVAL_MS)
      const gainedXp = focusedXp + chaoticXp

      if (focusedXp > 0) {
        this.profile.focusedMsCarry %= FOCUSED_XP_INTERVAL_MS
        dirty = true
      }

      if (chaoticXp > 0) {
        this.profile.chaoticMsCarry %= CHAOTIC_XP_INTERVAL_MS
        dirty = true
      }

      if (gainedXp > 0) {
        this.profile.xp = clampXp(this.profile.xp + gainedXp)
        this.profile.level = levelForXp(this.profile.xp)

        if (this.profile.xp >= MAX_XP) {
          this.profile.focusedMsCarry = 0
          this.profile.chaoticMsCarry = 0
        }

        dirty = true
      }
    }

    const leveledUp = this.profile.level > previousLevel
    const levelUpMessage = leveledUp ? pickLevelUpMessage(this.profile.level) : null

    if (dirty || leveledUp) {
      saveProfile(this.profile)
    }

    return toSnapshot(this.profile, leveledUp, levelUpMessage)
  }

  applyDebugXp(amount: number, now = Date.now()): GrowthSnapshot {
    this.lastTickAt = now

    if (amount === 0) {
      return toSnapshot(this.profile)
    }

    const previousLevel = this.profile.level
    this.profile.xp = clampXp(this.profile.xp + amount)
    this.profile.level = levelForXp(this.profile.xp)

    if (this.profile.xp >= MAX_XP) {
      this.profile.focusedMsCarry = 0
      this.profile.chaoticMsCarry = 0
    }

    const leveledUp = this.profile.level > previousLevel
    const levelUpMessage = leveledUp ? pickLevelUpMessage(this.profile.level) : null

    saveProfile(this.profile)

    return toSnapshot(this.profile, leveledUp, levelUpMessage)
  }

  jumpToNextLevel(now = Date.now()): GrowthSnapshot {
    this.lastTickAt = now

    if (this.profile.level === 3) {
      return toSnapshot(this.profile)
    }

    const nextTarget = this.profile.level === 1 ? LEVEL_2_XP : LEVEL_3_XP
    const gainedXp = Math.max(0, nextTarget - this.profile.xp)

    return this.applyDebugXp(gainedXp, now)
  }

  jumpToPreviousLevel(now = Date.now()): GrowthSnapshot {
    this.lastTickAt = now

    if (this.profile.level === 1) {
      return toSnapshot(this.profile)
    }

    const previousTarget = this.profile.level === 3 ? LEVEL_3_XP - 1 : LEVEL_2_XP - 1
    const delta = previousTarget - this.profile.xp

    return this.applyDebugXp(delta, now)
  }
}

export function getLevelLabel(level: PetLevel): string {
  return `Lv.${level}`
}

function loadProfile(): BugPetProfile {
  if (typeof window === 'undefined') {
    return { ...DEFAULT_PROFILE }
  }

  try {
    const raw = window.localStorage.getItem(STORAGE_KEY)
    if (!raw) {
      return { ...DEFAULT_PROFILE }
    }

    const parsed = JSON.parse(raw) as Partial<BugPetProfile>

    return normalizeProfile(parsed)
  } catch (error) {
    console.warn('Failed to load BugPet profile from localStorage.', error)
    return { ...DEFAULT_PROFILE }
  }
}

function saveProfile(profile: BugPetProfile): void {
  if (typeof window === 'undefined') {
    return
  }

  try {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(profile))
  } catch (error) {
    console.warn('Failed to save BugPet profile to localStorage.', error)
  }
}

function normalizeProfile(input: Partial<BugPetProfile>): BugPetProfile {
  const xp = clampXp(asNonNegativeNumber(input.xp))

  return {
    xp,
    level: levelForXp(xp),
    focusedMsCarry: asNonNegativeNumber(input.focusedMsCarry),
    chaoticMsCarry: asNonNegativeNumber(input.chaoticMsCarry),
  }
}

function toSnapshot(
  profile: BugPetProfile,
  leveledUp = false,
  levelUpMessage: string | null = null,
): GrowthSnapshot {
  const nextLevelXp = nextThresholdForLevel(profile.level)
  const xpToNext = nextLevelXp === null ? null : Math.max(0, nextLevelXp - profile.xp)
  const progressRatio = getProgressRatio(profile.xp, profile.level)

  return {
    xp: profile.xp,
    level: profile.level,
    progressRatio,
    nextLevelXp,
    xpToNext,
    progressLabel: nextLevelXp === null ? '已满级' : `距下一级 ${xpToNext} XP`,
    leveledUp,
    levelUpMessage,
    isMaxLevel: nextLevelXp === null,
    isMinLevel: profile.level === 1 && profile.xp === 0,
  }
}

function getProgressRatio(xp: number, level: PetLevel): number {
  if (level === 1) {
    return clampRatio(xp / LEVEL_2_XP)
  }

  if (level === 2) {
    return clampRatio((xp - LEVEL_2_XP) / (LEVEL_3_XP - LEVEL_2_XP))
  }

  return 1
}

function nextThresholdForLevel(level: PetLevel): number | null {
  if (level === 1) {
    return LEVEL_2_XP
  }

  if (level === 2) {
    return LEVEL_3_XP
  }

  return null
}

function levelForXp(xp: number): PetLevel {
  if (xp >= LEVEL_3_XP) {
    return 3
  }

  if (xp >= LEVEL_2_XP) {
    return 2
  }

  return 1
}

function pickLevelUpMessage(level: PetLevel): string | null {
  if (level === 1) {
    return null
  }

  const pool = LEVEL_UP_MESSAGES[level]
  return pool[Math.floor(Math.random() * pool.length)]
}

function isTrackableTool(toolKind: ToolKind): boolean {
  return toolKind === 'trae' || toolKind === 'codex' || toolKind === 'claudecode'
}

function clampXp(xp: number): number {
  return Math.max(0, Math.min(MAX_XP, Math.floor(xp)))
}

function clampRatio(ratio: number): number {
  return Math.max(0, Math.min(1, ratio))
}

function asNonNegativeNumber(value: unknown): number {
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    return 0
  }

  return Math.max(0, value)
}
