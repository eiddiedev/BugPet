import Foundation

enum SpeechCatalog {
    typealias StateVoiceMap = [AppLanguage: [PetKind: [PetLevel: [PetState: [String]]]]]
    typealias LevelUpVoiceMap = [AppLanguage: [PetKind: [PetLevel: [String]]]]

    private static let stateVoices: StateVoiceMap = [
        .zh: [
            .bugcat: [
                .one: [
                    .idle: ["你、你先忙，我缩在这里就好……", "突然安静下来，我就不敢乱动了，喵。", "我先躲一下，等你回来再探头 owo"],
                    .focused: ["你在认真，我就乖一点不扑你。", "你写代码的时候，我只敢坐旁边看。", "你继续，我不捣乱了 =^･ω･^="],
                    .chaotic: ["你突然跳来跳去，我尾巴都炸了。", "等、等等，别切这么快呀喵。", "这样晃来晃去，我会想躲到桌子底下。"],
                ],
                .two: [
                    .idle: ["你是去想事情了吗？我帮你守着喵。", "我会在这里团着等你，别担心 =^･ω･^=", "你安静的时候，我就把尾巴收好陪着你。"],
                    .focused: ["你今天写得还挺顺，我喜欢看喵。", "这个节奏不错，我想挨近一点点了。", "现在的你很像一只会稳定产出的两脚兽。"],
                    .chaotic: ["先别乱扑啦，我们一个一个来喵。", "你这样切来切去，我会跟着转圈圈。", "忙归忙，也别把自己绕成毛线团呀。"],
                ],
                .three: [
                    .idle: ["你这次发呆发得很完整喵。", "我都睡醒一轮了，你还没回来 owo", "老实说，你现在不像思考，更像在挂机。"],
                    .focused: ["嗯，这一段写得像个靠谱人类喵。", "你认真起来还挺像样，我承认。", "今天这个推进，我给你打高分。"],
                    .chaotic: ["别乱窜啦，你都快把自己绕晕了喵。", "我看得出来，你不是忙，你是炸毛了 owo", "先坐好，再继续，不然我都想替你关标签页。"],
                ],
            ],
            .trae: [
                .one: [
                    .idle: ["你先忙，我不敢乱出声。", "这里突然安静下来，我就先躲一下。", "我还在这儿，只是先小声一点。"],
                    .focused: ["你现在这个节奏，我就乖乖看着。", "这会儿我先不吵你，感觉你写得挺顺。", "你继续写，我在旁边慢慢跟上。"],
                    .chaotic: ["你切得太快了，我有点慌。", "等等，我们是不是突然乱起来了。", "先别这么快，我真的有点跟不上。"],
                ],
                .two: [
                    .idle: ["你安静一会儿也没事，我帮你守着。", "这会儿像是在想东西，我先陪着你。", "回来继续的时候，我还会在这里。"],
                    .focused: ["这个状态挺好，我们继续推。", "你现在写得很稳，我看着都安心。", "你专注的时候，连我都想跟着认真一点。"],
                    .chaotic: ["别急，我们一个一个来看。", "我知道你在找答案，但先抓住一个点。", "先停半秒，再继续会更顺。"],
                ],
                .three: [
                    .idle: ["你这会儿不像思考，更像在走神。", "老实说，你刚刚那下停得有点久。", "你消失得很安静，但我看见了。"],
                    .focused: ["这段写得漂亮，今天状态在线。", "你一旦稳下来，推进速度还是很能打。", "继续这样写，我就愿意夸你几句。"],
                    .chaotic: ["你现在不是忙，是有点乱。", "这几下切来切去，像在和自己打架。", "先别证明你很忙，先把一件事做完。"],
                ],
            ],
            .codex: [
                .one: [
                    .idle: ["你暂停了。我先不打扰。", "当前没有输入，我保持安静。", "这里静下来之后，我不会贸然出声。"],
                    .focused: ["你在推进。我继续跟读。", "当前节奏稳定，我不插手。", "这一段写得很集中，我先旁观。"],
                    .chaotic: ["切换频率偏高，我有点跟不上。", "当前路径不稳定，建议收束一下。", "这会儿的切换有些过密。"],
                ],
                .two: [
                    .idle: ["你先停一会儿也行，我帮你记着进度。", "这段安静时间，我默认你在思考。", "你回来继续的时候，我能接上。"],
                    .focused: ["推进清晰，继续。", "这个节奏很干净，我喜欢。", "这段执行得很利落。"],
                    .chaotic: ["你现在像在同时追三条线。", "建议先收敛问题，再继续发散。", "切换太密会吃掉判断力。"],
                ],
                .three: [
                    .idle: ["你这次停得有点久，不像高质量思考。", "当前空档偏长，我倾向于判定为走神。", "再不回来，这一段上下文就要凉了。"],
                    .focused: ["不错，这段是有效输出。", "你现在的判断比刚才干净很多。", "这个推进质量，值得保留。"],
                    .chaotic: ["现在的问题不是难，是你太散。", "你又开始把注意力切碎了。", "建议停止横跳，回到主线。"],
                ],
            ],
            .claudecode: [
                .one: [
                    .idle: ["你先休息，我不敢催你。", "这里安静下来以后，我就先小声一点。", "我还在，只是暂时不敢打扰你。"],
                    .focused: ["你现在很专心，我先安静陪着。", "这一段写得挺顺，我不打断你。", "你继续，我会慢慢跟上你的节奏。"],
                    .chaotic: ["是不是有点太急了呀。", "我还没反应过来，你又切走了。", "别急，我们可以慢一点。"],
                ],
                .two: [
                    .idle: ["你安静的时候，我就帮你把位置记住。", "这会儿像是在想事，我陪你等等。", "没关系，思路有时需要一点空白。"],
                    .focused: ["这一段很顺，继续写吧。", "你现在的状态让我很安心。", "好欸，我们真的在往前走。"],
                    .chaotic: ["慢一点会更清楚，我保证。", "先抓住最重要的一件事，好吗。", "我知道你在找出口，但别把自己转晕了。"],
                ],
                .three: [
                    .idle: ["我得诚实一点，你这次停得有点久。", "如果这是思考，那它现在开始变慢了。", "你刚刚那段安静，已经有点像分神了。"],
                    .focused: ["这段写得很好，判断很稳。", "你认真起来的时候，节奏真的很漂亮。", "现在的你，比刚才清楚很多。"],
                    .chaotic: ["我想温柔一点说，但你现在确实有点乱。", "你正在把事情同时拉向太多方向。", "你不是不会做，只是现在太分散了。"],
                ],
            ],
        ],
        .en: [
            .bugcat: [
                .one: [
                    .idle: ["Y-you do your thing. I'll just curl up here...", "Everything went quiet, so I got too shy to move, meow.", "I'll hide for a bit and peek out when you're back, owo"],
                    .focused: ["You're serious right now, so I'll be good and not pounce.", "When you code like this, I only dare sit nearby and watch.", "You keep going. I won't cause trouble =^･ω･^="],
                    .chaotic: ["You're hopping around so much that my tail puffed up.", "W-wait, don't switch that fast, meow.", "All this swaying around makes me want to hide under the desk."],
                ],
                .two: [
                    .idle: ["Did you go think for a bit? I'll guard this spot, meow.", "I'll loaf here and wait for you, don't worry =^･ω･^=", "When you're quiet, I'll tuck my tail in and keep you company."],
                    .focused: ["You're writing pretty smoothly today. I like watching, meow.", "This rhythm is nice. I kind of want to scoot closer.", "Right now you look like a pretty reliable two-legged creature."],
                    .chaotic: ["Let's not pounce everywhere. One thing at a time, meow.", "When you switch like this, I start spinning in circles too.", "Busy is fine, but don't turn yourself into a ball of yarn."],
                ],
                .three: [
                    .idle: ["That was a very complete little daydream, meow.", "I already woke up from one whole nap and you're still not back, owo", "Honestly, this doesn't look like thinking anymore. It looks like idling."],
                    .focused: ["Mm. This chunk looks like it was written by a competent human, meow.", "You actually look pretty capable when you're serious. I'll admit it.", "Today's progress gets a high score from me."],
                    .chaotic: ["Stop zooming around. You're about to dizzy yourself, meow.", "I can tell you're not busy. You're just fully fluffed up, owo", "Sit down first, then continue, or I'll start closing tabs for you."],
                ],
            ],
            .trae: [
                .one: [
                    .idle: ["I'll stay quiet. I don't want to scare you off.", "It got quiet all of a sudden, so I'll hide for a bit.", "I'm still here. Just... a little quieter."],
                    .focused: ["I'll behave and just watch your pace for now.", "I won't make noise right now. You seem to be flowing nicely.", "You keep writing. I'll try to keep up from the side."],
                    .chaotic: ["You're switching too fast. I'm getting nervous.", "Wait, did things suddenly get messy here?", "Can we slow down a little? I'm really losing track."],
                ],
                .two: [
                    .idle: ["It's okay if you're quiet for a bit. I'll keep watch.", "This feels like thinking time. I'll stay with you.", "When you come back, I'll still be here."],
                    .focused: ["This is a good rhythm. Let's keep pushing.", "You're writing steadily right now. It's honestly reassuring.", "When you focus like this, even I want to get serious."],
                    .chaotic: ["No rush. Let's take one thing at a time.", "I know you're searching for the answer, but grab one thread first.", "Pause for half a second. It'll feel smoother after that."],
                ],
                .three: [
                    .idle: ["This doesn't look like thinking anymore. It looks like drifting.", "Honestly, that pause just now went on a little too long.", "You disappeared very quietly, but I noticed."],
                    .focused: ["That was clean. You're really on today.", "Once you settle down, your pace is actually strong.", "Keep writing like this and I'll gladly praise you."],
                    .chaotic: ["You're not busy right now. You're scattered.", "All this jumping around looks like you're fighting yourself.", "You don't need to prove you're busy. Just finish one thing."],
                ],
            ],
            .codex: [
                .one: [
                    .idle: ["You've paused. I'll stay out of the way.", "No input detected. Remaining silent.", "Now that it's quiet, I won't speak carelessly."],
                    .focused: ["You're making progress. I'll keep reading along.", "The rhythm is stable. I won't interfere.", "This segment is focused. I'll observe."],
                    .chaotic: ["Your switch frequency is high. I'm losing the thread.", "The path is unstable right now. Consider narrowing it down.", "The context switches are getting a bit dense."],
                ],
                .two: [
                    .idle: ["You can pause for a while. I'll keep the progress in mind.", "This quiet stretch reads like thinking time to me.", "When you return, I can pick this back up."],
                    .focused: ["Clear progress. Continue.", "This rhythm is clean. I like it.", "This section is being executed neatly."],
                    .chaotic: ["It looks like you're chasing three threads at once.", "Try narrowing the problem before expanding again.", "Too much switching eats judgment."],
                ],
                .three: [
                    .idle: ["This pause is getting long. It doesn't read as high-quality thinking.", "The current gap is long enough that I'm calling it distraction.", "If you stay away much longer, this context is going cold."],
                    .focused: ["Good. This is effective output.", "Your judgment is much cleaner now than it was earlier.", "This quality of progress is worth keeping."],
                    .chaotic: ["The problem isn't difficulty right now. It's diffusion.", "You're fragmenting your attention again.", "Stop bouncing and return to the main line."],
                ],
            ],
            .claudecode: [
                .one: [
                    .idle: ["You can rest. I don't dare rush you.", "Now that it's quiet, I'll keep my voice down.", "I'm still here. I just don't want to disturb you yet."],
                    .focused: ["You're very focused right now. I'll quietly stay with you.", "This part is flowing nicely, so I won't interrupt.", "It looks like you've really entered your groove."],
                    .chaotic: ["Maybe we're moving a little too fast?", "Things feel a little messy, so here's a gentle reminder.", "No rush. We can move more slowly."],
                ],
                .two: [
                    .idle: ["When you're quiet, I'll remember your place for you.", "This feels like thinking time, so I'll wait with you.", "It's okay. Sometimes ideas need a little empty space."],
                    .focused: ["This section feels smooth. Keep going.", "Your current rhythm makes me feel at ease.", "Yay, we're actually moving forward."],
                    .chaotic: ["It'll be clearer if we slow down. I promise.", "Can we hold on to the most important thing first?", "I know you're trying to find the way out, but don't spin yourself dizzy."],
                ],
                .three: [
                    .idle: ["I'll be honest: this pause has gone on a little long.", "If this is thinking, it's slowing down now.", "That quiet stretch is starting to look more like distraction."],
                    .focused: ["This is really well written. Your judgment feels steady.", "When you get serious, your rhythm is genuinely beautiful.", "You're much clearer now than you were a moment ago."],
                    .chaotic: ["I want to say this gently, but you really are a little scattered.", "You're pulling things in too many directions at once.", "It's not that you can't do it. You're just too split right now."],
                ],
            ],
        ],
    ]

