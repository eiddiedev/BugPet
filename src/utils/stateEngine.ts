import { ActivityMonitor } from './activityMonitor'

export type PetState = 'idle' | 'focused' | 'chaotic'

export class StateEngine {
  private activityMonitor: ActivityMonitor
  private currentState: PetState
  private messages: Record<PetState, string[]>

  constructor() {
    this.activityMonitor = new ActivityMonitor()
    this.currentState = 'idle'
    this.messages = {
      idle: [
        "你又消失了",
        "是在思考还是发呆？"
      ],
      focused: [
        "这波状态不错",
        "继续保持"
      ],
      chaotic: [
        "你现在有点乱",
        "你到底在干嘛？"
      ]
    }
  }

  // 更新状态
  async updateState(): Promise<PetState> {
    await this.activityMonitor.checkWindowSwitch()

    if (this.activityMonitor.isChaotic()) {
      this.currentState = 'chaotic'
    } else if (this.activityMonitor.isIdle()) {
      this.currentState = 'idle'
    } else if (this.activityMonitor.isActive()) {
      this.currentState = 'focused'
    }

    return this.currentState
  }

  // 获取当前状态
  getCurrentState(): PetState {
    return this.currentState
  }

  // 生成反馈文本
  generateMessage(): string {
    const stateMessages = this.messages[this.currentState]
    const randomIndex = Math.floor(Math.random() * stateMessages.length)
    return stateMessages[randomIndex]
  }

  // 记录用户活动
  recordActivity() {
    this.activityMonitor.recordActivity()
  }
}