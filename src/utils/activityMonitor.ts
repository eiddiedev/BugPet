// 模拟获取当前活跃窗口名称
export async function getActiveWindow(): Promise<string> {
  // 模拟返回一个窗口名称
  return 'TRAE SOLO'
}

// 模拟用户输入状态检测（实际项目中可能需要更复杂的实现）
export class ActivityMonitor {
  private lastActivityTime: number
  private windowSwitchCount: number
  private lastWindow: string
  private windowSwitchTime: number

  constructor() {
    this.lastActivityTime = Date.now()
    this.windowSwitchCount = 0
    this.lastWindow = ''
    this.windowSwitchTime = Date.now()
  }

  // 记录用户活动
  recordActivity() {
    this.lastActivityTime = Date.now()
  }

  // 检测是否空闲
  isIdle(): boolean {
    const idleTime = Date.now() - this.lastActivityTime
    return idleTime > 60000 // 60秒无活动
  }

  // 检测窗口切换
  async checkWindowSwitch(): Promise<boolean> {
    const currentWindow = await getActiveWindow()
    if (currentWindow !== this.lastWindow) {
      this.lastWindow = currentWindow
      this.windowSwitchCount++
      
      // 重置窗口切换计数的时间
      const now = Date.now()
      if (now - this.windowSwitchTime > 60000) { // 1分钟
        this.windowSwitchCount = 1
        this.windowSwitchTime = now
      }
      return true
    }
    return false
  }

  // 获取窗口切换次数
  getWindowSwitchCount(): number {
    return this.windowSwitchCount
  }

  // 检测是否活跃
  isActive(): boolean {
    const activeTime = Date.now() - this.lastActivityTime
    return activeTime < 30000 // 30秒内有活动
  }

  // 检测是否混乱（频繁切换窗口）
  isChaotic(): boolean {
    return this.windowSwitchCount > 5 // 1分钟内切换超过5次
  }
}