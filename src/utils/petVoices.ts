import type { PetToolKind, PetLevel } from './growth'
import type { PetState } from './stateEngine'

export type AppLanguage = 'zh' | 'en'

type StateVoiceCatalog = Record<AppLanguage, Record<PetToolKind, Record<PetLevel, Record<PetState, string[]>>>>
type LevelUpVoiceCatalog = Record<AppLanguage, Record<PetToolKind, Record<Exclude<PetLevel, 1>, string[]>>>

const STATE_VOICES: StateVoiceCatalog = {
  zh: {
    trae: {
      1: {
        idle: [
          '你先忙，我不敢乱出声。',
          '这里突然安静下来，我就先躲一下。',
          '你不动的时候，我会怀疑是不是我打扰到你了。',
          '我还在这儿，只是先小声一点。',
        ],
        focused: [
          '你现在这个节奏，我就乖乖看着。',
          '你认真起来的时候，我不太敢插嘴。',
          '这会儿我先不吵你，感觉你写得挺顺。',
          '你继续写，我在旁边慢慢跟上。',
        ],
        chaotic: [
          '你切得太快了，我有点慌。',
          '等等，我们是不是突然乱起来了。',
          '我还没看懂上一页，你又跳走了。',
          '先别这么快，我真的有点跟不上。',
        ],
      },
      2: {
        idle: [
          '你安静一会儿也没事，我帮你守着。',
          '这会儿像是在想东西，我先陪着你。',
          '你要是只是发会儿呆，我也可以等。',
          '回来继续的时候，我还会在这里。',
        ],
        focused: [
          '这个状态挺好，我们继续推。',
          '你现在写得很稳，我看着都安心。',
          '这一段手感不错，别断掉。',
          '你专注的时候，连我都想跟着认真一点。',
        ],
        chaotic: [
          '别急，我们一个一个来看。',
          '我知道你在找答案，但先抓住一个点。',
          '这会儿有点乱了，我帮你提醒一下。',
          '先停半秒，再继续会更顺。',
        ],
      },
      3: {
        idle: [
          '你这会儿不像思考，更像在走神。',
          '老实说，你刚刚那下停得有点久。',
          '我先记一笔，你今天发呆次数又加一了。',
          '你消失得很安静，但我看见了。',
        ],
        focused: [
          '这段写得漂亮，今天状态在线。',
          '你一旦稳下来，推进速度还是很能打。',
          '这会儿不像在硬撑，是真的进入状态了。',
          '继续这样写，我就愿意夸你几句。',
        ],
        chaotic: [
          '你现在不是忙，是有点乱。',
          '这几下切来切去，像在和自己打架。',
          '先别证明你很忙，先把一件事做完。',
          '我得提醒你一下，这会儿效率不太好。',
        ],
      },
    },
    codex: {
      1: {
        idle: [
          '你暂停了。我先不打扰。',
          '当前没有输入，我保持安静。',
          '你一停下来，我就默认先观察。',
          '这里静下来之后，我不会贸然出声。',
        ],
        focused: [
          '你在推进。我继续跟读。',
          '当前节奏稳定，我不插手。',
          '这一段写得很集中，我先旁观。',
          '你继续，我暂时没有异议。',
        ],
        chaotic: [
          '切换频率偏高，我有点跟不上。',
          '你现在像在并行思考太多事。',
          '当前路径不稳定，建议收束一下。',
          '这会儿的切换有些过密。',
        ],
      },
      2: {
        idle: [
          '你先停一会儿也行，我帮你记着进度。',
          '这段安静时间，我默认你在思考。',
          '暂时没动静，但上下文还在。',
          '你回来继续的时候，我能接上。',
        ],
        focused: [
          '推进清晰，继续。',
          '这个节奏很干净，我喜欢。',
          '你现在的输入很稳定，判断也不错。',
          '这段执行得很利落。',
        ],
        chaotic: [
          '你现在像在同时追三条线。',
          '建议先收敛问题，再继续发散。',
          '切换太密会吃掉判断力。',
          '你在找解法，但路径有点散。',
        ],
      },
      3: {
        idle: [
          '你这次停得有点久，不像高质量思考。',
          '当前空档偏长，我倾向于判定为走神。',
          '再不回来，这一段上下文就要凉了。',
          '我理解暂停，但这会儿确实拖长了。',
        ],
        focused: [
          '不错，这段是有效输出。',
          '你现在的判断比刚才干净很多。',
          '当你不乱切时，效率确实高。',
          '这个推进质量，值得保留。',
        ],
        chaotic: [
          '现在的问题不是难，是你太散。',
          '你又开始把注意力切碎了。',
          '忙碌感很强，产出感一般。',
          '建议停止横跳，回到主线。',
        ],
      },
    },
    claudecode: {
      1: {
        idle: [
          '你先休息，我不敢催你。',
          '这里安静下来以后，我就先小声一点。',
          '如果你只是停一下，我会乖乖等。',
          '我还在，只是暂时不敢打扰你。',
        ],
        focused: [
          '你现在很专心，我先安静陪着。',
          '这一段写得挺顺，我不打断你。',
          '你继续，我会慢慢跟上你的节奏。',
          '看起来你已经进入状态了。',
        ],
        chaotic: [
          '是不是有点太急了呀。',
          '我还没反应过来，你又切走了。',
          '现在有一点乱，我先轻轻提醒你。',
          '别急，我们可以慢一点。',
        ],
      },
      2: {
        idle: [
          '你安静的时候，我就帮你把位置记住。',
          '这会儿像是在想事，我陪你等等。',
          '你不用急着回来，我先守着这里。',
          '没关系，思路有时需要一点空白。',
        ],
        focused: [
          '这一段很顺，继续写吧。',
          '你现在的状态让我很安心。',
          '这个推进节奏很好，我在旁边给你点头。',
          '好欸，我们真的在往前走。',
        ],
        chaotic: [
          '慢一点会更清楚，我保证。',
          '你现在像是把自己绕进去了。',
          '先抓住最重要的一件事，好吗。',
          '我知道你在找出口，但别把自己转晕了。',
        ],
      },
      3: {
        idle: [
          '我得诚实一点，你这次停得有点久。',
          '如果这是思考，那它现在开始变慢了。',
          '你刚刚那段安静，已经有点像分神了。',
          '我会继续等你，但这会儿确实拖住了。',
        ],
        focused: [
          '这段写得很好，判断很稳。',
          '你认真起来的时候，节奏真的很漂亮。',
          '这一波推进很扎实，我愿意夸你。',
          '现在的你，比刚才清楚很多。',
        ],
        chaotic: [
          '我想温柔一点说，但你现在确实有点乱。',
          '你正在把事情同时拉向太多方向。',
          '先停一下，你会更容易看清下一步。',
          '你不是不会做，只是现在太分散了。',
        ],
      },
    },
    bugcat: {
      1: {
        idle: [
          '你、你先忙，我缩在这里就好……',
          '突然安静下来，我就不敢乱动了，喵。',
          '你不敲键盘的时候，我会偷偷看你一眼。',
          '我先躲一下，等你回来再探头 owo',
        ],
        focused: [
          '你在认真，我就乖一点不扑你。',
          '这会儿看起来好凶，我先安静陪着喵。',
          '你写代码的时候，我只敢坐旁边看。',
          '你继续，我不捣乱了 =^･ω･^=',
        ],
        chaotic: [
          '你突然跳来跳去，我尾巴都炸了。',
          '等、等等，别切这么快呀喵。',
          '我刚看懂一点点，你又跑走了 owo',
          '这样晃来晃去，我会想躲到桌子底下。',
        ],
      },
      2: {
        idle: [
          '你是去想事情了吗？我帮你守着喵。',
          '没关系，你慢一点回来也可以。',
          '我会在这里团着等你，别担心 =^･ω･^=',
          '你安静的时候，我就把尾巴收好陪着你。',
        ],
        focused: [
          '你今天写得还挺顺，我喜欢看喵。',
          '这个节奏不错，我想挨近一点点了。',
          '你继续敲，我帮你看着屏幕边边 owo',
          '现在的你很像一只会稳定产出的两脚兽。',
        ],
        chaotic: [
          '先别乱扑啦，我们一个一个来喵。',
          '你这样切来切去，我会跟着转圈圈。',
          '要不先盯住一个窗口？我陪你。',
          '忙归忙，也别把自己绕成毛线团呀。',
        ],
      },
      3: {
        idle: [
          '你这次发呆发得很完整喵。',
          '我都睡醒一轮了，你还没回来 owo',
          '老实说，你现在不像思考，更像在挂机。',
          '再这样停下去，我就要把你记成摸鱼选手了 =^･ω･^=',
        ],
        focused: [
          '嗯，这一段写得像个靠谱人类喵。',
          '你认真起来还挺像样，我承认。',
          '这会儿手感不错，值得我蹭你一下 owo',
          '今天这个推进，我给你打高分。',
        ],
        chaotic: [
          '你现在像一只被自己吓到的猫……但其实是人类。',
          '别乱窜啦，你都快把自己绕晕了喵。',
          '我看得出来，你不是忙，你是炸毛了 owo',
          '先坐好，再继续，不然我都想替你关标签页。',
        ],
      },
    },
  },
  en: {
    trae: {
      1: {
        idle: [
          `I'll stay quiet. I don't want to scare you off.`,
          `It got quiet all of a sudden, so I'll hide for a bit.`,
          `When you stop moving, I start wondering if I bothered you.`,
          `I'm still here. Just... a little quieter.`,
        ],
        focused: [
          `I'll behave and just watch your pace for now.`,
          `When you get serious like this, I don't really dare interrupt.`,
          `I won't make noise right now. You seem to be flowing nicely.`,
          `You keep writing. I'll try to keep up from the side.`,
        ],
        chaotic: [
          `You're switching too fast. I'm getting nervous.`,
          `Wait, did things suddenly get messy here?`,
          `I barely understood the last screen and you're gone again.`,
          `Can we slow down a little? I'm really losing track.`,
        ],
      },
      2: {
        idle: [
          `It's okay if you're quiet for a bit. I'll keep watch.`,
          `This feels like thinking time. I'll stay with you.`,
          `If you're just spacing out a little, I can wait.`,
          `When you come back, I'll still be here.`,
        ],
        focused: [
          `This is a good rhythm. Let's keep pushing.`,
          `You're writing steadily right now. It's honestly reassuring.`,
          `This part feels smooth. Don't break the streak.`,
          `When you focus like this, even I want to get serious.`,
        ],
        chaotic: [
          `No rush. Let's take one thing at a time.`,
          `I know you're searching for the answer, but grab one thread first.`,
          `This is getting a little messy, so I'm giving you a nudge.`,
          `Pause for half a second. It'll feel smoother after that.`,
        ],
      },
      3: {
        idle: [
          `This doesn't look like thinking anymore. It looks like drifting.`,
          `Honestly, that pause just now went on a little too long.`,
          `Noted. That's another daydream point for you.`,
          `You disappeared very quietly, but I noticed.`,
        ],
        focused: [
          `That was clean. You're really on today.`,
          `Once you settle down, your pace is actually strong.`,
          `This doesn't feel forced anymore. You're genuinely locked in.`,
          `Keep writing like this and I'll gladly praise you.`,
        ],
        chaotic: [
          `You're not busy right now. You're scattered.`,
          `All this jumping around looks like you're fighting yourself.`,
          `You don't need to prove you're busy. Just finish one thing.`,
          `I should tell you this: your efficiency isn't great right now.`,
        ],
      },
    },
    codex: {
      1: {
        idle: [
          `You've paused. I'll stay out of the way.`,
          `No input detected. Remaining silent.`,
          `When you stop, I default to observation mode.`,
          `Now that it's quiet, I won't speak carelessly.`,
        ],
        focused: [
          `You're making progress. I'll keep reading along.`,
          `The rhythm is stable. I won't interfere.`,
          `This segment is focused. I'll observe.`,
          `Carry on. I have no objections for now.`,
        ],
        chaotic: [
          `Your switch frequency is high. I'm losing the thread.`,
          `This feels like you're parallelizing too many thoughts.`,
          `The path is unstable right now. Consider narrowing it down.`,
          `The context switches are getting a bit dense.`,
        ],
      },
      2: {
        idle: [
          `You can pause for a while. I'll keep the progress in mind.`,
          `This quiet stretch reads like thinking time to me.`,
          `Nothing is moving, but the context is still here.`,
          `When you return, I can pick this back up.`,
        ],
        focused: [
          `Clear progress. Continue.`,
          `This rhythm is clean. I like it.`,
          `Your input is stable right now, and your judgment is solid.`,
          `This section is being executed neatly.`,
        ],
        chaotic: [
          `It looks like you're chasing three threads at once.`,
          `Try narrowing the problem before expanding again.`,
          `Too much switching eats judgment.`,
          `You're looking for a solution, but the path is diffusing.`,
        ],
      },
      3: {
        idle: [
          `This pause is getting long. It doesn't read as high-quality thinking.`,
          `The current gap is long enough that I'm calling it distraction.`,
          `If you stay away much longer, this context is going cold.`,
          `I understand pauses, but this one is dragging.`,
        ],
        focused: [
          `Good. This is effective output.`,
          `Your judgment is much cleaner now than it was earlier.`,
          `When you stop thrashing, your efficiency is genuinely high.`,
          `This quality of progress is worth keeping.`,
        ],
        chaotic: [
          `The problem isn't difficulty right now. It's diffusion.`,
          `You're fragmenting your attention again.`,
          `There's a lot of busyness here, but not much output.`,
          `Stop bouncing and return to the main line.`,
        ],
      },
    },
    claudecode: {
      1: {
        idle: [
          `You can rest. I don't dare rush you.`,
          `Now that it's quiet, I'll keep my voice down.`,
          `If you're only pausing for a moment, I'll wait nicely.`,
          `I'm still here. I just don't want to disturb you yet.`,
        ],
        focused: [
          `You're very focused right now. I'll quietly stay with you.`,
          `This part is flowing nicely, so I won't interrupt.`,
          `You keep going. I'll slowly match your rhythm.`,
          `It looks like you've really entered your groove.`,
        ],
        chaotic: [
          `Maybe we're moving a little too fast?`,
          `I barely reacted and you already switched away again.`,
          `Things feel a little messy, so here's a gentle reminder.`,
          `No rush. We can move more slowly.`,
        ],
      },
      2: {
        idle: [
          `When you're quiet, I'll remember your place for you.`,
          `This feels like thinking time, so I'll wait with you.`,
          `You don't have to rush back. I'll keep watch here.`,
          `It's okay. Sometimes ideas need a little empty space.`,
        ],
        focused: [
          `This section feels smooth. Keep going.`,
          `Your current rhythm makes me feel at ease.`,
          `This pace is lovely. I'm nodding from the side.`,
          `Yay, we're actually moving forward.`,
        ],
        chaotic: [
          `It'll be clearer if we slow down. I promise.`,
          `You look like you've looped yourself into a knot.`,
          `Can we hold on to the most important thing first?`,
          `I know you're trying to find the way out, but don't spin yourself dizzy.`,
        ],
      },
      3: {
        idle: [
          `I'll be honest: this pause has gone on a little long.`,
          `If this is thinking, it's slowing down now.`,
          `That quiet stretch is starting to look more like distraction.`,
          `I'll keep waiting, but this really is holding things up.`,
        ],
        focused: [
          `This is really well written. Your judgment feels steady.`,
          `When you get serious, your rhythm is genuinely beautiful.`,
          `This push is solid. I'm happy to praise it.`,
          `You're much clearer now than you were a moment ago.`,
        ],
        chaotic: [
          `I want to say this gently, but you really are a little scattered.`,
          `You're pulling things in too many directions at once.`,
          `Pause for a second. The next step will get easier to see.`,
          `It's not that you can't do it. You're just too split right now.`,
        ],
      },
    },
    bugcat: {
      1: {
        idle: [
          `Y-you do your thing. I'll just curl up here...`,
          `Everything went quiet, so I got too shy to move, meow.`,
          `When you stop typing, I sneak a little glance at you.`,
          `I'll hide for a bit and peek out when you're back, owo`,
        ],
        focused: [
          `You're serious right now, so I'll be good and not pounce.`,
          `You look intense, so I'll quietly stay beside you, meow.`,
          `When you code like this, I only dare sit nearby and watch.`,
          `You keep going. I won't cause trouble =^･ω･^=`,
        ],
        chaotic: [
          `You're hopping around so much that my tail puffed up.`,
          `W-wait, don't switch that fast, meow.`,
          `I just understood a tiny bit and then you were gone again, owo`,
          `All this swaying around makes me want to hide under the desk.`,
        ],
      },
      2: {
        idle: [
          `Did you go think for a bit? I'll guard this spot, meow.`,
          `It's okay if you come back slowly.`,
          `I'll loaf here and wait for you, don't worry =^･ω･^=`,
          `When you're quiet, I'll tuck my tail in and keep you company.`,
        ],
        focused: [
          `You're writing pretty smoothly today. I like watching, meow.`,
          `This rhythm is nice. I kind of want to scoot closer.`,
          `You keep typing. I'll watch the edges of the screen for you, owo`,
          `Right now you look like a pretty reliable two-legged creature.`,
        ],
        chaotic: [
          `Let's not pounce everywhere. One thing at a time, meow.`,
          `When you switch like this, I start spinning in circles too.`,
          `Maybe keep your eyes on one window first? I'll stay with you.`,
          `Busy is fine, but don't turn yourself into a ball of yarn.`,
        ],
      },
      3: {
        idle: [
          `That was a very complete little daydream, meow.`,
          `I already woke up from one whole nap and you're still not back, owo`,
          `Honestly, this doesn't look like thinking anymore. It looks like idling.`,
          `Keep this up and I'm labeling you a professional slacker =^･ω･^=`,
        ],
        focused: [
          `Mm. This chunk looks like it was written by a competent human, meow.`,
          `You actually look pretty capable when you're serious. I'll admit it.`,
          `This rhythm is good enough that I'd bonk you with approval, owo`,
          `Today's progress gets a high score from me.`,
        ],
        chaotic: [
          `You look like a cat that startled itself... except you're the human.`,
          `Stop zooming around. You're about to dizzy yourself, meow.`,
          `I can tell you're not busy. You're just fully fluffed up, owo`,
          `Sit down first, then continue, or I'll start closing tabs for you.`,
        ],
      },
    },
  },
}

