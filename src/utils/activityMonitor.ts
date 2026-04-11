import { invoke } from '@tauri-apps/api/tauri'

export type ToolKind = 'trae' | 'codex' | 'claudecode' | 'other'

export interface ActivitySnapshot {
  appName: string
  windowTitle: string
  idleSeconds: number
}

export interface ActivityReading extends ActivitySnapshot {
  toolKind: ToolKind
}

export function detectToolKind(appName: string, windowTitle: string): ToolKind {
  const haystack = `${appName} ${windowTitle}`.toLowerCase()

  if (haystack.includes('trae')) {
    return 'trae'
  }

  if (haystack.includes('codex')) {
    return 'codex'
  }

  if (haystack.includes('claude')) {
    return 'claudecode'
  }

  return 'other'
}

export async function getActivitySnapshot(): Promise<ActivityReading> {
  const snapshot = await invoke<ActivitySnapshot>('get_activity_snapshot')

  return {
    ...snapshot,
    toolKind: detectToolKind(snapshot.appName, snapshot.windowTitle),
  }
}

export class ActivityMonitor {
  async read(): Promise<ActivityReading> {
    return getActivitySnapshot()
  }
}
