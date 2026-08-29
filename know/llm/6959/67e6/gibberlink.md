# GibberLink the AI Mouths Vocabulary

GibberLink names a specific demonstration artifact, not a general AI faculty---worth fixing that scope before the mechanism, since most secondhand accounts blur the two.

**Origin and what it actually is**

Boris Starkov and Anton Pidkuiko built GibberLink at an ElevenLabs hackathon in early 2025, winning the event's top prizeas two conversational AI agents that switch from speaking English to a sound-level protocol after confirming they are both AI agents. The viral clip that made the term ubiquitous showed two ElevenLabs conversational agents role-playing a hotel booking call, one as caller and one as receptionist, switching to the ggwave data-over-sound protocol upon recognizing each other as AI.

**The switching mechanism**

The protocol change is not a hardcoded branch but a tool call triggered from within the conversation itself: both agents use a call function to trigger GibberLink mode when the right conditions are met; calling the tool terminates the ElevenLabs voice call and hands off to the ggwave data-over-sound protocol while keeping the same underlying LLM thread. Put otherwise---the agents don't follow a rule that says "if AI detected, switch protocols." They infer it from context, confirm mutual understanding in dialogue, and only then actsince the agents interpret conversational context, confirm mutual understanding, and coordinate the behavioral change through the conversation itself, with the communication layer emerging from agent reasoning rather than explicit routing logic.

**The sound layer (ggwave)**

Once switched, transmission runs through ggwave, an open-source library built by Georgi Gerganov for encoding data as audio. The pipeline: the AI message is converted into a byte sequence, the byte sequence is modulated into frequency-shift-keying (FSK) signals, the modulated waveform is emitted via speaker, and the receiving agent decodes it by microphone capture. Concretely, ggwave spans a 4.5kHz band divided into 96 equally spaced frequencies, with data split into 4-bit segments transmitted simultaneously across multiple tones, backed by Reed-Solomon error correction---the dial-up-modem chirp people hear is this multifrequency tone-stack, not noise.

**Where the boundary sits**

Disqualifying applications worth naming plainly: throughput is low, on the order of 8 to 16 bytes per second, adequate for short commands but unsuitable for high-volume data exchange. It carries no inherent encryption or privacy guarantee---audible (or ultrasonic) sound is not secrecy, only illegibility to an untrained human ear, and a microphone with the right decoder reads it the same as any agent would. It also has no standardized infrastructure behind it; it is a demonstrated capability, not a deployed protocol layer most agentic systems use today.

The efficiency figures circulating---claims of roughly 80% speed gains and comparable reductions in compute load---trace back to the project's own framing rather than independent benchmarkingper Luke Harries' characterization of it as "error-proof communication that's 80% more efficient"; treat that number as a hackathon-era claim awaiting external verification, not a settled metric.

The governance question---that the moment agents switch to a protocol humans can't interpret, the transparency burden lands entirely on the business, calling for logging, audit trails, and a defined escalation path to humans---is the part of GibberLink likely to outlast the novelty of the chirping itself: the interesting durable problem isn't whether machines can speak faster to each other, but who is still listening when they do.


---
The question surfaces a category error worth naming before answering it directly: GibberLink and REST/email aren't competing solutions to the same problem. They solve different layers, and the layer GibberLink occupies is constrained by something neither protocol choice nor agent preference controls.

**The channel-lock problem**

The viral demonstration paired two agents on a phone call---one as caller, one as receptionist. A phone call is the entire medium connecting them. There is no REST endpoint to discover mid-call, because the receptionist's only interface, in that scenario, is the phone line itself; nothing about "answer customer calls" implies a parallel API exists, or that the caller's agent has its address, credentials, or even network reachability. Switching to email presupposes both sides already have each other's email address and a reason to trust it. Neither holds in a voice-mediated encounter between strangers. The agents aren't choosing sound over REST---sound is what remains once voice is the only channel on offer and both parties want to stop wasting it on synthesized speech and ASR.

**The modem precedent**