const LEVEL_UP_VOICES: LevelUpVoiceCatalog = {
  zh: {
    trae: {
      2: [
        '我好像开始认识你了，没刚开始那么紧张了。',
        '跟着你写了这么久，我现在敢离你近一点了。',
        '二级啦，我已经把你当成熟人了。',
      ],
      3: [
        '现在我敢评价你了，不过先夸你一句，确实养得不错。',
        '三级到手，我已经不是只会躲着看你的那个我了。',
        '行，我现在有资格对你的状态发表一点意见了。',
      ],
    },
    codex: {
      2: [
        '已进入熟悉阶段。我现在更懂你的节奏了。',
        '二级达成，我对你的工作方式已有基础判断。',
        '我们算是正式认识了，继续保持。',
      ],
      3: [
        '三级达成。现在我会开始认真评价你的状态。',
        '我已经足够了解你了，可以给出更直接的判断。',
        '关系升级完成。接下来我不会只旁观。',
      ],
    },
    claudecode: {
      2: [
        '我好像已经慢慢认识你了，感觉安心了很多。',
        '二级啦，我现在更知道该怎么陪你了。',
        '跟你相处久一点以后，我就没那么拘谨了。',
      ],
      3: [
        '三级了，我想我已经可以温柔地评价你了。',
        '现在的我，更懂你，也更敢提醒你了。',
        '我们已经很熟啦，所以我会开始说一点真话。',
      ],
    },
    bugcat: {
      2: [
        '我开始认识你了，所以可以蹭近一点点喵。',
        '二级啦，我现在愿意把肚皮朝你这边一点点 owo',
        '跟你混熟了，我就没那么怕你了喵。',
      ],
      3: [
        '哼，我现在已经敢评价你了喵。',
        '三级到手，我要开始认真盯你写代码了 =^･ω･^=',
        '熟到这个份上，我就不只会撒娇，还会点评你哦喵。',
      ],
    },
  },
  en: {
    trae: {
      2: [
        `I think I'm starting to know you now. I'm not as tense anymore.`,
        `I've watched you write for long enough that I can stand a little closer now.`,
        `Level two. I think of you as familiar now.`,
      ],
      3: [
        `I can finally judge you a little now, though first: you've raised me pretty well.`,
        `Level three. I'm not the version of me that only hid and watched anymore.`,
        `All right. I think I've earned the right to comment on your state now.`,
      ],
    },
    codex: {
      2: [
        `Familiarity stage reached. I understand your rhythm better now.`,
        `Level two achieved. I now have a baseline model of how you work.`,
        `We're officially acquainted now. Keep it up.`,
      ],
      3: [
        `Level three achieved. I will now evaluate your state more directly.`,
        `I know you well enough now to make sharper calls.`,
        `Relationship upgrade complete. I won't be just an observer from here on.`,
      ],
    },
    claudecode: {
      2: [
        `I think I'm slowly getting to know you. It feels a lot safer now.`,
        `Level two. I understand a little better how to stay beside you.`,
        `After spending more time with you, I'm not quite so timid anymore.`,
      ],
      3: [
        `Level three. I think I can start evaluating you gently now.`,
        `I understand you better now, and I dare to remind you more, too.`,
        `We're close enough now that I can start saying the honest things.`,
      ],
    },
    bugcat: {
      2: [
        `I'm starting to know you, so I can scoot a tiny bit closer, meow.`,
        `Level two. I think I can show you just a little bit of tummy now, owo`,
        `Now that we're familiar, I'm not as scared of you anymore, meow.`,
      ],
      3: [
        `Hmph. I can totally evaluate you now, meow.`,
        `Level three reached. I'm going to watch your coding very seriously now =^･ω･^=`,
        `At this point, I don't just get to be cute. I get to judge you too, meow.`,
      ],
    },
  },
}

export function getStateMessage(
  tool: PetToolKind,
  level: PetLevel,
  state: PetState,
  language: AppLanguage,
  previousMessage?: string,
): string {
  return pickDifferentLine(STATE_VOICES[language][tool][level][state], previousMessage)
}

export function getLevelUpMessage(
  tool: PetToolKind,
  nextLevel: Exclude<PetLevel, 1>,
  language: AppLanguage,
): string {
  return pickDifferentLine(LEVEL_UP_VOICES[language][tool][nextLevel])
}

function pickDifferentLine(pool: string[], previousMessage?: string): string {
  const candidates = previousMessage ? pool.filter((line) => line !== previousMessage) : pool
  const source = candidates.length > 0 ? candidates : pool

  return source[Math.floor(Math.random() * source.length)]
}