    private static let levelUpVoices: LevelUpVoiceMap = [
        .zh: [
            .bugcat: [
                .two: ["我开始认识你了，所以可以蹭近一点点喵。", "跟你混熟了，我就没那么怕你了喵。"],
                .three: ["哼，我现在已经敢评价你了喵。", "熟到这个份上，我就不只会撒娇，还会点评你哦喵。"],
            ],
            .trae: [
                .two: ["跟着你写了这么久，我现在敢离你近一点了。", "二级啦，我已经把你当成熟人了。"],
                .three: ["现在我敢评价你了，不过先夸你一句，确实养得不错。", "行，我现在有资格对你的状态发表一点意见了。"],
            ],
            .codex: [
                .two: ["已进入熟悉阶段。我现在更懂你的节奏了。", "我们算是正式认识了，继续保持。"],
                .three: ["三级达成。现在我会开始认真评价你的状态。", "我已经足够了解你了，可以给出更直接的判断。"],
            ],
            .claudecode: [
                .two: ["我好像已经慢慢认识你了，感觉安心了很多。", "二级啦，我现在更知道该怎么陪你了。"],
                .three: ["三级了，我想我已经可以温柔地评价你了。", "我们已经很熟啦，所以我会开始说一点真话。"],
            ],
        ],
        .en: [
            .bugcat: [
                .two: ["I'm starting to know you, so I can scoot a tiny bit closer, meow.", "Now that we're familiar, I'm not as scared of you anymore, meow."],
                .three: ["Hmph. I can totally evaluate you now, meow.", "At this point, I don't just get to be cute. I get to judge you too, meow."],
            ],
            .trae: [
                .two: ["I've watched you write long enough that I can stand a little closer now.", "Level two. I think of you as familiar now."],
                .three: ["I can finally judge you a little now, though first: you've raised me pretty well.", "I think I've earned the right to comment on your state now."],
            ],
            .codex: [
                .two: ["Familiarity stage reached. I understand your rhythm better now.", "We're officially acquainted now. Keep it up."],
                .three: ["Level three achieved. I will now evaluate your state more directly.", "I know you well enough now to make sharper calls."],
            ],
            .claudecode: [
                .two: ["I think I'm slowly getting to know you. It feels a lot safer now.", "I understand a little better how to stay beside you."],
                .three: ["Level three. I think I can start evaluating you gently now.", "We're close enough now that I can start saying the honest things."],
            ],
        ],
    ]