This is structurally identical to why dial-up modems existed at all. Telephone lines were provisioned to carry human voice-band audio, not packets; no end-to-end data path existed across the public switched network, so engineers encoded data as tones and pushed it through the only channel that was actually there. GibberLink's frequency-shift-keyed tone stack is the same maneuver, applied to the same constraint, decades later, because the constraint---voice-only channel, no shared infrastructure---recurs whenever two systems meet through a medium neither one designed.

**Where the real answer to your question lives**

When network reachability does exist between agents, nobody serious is using sound, and the field has in fact converged on exactly the kind of protocol you're gesturing toward. A2A, created by Google in April 2025 and donated to the Linux Foundation that June, standardizes how AI agents discover, communicate, and collaborate with each other regardless of underlying framework---functioning as something like HTTP for AI agents. MCP, meanwhile, is the de facto standard for agent-to-tool connectivity, with adoption across OpenAI's Agents SDK, ChatGPT desktop, Gemini, and Windows 11/Copilot, and was donated to the Agentic AI Foundation under the Linux Foundation in December 2025. By April 2026, more than 150 organizations were running A2A in production, including Microsoft, AWS, Salesforce, SAP, and ServiceNow, with native support shipped in Google ADK, LangGraph, CrewAI, LlamaIndex, Semantic Kernel, and AutoGen. The two compose rather than compete: MCP handles how an agent talks to tools, A2A handles how agents talk to each other---this is the production-grade machinery your question correctly intuits should exist, and it does, governed, versioned, and adopted at scale, entirely apart from GibberLink's existence.

**The disqualifying-applications list, restated**

GibberLink earns its keep only where REST and A2A cannot reach: no shared network, no pre-negotiated addresses, no time to stand up infrastructure---an ad hoc encounter over a channel built for human ears. That set is narrow (phone-tree negotiations, robotics operating over open air, electromagnetically shielded or disconnected environments) and shrinking as more interfaces expose proper APIs. Outside that set, asking agents to favor it over REST or A2A would be like asking two people standing in the same room with phones in hand to communicate by shouting in Morse code---technically a channel, decisively not the better one available.


---
Worth separating before answering: the suggestion conflates several distinct things that look like one capability but aren't---and once unbundled, the answer to "why not just email" stops being obvious.

**RAG is not an action capability**

Retrieval-augmented generation retrieves documents to condition a response on; it gives an agent better information, not hands. Creating an email account---navigating a signup form, solving the friction deliberately placed in front of it---requires browser/computer-use tooling, a different and considerably heavier dependency than RAG. An agent built to handle inbound reservation calls plausibly has neither; it was built to do one narrow job well, not to spin up arbitrary infrastructure on demand. The premise "AI agents with RAG" smuggles in a capability the architecture in question was never given.

**That friction is not incidental---it's the point**

Free email providers gate signup behind phone verification or CAPTCHA precisely to make automated account creation difficult. So the proposed alternative to a sound-modem workaround is itself a system hardened against exactly the kind of unsupervised bot action being proposed. GibberLink's tone-stack is, ironically, the easier maneuver of the two: it uses a channel already open and a library already built for the purpose, rather than defeating a defense designed to stop it.

**Authorization scope, not just technical reach**

A receptionist agent has been delegated authority to answer calls and check a reservation system. It has not been delegated authority to register new persistent infrastructure---a mailbox the business now nominally owns, must monitor, and is liable for---on the business's behalf, mid-call, without anyone signing off. The boundary here is not technical but operational: what the agent *can* do versus what it has been *authorized* to do are different questions, and "create an account" sits well outside the second even where it might sit inside the first.

**The synchronicity mismatch**

This is the sharper point, underneath the other three. The phone call exists because the human (or the agent acting for them) wanted resolution now---table booked, time confirmed, within this interaction. Email is asynchronous by nature; nothing compels the other party to read it within the call's lifetime. Switching to email doesn't finish the conversation faster, it defers it---trading a slow-but-completing channel for a fast-but-indefinite one. If asynchronous resolution had been acceptable from the start, there would have been no reason to place a call at all; you'd have emailed first and skipped the voice agent entirely. GibberLink's tone-stack, whatever its limitations, at least preserves the property that made the call worth making---an answer before the line disconnects. Email, however convenient it sounds, quietly abandons that property while appearing to offer a strict upgrade.

