# Evolution Constraint Control Notes

This file captures a future workflow idea for `my-agent-harness` without turning it into a real harness feature yet.

## Why Keep This

The repo is still a base setup for Claude Code and Codex. For now, the right level is one note that records the idea clearly so it can be implemented later if it still feels useful.

## Core Idea

The source idea treats software work as a controlled conversion from messy user intent into stable implementation constraints.

The important chain is:

`requirement -> feature -> module -> function`

The hard part is not only writing code. It is converting vague, incomplete, or even misleading user input into a constraint set that can drive code and tests.

## Proposed Future Workflow

If this is implemented later, the workflow should likely look like this:

1. treat the user's request as a hypothesis, not as unquestionable truth
2. ask back on ambiguity and challenge claims that may be incomplete, false, hidden, or inconsistent
3. deliberately diverge and explore multiple possible solutions
4. decompose the candidate solutions into concrete requirement points
5. critique and reject conflicts, weak assumptions, and non-objective requirements
6. complete missing links so the requirement chain can support an end-to-end path
7. probe risky options with lightweight research or validation code and discard infeasible paths
8. run adversarial review on boundary cases and failure modes
9. approve the converged constraint set before implementation
10. implement, test, verify, and feed failures back into the same loop

## Sub-Agent Fit

This idea maps naturally to sub-agents, but only as a future implementation detail.

Possible specialist roles:

- intake analyst
- solution diverger
- constraint critic
- probe researcher
- red team
- blue team
- approval judge

The important part is not the exact role list. The important part is separating expansion, critique, probing, and approval so the harness does not collapse too early into a single fragile solution.

## White-Box Context

The strongest idea in the source notes is observability.

The workflow should not rely only on final outputs or scattered logs. It should preserve a visible task context that records:

- user claims
- assumptions
- derived requirements
- conflicts
- feasibility probes
- adversarial findings
- decisions and reasons
- evidence links

That would make the process more white-box than black-box. If the result is wrong but the process is visible, the harness can inspect where the bad assumption or bad decision entered the flow instead of blindly rewriting code.

## Practical Lesson

The main lesson is to revisit upstream assumptions when downstream fixes keep failing.

Without that discipline, an agent can get trapped in local rewrites of later-stage decisions while the real problem lives earlier in the reasoning chain.

## Original Chinese Source Notes

> "给我的理念一模一样。但是一些细节不一样，他这个做法太累了。首先就是测试驱动开发，实现端到端的闭环，那么你就要有测试和功能对应，足够完备。我们必须理解一个逻辑，函数支撑模块，模块支持功能，功能支撑需求。也就是需求到函数需要被转换，亮点就是如何实现需求的转换。这里我的思考就是先先发散在收敛，发散是一个探索可能性的过程，将增加覆盖面，但很多是无效路径，是幻觉，需要收敛。我的做法是用户描述速场景/需求，A大模型做预处理，1.需求即假设，反问模糊的迷糊不清的点。2.需求非真理，质疑不符合客观事实的东西。我们的假设是用户可能说不清，说不全，隐瞒，撒谎。B然后就是大模型想畅享，这是一个发散的过程，畅享的各种方案将补全用户的盲区。C然后将畅享的内容拆解成具体的需求点。D挑刺，引入新agent客观的质疑和反对，剔除不合理的为需求，做正交过滤，用方法论判定冲突需求。从这里开始就是收敛了。E补全，端到端的逻辑是一个完整的链条，收敛的需求应该是能支撑这个链条，所以必须做缺少补全，保证需求满足依赖关系。F探测，将所有收敛后的方案做探测，这里会生成验证代码做调研，行不通的方案丢掉。需求再次收敛。然后就是红蓝对抗，红发发出各种边界问题进行攻击，蓝方识别是否能解决，或者给出缓解方案，需求继续收敛。然后开始评审。评审通过进行编码，测试。遇到问题就作为新的需求进入上面的逻辑,形成闭环。将需求写出代码就是一个约束求解的过程，将多种可行方案变成策略。其中一个路径就是给出满足你需求的一个解。不满足，他就会重新走上门的逻辑，再次约束求解。这套方法论，让垃圾模型都变得非常聪明和专注。将原始需求拆解成各种约束，对应就是各种函数实现。迭代过程中，测试用例是比较明确的。为了将过程产物固化，需求，功能，模块，函数，当然还有一些其他信息，组合成一个描述性语言。换个大模型看到了只管框框写代码，组装起来再说。这个描述性语言，贯穿整个迭代生命周期，大模型给它取了一个我非常喜欢的名字，演进约束语言。这个闭环流程，丢给大模型，让他再给你生成提示词，你的开发工作绝对要轻松很多。"

> "让他学会定性，定量分析。定性，举个例子，出了bug，共性问题还是特例，共性就是就可能逻辑没问题，方案错了，他会复盘方案，如果是特例，就是具体问题具体分析，进入定量分析维度。看准病才能抓好药。还要很多技巧，这两天太忙，都忘得差不多了。"

> "做熔断机制，有些不合理的设计坚决不采纳。其中一个是场景大家忽略的，白盒设计，所有的实现都是可观测的。端到端最重要的是什么？是内部流程的数据采集，一般人怎么做呢？也就是函数打打日志。真正的大模型设计模式（我编的），是管道，是总线设计，搞一个context，贯穿整个生命周期，作为信息的采集和传播投递总线，要无锁数据结构。任何一点都可以采样，当生命周期结束，就能统计虽有埋点信息。按照时间线或者任务线，形成矩阵日志，那个线程，在哪里阻断，在哪里通过，一目了然。大模型分析日志一下就定位到了。"

> "单独用应该效果不那么好，这个点是在逻辑补全那里发现的，做了ABCDE，可能写好了E，变成了约束，稳定了，但是因为某些原因必须要改D，然后他就反复改，都改不对，就想去改E来解决，推翻之前的代码，反正就是你改过去，我改过来。没有重新审视ABC是不是要重新搞。端到端最大的问题就是黑盒，sx玩意能改几个小时，各种推到重来，就是没有改到点子上。"

> ":是的。可观测的意义，有错误的结果，却没有错误的过程，那么只能推测，先去假设，验证假设。
有错误的过程，就是证据，就能直接定罪。这是本质上的差别。"