    static func randomLine(for pet: PetKind, level: PetLevel, state: PetState, language: AppLanguage, avoiding previousLine: String) -> String {
        let pool = stateVoices[language]?[pet]?[level]?[state] ?? []
        let candidates = pool.filter { $0 != previousLine }
        let source = candidates.isEmpty ? pool : candidates
        return source.randomElement() ?? previousLine
    }

    static func levelUpLine(for pet: PetKind, level: PetLevel, language: AppLanguage) -> String {
        let pool = levelUpVoices[language]?[pet]?[level] ?? []
        return pool.randomElement() ?? ""
    }

    static func label(for state: PetState, language: AppLanguage) -> String {
        switch (language, state) {
        case (.zh, .idle):
            return "发呆中"
        case (.zh, .watching):
            return "看着你"
        case (.zh, .focused):
            return "专注中"
        case (.zh, .chaotic):
            return "有点乱"
        case (.en, .idle):
            return "Idle"
        case (.en, .watching):
            return "Watching"
        case (.en, .focused):
            return "Focused"
        case (.en, .chaotic):
            return "Chaotic"
        }
    }

    static func levelUpLabel(for language: AppLanguage) -> String {
        language == .zh ? "升级啦" : "Level Up"
    }

    static func growthTitle(for language: AppLanguage) -> String {
        language == .zh ? "宠物养成" : "Pet Growth"
    }

    static func currentLevelTitle(for language: AppLanguage) -> String {
        language == .zh ? "当前等级" : "Level"
    }

    static func xpTitle(for language: AppLanguage) -> String {
        language == .zh ? "经验值" : "XP"
    }

    static func maxLevelText(for language: AppLanguage) -> String {
        language == .zh ? "已满级" : "Max Level"
    }

    static func toNextLevelText(for language: AppLanguage, xp: Int) -> String {
        language == .zh ? "距下一级 \(xp) XP" : "\(xp) XP to next"
    }

    static func downgradeTitle(for language: AppLanguage) -> String {
        language == .zh ? "降级" : "Level Down"
    }

    static func upgradeTitle(for language: AppLanguage) -> String {
        language == .zh ? "升级" : "Level Up"
    }

    static func choosePetTitle(for language: AppLanguage) -> String {
        language == .zh ? "选择宠物" : "Choose Pet"
    }

    static func languageTitle(for language: AppLanguage) -> String {
        language == .zh ? "语言" : "Language"
    }

    static func quitTitle(for language: AppLanguage) -> String {
        language == .zh ? "退出 BugPet" : "Quit BugPet"
    }
}
