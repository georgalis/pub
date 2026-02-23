<div class="w-full h-full relative"><div tabindex="0" class="w-full h-full relative [&amp;_:not(input)::selection]:bg-secondary-000/10"><div tabindex="0" id="markdown-artifact" class="font-claude-response mx-auto w-full max-w-3xl leading-[1.65rem] px-6 pt-4 md:pt-6 md:px-11"><div><div class="grid-cols-1 grid gap-2.5 [&amp;_&gt;_*]:min-w-0 !gap-3.5"><h1 class="text-2xl font-bold mt-1 text-text-100">Ultra-High-Speed Camera System for Filming Light Propagation: A Technical Implementation Guide</h1>
<h2 class="text-xl font-bold text-text-100 mt-1 -mb-0.5">Overview: Building a 2 billion fps imaging system</h2>
<p class="whitespace-normal break-words">This document details a novel experimental setup for capturing light propagation at <strong>~2 billion frames per second</strong> using time-domain multiplexing, photomultiplier tube detection, and precision nanosecond-scale pulse generation. The system reconstructs a 1280×720 pixel video from 921,600 repeated laser pulses, each capturing a single spatial position at a different temporal offset.</p>
<p class="whitespace-normal break-words"><strong>Key Innovation</strong>: Rather than continuous video capture, this system exploits the deterministic nature of light propagation to build a composite image from thousands of identical events, with each laser pulse capturing one pixel location at sub-nanosecond temporal resolution.</p>
<p class="whitespace-normal break-words"><strong>Source Material</strong>: This technical artifact is based on the experimental work documented in two YouTube videos by BetaPhoenix:</p>
<ul class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-disc space-y-2.5 pl-7">
<li class="whitespace-normal break-words">"The 555 timer finally failed me... How I generated 50ns pulses for my ludicrously fast camera flash" (<a class="underline" href="https://www.youtube.com/watch?v=WLJuC0q84IQ">https://www.youtube.com/watch?v=WLJuC0q84IQ</a>)</li>
<li class="whitespace-normal break-words">"Setting up a camera to film the speed of light" (<a class="underline" href="https://www.youtube.com/watch?v=lWIXnL8RAcc">https://www.youtube.com/watch?v=lWIXnL8RAcc</a>)</li>
</ul>
<h2 class="text-xl font-bold text-text-100 mt-1 -mb-0.5">The fundamental challenge: Why conventional electronics fail at 50ns timescales</h2>
<p class="whitespace-normal break-words">The 555 timer, ubiquitous in hobby electronics for pulse generation, becomes fundamentally unusable when attempting to generate 50-nanosecond laser pulses. This failure isn't a limitation of implementation but of physics.</p>
<p class="whitespace-normal break-words"><strong>The 555 timer's insurmountable bottleneck</strong> lies in its internal switching characteristics. Standard NE555 circuits exhibit rise and fall times of approximately <strong>100 nanoseconds</strong> - twice the desired 50ns pulse width. Attempting to generate a 50ns pulse results in a waveform that resembles a single sawtooth ramp rather than a clean rectangular pulse. <span class="inline-flex" data-state="closed"><a href="https://electronics.stackexchange.com/questions/610915/minimum-time-pulse-for-the-ne555" target="_blank" class="group/tag relative h-[18px] rounded-full inline-flex items-center overflow-hidden -translate-y-px cursor-pointer"><span class="relative transition-colors h-full max-w-[180px] overflow-hidden px-1.5 inline-flex items-center font-small rounded-full border-0.5 border-border-300 bg-bg-200 group-hover/tag:bg-accent-secondary-900 group-hover/tag:border-accent-secondary-100/60"><span class="text-nowrap text-text-300 break-all truncate font-normal group-hover/tag:text-text-200">Stack Exchange</span></span><span class="transition-all opacity-[0%] h-[17px] absolute right-[0.5px] inline rounded-r-full flex items-center px-1.5 bg-gradient-to-r from-accent-secondary-900/0 via-accent-secondary-900/100 via-30% to-accent-secondary-900/100 group-hover/tag:opacity-[100%]"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 256 256" class="transition-all group-hover/tag:ease-out duration-[500ms] ease-in text-accent-secondary-100 group-hover/tag:scale-[100%] scale-[80%] group-hover/tag:opacity-[100%] opacity-[0%] -mr-[2px]"><path d="M200,64V168a8,8,0,0,1-16,0V83.31L69.66,197.66a8,8,0,0,1-11.32-11.32L172.69,72H88a8,8,0,0,1,0-16H192A8,8,0,0,1,200,64Z"></path></svg></span></a></span> The output never reaches a stable high state before the circuit attempts to transition back low. Additional limitations compound this problem: internal comparator propagation delays of ~16 microseconds, <span class="inline-flex" data-state="closed"><a href="https://e2e.ti.com/support/clock-timing-group/clock-and-timing/f/clock-timing-forum/906800/faq-how-do-i-design-a-pulse-width-modulator-pwm-circuit-using-lmc555-tlc555-lm555-na555-ne555-sa555-or-se555" target="_blank" class="group/tag relative h-[18px] rounded-full inline-flex items-center overflow-hidden -translate-y-px cursor-pointer"><span class="relative transition-colors h-full max-w-[180px] overflow-hidden px-1.5 inline-flex items-center font-small rounded-full border-0.5 border-border-300 bg-bg-200 group-hover/tag:bg-accent-secondary-900 group-hover/tag:border-accent-secondary-100/60"><span class="text-nowrap text-text-300 break-all truncate font-normal group-hover/tag:text-text-200">Texas Instruments E2E</span></span><span class="transition-all opacity-[0%] h-[17px] absolute right-[0.5px] inline rounded-r-full flex items-center px-1.5 bg-gradient-to-r from-accent-secondary-900/0 via-accent-secondary-900/100 via-30% to-accent-secondary-900/100 group-hover/tag:opacity-[100%]"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 256 256" class="transition-all group-hover/tag:ease-out duration-[500ms] ease-in text-accent-secondary-100 group-hover/tag:scale-[100%] scale-[80%] group-hover/tag:opacity-[100%] opacity-[0%] -mr-[2px]"><path d="M200,64V168a8,8,0,0,1-16,0V83.31L69.66,197.66a8,8,0,0,1-11.32-11.32L172.69,72H88a8,8,0,0,1,0-16H192A8,8,0,0,1,200,64Z"></path></svg></span></a></span> maximum practical operating frequencies around 1 MHz, <span class="inline-flex" data-state="closed"><a href="https://en.wikipedia.org/wiki/555_timer_IC" target="_blank" class="group/tag relative h-[18px] rounded-full inline-flex items-center overflow-hidden -translate-y-px cursor-pointer"><span class="relative transition-colors h-full max-w-[180px] overflow-hidden px-1.5 inline-flex items-center font-small rounded-full border-0.5 border-border-300 bg-bg-200 group-hover/tag:bg-accent-secondary-900 group-hover/tag:border-accent-secondary-100/60"><span class="text-nowrap text-text-300 break-all truncate font-normal group-hover/tag:text-text-200">Wikipedia</span></span><span class="transition-all opacity-[0%] h-[17px] absolute right-[0.5px] inline rounded-r-full flex items-center px-1.5 bg-gradient-to-r from-accent-secondary-900/0 via-accent-secondary-900/100 via-30% to-accent-secondary-900/100 group-hover/tag:opacity-[100%]"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 256 256" class="transition-all group-hover/tag:ease-out duration-[500ms] ease-in text-accent-secondary-100 group-hover/tag:scale-[100%] scale-[80%] group-hover/tag:opacity-[100%] opacity-[0%] -mr-[2px]"><path d="M200,64V168a8,8,0,0,1-16,0V83.31L69.66,197.66a8,8,0,0,1-11.32-11.32L172.69,72H88a8,8,0,0,1,0-16H192A8,8,0,0,1,200,64Z"></path></svg></span></a></span> and RC timing networks that cannot charge or discharge quickly enough at nanosecond timescales.</p>
<p class="whitespace-normal break-words">For reference, the minimum reliable pulse width from a 555 timer is approximately <strong>200-500 nanoseconds</strong> - a full order of magnitude too slow for this application. Even if the circuit could theoretically trigger at the correct intervals, the slew-rate-limited output would fail to properly drive the laser driver circuit, resulting in poorly defined laser pulses with excessive jitter and inconsistent pulse energy.</p>
<h2 class="text-xl font-bold text-text-100 mt-1 -mb-0.5">Novel pulse generation circuit: 74AC14 Schmitt trigger solution</h2>
<p class="whitespace-normal break-words">The solution employs <strong>74AC14 hex inverter with Schmitt trigger inputs</strong> from the Advanced CMOS (AC) logic family. This chip provides the speed necessary for sub-100ns pulse generation through fundamentally faster switching mechanisms.</p>
<h3 class="text-lg font-bold text-text-100 mt-1 -mb-1.5">Why 74AC14 succeeds where 555 fails</h3>
<p class="whitespace-normal break-words">The 74AC14 achieves <strong>3-5 nanosecond rise and fall times</strong> <span class="inline-flex" data-state="closed"><a href="https://www.newark.com/on-semiconductor/74ac14sc/hex-inverter-schmitt-trigger-soic/dp/05M2996" target="_blank" class="group/tag relative h-[18px] rounded-full inline-flex items-center overflow-hidden -translate-y-px cursor-pointer"><span class="relative transition-colors h-full max-w-[180px] overflow-hidden px-1.5 inline-flex items-center font-small rounded-full border-0.5 border-border-300 bg-bg-200 group-hover/tag:bg-accent-secondary-900 group-hover/tag:border-accent-secondary-100/60"><span class="text-nowrap text-text-300 break-all truncate font-normal group-hover/tag:text-text-200">Newark Electronics</span></span><span class="transition-all opacity-[0%] h-[17px] absolute right-[0.5px] inline rounded-r-full flex items-center px-1.5 bg-gradient-to-r from-accent-secondary-900/0 via-accent-secondary-900/100 via-30% to-accent-secondary-900/100 group-hover/tag:opacity-[100%]"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 256 256" class="transition-all group-hover/tag:ease-out duration-[500ms] ease-in text-accent-secondary-100 group-hover/tag:scale-[100%] scale-[80%] group-hover/tag:opacity-[100%] opacity-[0%] -mr-[2px]"><path d="M200,64V168a8,8,0,0,1-16,0V83.31L69.66,197.66a8,8,0,0,1-11.32-11.32L172.69,72H88a8,8,0,0,1,0-16H192A8,8,0,0,1,200,64Z"></path></svg></span></a></span> - approximately 20× faster than the 555 timer. <span class="inline-flex" data-state="closed"><a href="https://www.onsemi.com/products/timing-logic-memory/standard-logic/logic-gates/74ac14" target="_blank" class="group/tag relative h-[18px] rounded-full inline-flex items-center overflow-hidden -translate-y-px cursor-pointer"><span class="relative transition-colors h-full max-w-[180px] overflow-hidden px-1.5 inline-flex items-center font-small rounded-full border-0.5 border-border-300 bg-bg-200 group-hover/tag:bg-accent-secondary-900 group-hover/tag:border-accent-secondary-100/60"><span class="text-nowrap text-text-300 break-all truncate font-normal group-hover/tag:text-text-200">Onsemi</span></span><span class="transition-all opacity-[0%] h-[17px] absolute right-[0.5px] inline rounded-r-full flex items-center px-1.5 bg-gradient-to-r from-accent-secondary-900/0 via-accent-secondary-900/100 via-30% to-accent-secondary-900/100 group-hover/tag:opacity-[100%]"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 256 256" class="transition-all group-hover/tag:ease-out duration-[500ms] ease-in text-accent-secondary-100 group-hover/tag:scale-[100%] scale-[80%] group-hover/tag:opacity-[100%] opacity-[0%] -mr-[2px]"><path d="M200,64V168a8,8,0,0,1-16,0V83.31L69.66,197.66a8,8,0,0,1-11.32-11.32L172.69,72H88a8,8,0,0,1,0-16H192A8,8,0,0,1,200,64Z"></path></svg></span></a></span> This speed comes from the Advanced CMOS fabrication process, which minimizes parasitic capacitances and optimizes charge carrier mobility. The Schmitt trigger input provides hysteresis of approximately 1.0V between positive-going and negative-going thresholds, creating sharply defined, jitter-free transitions that are essentially insensitive to temperature variations and power supply noise.</p>
<h3 class="text-lg font-bold text-text-100 mt-1 -mb-1.5">Circuit topology: RC differentiation for pulse shaping</h3>
<p class="whitespace-normal break-words">The pulse generation circuit uses a two-stage approach:</p>
<p class="whitespace-normal break-words"><strong>Stage 1 - Base oscillator</strong>: One 74AC14 inverter is configured as an RC oscillator to generate a square wave at the system repetition rate (~3 kHz, set by the motor/encoder system).</p>
<p class="whitespace-normal break-words"><strong>Stage 2 - Pulse differentiation</strong>: A capacitor-resistor differentiator (high-pass filter) converts the square wave edges into narrow pulses. The differentiator responds to rapid voltage changes (dV/dt), allowing only the rising edge transition to pass through as a brief voltage spike.</p>
<p class="whitespace-normal break-words"><strong>Pulse width calculation</strong>: The RC time constant determines pulse width:</p>
<div class="relative group/copy bg-bg-000/50 border-0.5 border-border-400 rounded-lg"><div class="sticky opacity-0 group-hover/copy:opacity-100 top-2 py-2 h-12 w-0 float-right"><div class="absolute right-0 h-8 px-2 items-center inline-flex z-10"><button class="inline-flex
  items-center
  justify-center
  relative
  shrink-0
  can-focus
  select-none
  disabled:pointer-events-none
  disabled:opacity-50
  disabled:shadow-none
  disabled:drop-shadow-none text-text-300
          border-transparent
          transition
          font-base
          duration-300
          ease-[cubic-bezier(0.165,0.85,0.45,1)]
          hover:bg-bg-300
          aria-checked:bg-bg-400
          aria-expanded:bg-bg-400
          hover:text-text-100
          aria-pressed:text-text-100
          aria-checked:text-text-100
          aria-expanded:text-text-100 h-8 w-8 rounded-md active:scale-95 backdrop-blur-md" type="button" aria-label="Copy to clipboard" data-state="closed"><div class="relative"><div class="flex items-center justify-center transition-all opacity-100 scale-100" style="width: 20px; height: 20px;"><svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor" xmlns="http://www.w3.org/2000/svg" class="shrink-0 transition-all opacity-100 scale-100" aria-hidden="true"><path d="M10 1.5C11.1097 1.5 12.0758 2.10424 12.5947 3H14.5C15.3284 3 16 3.67157 16 4.5V16.5C16 17.3284 15.3284 18 14.5 18H5.5C4.67157 18 4 17.3284 4 16.5V4.5C4 3.67157 4.67157 3 5.5 3H7.40527C7.92423 2.10424 8.89028 1.5 10 1.5ZM5.5 4C5.22386 4 5 4.22386 5 4.5V16.5C5 16.7761 5.22386 17 5.5 17H14.5C14.7761 17 15 16.7761 15 16.5V4.5C15 4.22386 14.7761 4 14.5 4H12.958C12.9853 4.16263 13 4.32961 13 4.5V5.5C13 5.77614 12.7761 6 12.5 6H7.5C7.22386 6 7 5.77614 7 5.5V4.5C7 4.32961 7.0147 4.16263 7.04199 4H5.5ZM12.54 13.3037C12.6486 13.05 12.9425 12.9317 13.1963 13.04C13.45 13.1486 13.5683 13.4425 13.46 13.6963C13.1651 14.3853 12.589 15 11.7998 15C11.3132 14.9999 10.908 14.7663 10.5996 14.4258C10.2913 14.7661 9.88667 14.9999 9.40039 15C8.91365 15 8.50769 14.7665 8.19922 14.4258C7.89083 14.7661 7.48636 15 7 15C6.72386 15 6.5 14.7761 6.5 14.5C6.5 14.2239 6.72386 14 7 14C7.21245 14 7.51918 13.8199 7.74023 13.3037L7.77441 13.2373C7.86451 13.0913 8.02513 13 8.2002 13C8.40022 13.0001 8.58145 13.1198 8.66016 13.3037C8.88121 13.8198 9.18796 14 9.40039 14C9.61284 13.9998 9.9197 13.8197 10.1406 13.3037L10.1748 13.2373C10.2649 13.0915 10.4248 13.0001 10.5996 13C10.7997 13 10.9808 13.1198 11.0596 13.3037C11.2806 13.8198 11.5874 13.9999 11.7998 14C12.0122 14 12.319 13.8198 12.54 13.3037ZM12.54 9.30371C12.6486 9.05001 12.9425 8.93174 13.1963 9.04004C13.45 9.14863 13.5683 9.44253 13.46 9.69629C13.1651 10.3853 12.589 11 11.7998 11C11.3132 10.9999 10.908 10.7663 10.5996 10.4258C10.2913 10.7661 9.88667 10.9999 9.40039 11C8.91365 11 8.50769 10.7665 8.19922 10.4258C7.89083 10.7661 7.48636 11 7 11C6.72386 11 6.5 10.7761 6.5 10.5C6.5 10.2239 6.72386 10 7 10C7.21245 10 7.51918 9.8199 7.74023 9.30371L7.77441 9.2373C7.86451 9.09126 8.02513 9 8.2002 9C8.40022 9.00008 8.58145 9.11981 8.66016 9.30371C8.88121 9.8198 9.18796 10 9.40039 10C9.61284 9.99978 9.9197 9.81969 10.1406 9.30371L10.1748 9.2373C10.2649 9.09147 10.4248 9.00014 10.5996 9C10.7997 9 10.9808 9.11975 11.0596 9.30371C11.2806 9.8198 11.5874 9.99989 11.7998 10C12.0122 10 12.319 9.81985 12.54 9.30371ZM10 2.5C8.89543 2.5 8 3.39543 8 4.5V5H12V4.5C12 3.39543 11.1046 2.5 10 2.5Z"></path></svg></div><div class="flex items-center justify-center absolute top-0 left-0 transition-all opacity-0 scale-50" style="width: 20px; height: 20px;"><svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor" xmlns="http://www.w3.org/2000/svg" class="shrink-0 absolute top-0 left-0 transition-all opacity-0 scale-50" aria-hidden="true"><path d="M15.1883 5.10908C15.3699 4.96398 15.6346 4.96153 15.8202 5.11592C16.0056 5.27067 16.0504 5.53125 15.9403 5.73605L15.8836 5.82003L8.38354 14.8202C8.29361 14.9279 8.16242 14.9925 8.02221 14.9989C7.88203 15.0051 7.74545 14.9526 7.64622 14.8534L4.14617 11.3533L4.08172 11.2752C3.95384 11.0811 3.97542 10.817 4.14617 10.6463C4.31693 10.4755 4.58105 10.4539 4.77509 10.5818L4.85321 10.6463L7.96556 13.7586L15.1161 5.1794L15.1883 5.10908Z"></path></svg></div></div></button></div></div><div><pre class="code-block__code !my-0 !rounded-lg !text-sm !leading-relaxed" style="background: transparent; color: rgb(171, 178, 191); text-shadow: rgba(0, 0, 0, 0.3) 0px 1px; font-family: var(--font-mono); direction: ltr; text-align: left; white-space: pre; word-spacing: normal; word-break: normal; line-height: 1.5; tab-size: 2; hyphens: none; padding: 1em; margin: 0.5em 0px; overflow: auto; border-radius: 0.3em;"><code style="background: transparent; color: rgb(171, 178, 191); text-shadow: rgba(0, 0, 0, 0.3) 0px 1px; font-family: var(--font-mono); direction: ltr; text-align: left; white-space: pre-wrap; word-spacing: normal; word-break: normal; line-height: 1.5; tab-size: 2; hyphens: none;"><span><span>τ = R × C
</span></span><span>For 50ns pulse: R ≈ 500Ω, C ≈ 100pF
</span><span>τ = 500Ω × 100pF = 50ns</span></code></pre></div></div>
<p class="whitespace-normal break-words">The capacitor passes the high-frequency edge components while the resistor provides the discharge path. Typical component values range from 100pF to 1nF for the capacitor and 50Ω to 1kΩ for the resistor, <span class="inline-flex" data-state="closed"><a href="https://forum.allaboutcircuits.com/threads/nanosecond-pulse-generator.36615/" target="_blank" class="group/tag relative h-[18px] rounded-full inline-flex items-center overflow-hidden -translate-y-px cursor-pointer"><span class="relative transition-colors h-full max-w-[180px] overflow-hidden px-1.5 inline-flex items-center font-small rounded-full border-0.5 border-border-300 bg-bg-200 group-hover/tag:bg-accent-secondary-900 group-hover/tag:border-accent-secondary-100/60"><span class="text-nowrap text-text-300 break-all truncate font-normal group-hover/tag:text-text-200">All About Circuits</span></span><span class="transition-all opacity-[0%] h-[17px] absolute right-[0.5px] inline rounded-r-full flex items-center px-1.5 bg-gradient-to-r from-accent-secondary-900/0 via-accent-secondary-900/100 via-30% to-accent-secondary-900/100 group-hover/tag:opacity-[100%]"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 256 256" class="transition-all group-hover/tag:ease-out duration-[500ms] ease-in text-accent-secondary-100 group-hover/tag:scale-[100%] scale-[80%] group-hover/tag:opacity-[100%] opacity-[0%] -mr-[2px]"><path d="M200,64V168a8,8,0,0,1-16,0V83.31L69.66,197.66a8,8,0,0,1-11.32-11.32L172.69,72H88a8,8,0,0,1,0-16H192A8,8,0,0,1,200,64Z"></path></svg></span></a></span> with a <strong>multi-turn trim potentiometer</strong> allowing precise adjustment of pulse width to match the laser driver's optimal trigger characteristics.</p>
<h3 class="text-lg font-bold text-text-100 mt-1 -mb-1.5">Parallel inverter configuration: Four gates for adequate drive current</h3>
<p class="whitespace-normal break-words">The circuit <strong>gangs four 74AC14 inverters in parallel</strong> at the output stage - a configuration critical for properly driving 50Ω loads. This design decision addresses a fundamental impedance matching problem.</p>
<p class="whitespace-normal break-words"><strong>Current drive requirements</strong>: A single 74AC14 inverter can source or sink 24mA. <span class="inline-flex" data-state="closed"><a href="https://www.onsemi.com/products/timing-logic-memory/standard-logic/logic-gates/74ac14" target="_blank" class="group/tag relative h-[18px] rounded-full inline-flex items-center overflow-hidden -translate-y-px cursor-pointer"><span class="relative transition-colors h-full max-w-[180px] overflow-hidden px-1.5 inline-flex items-center font-small rounded-full border-0.5 border-border-300 bg-bg-200 group-hover/tag:bg-accent-secondary-900 group-hover/tag:border-accent-secondary-100/60"><span class="text-nowrap text-text-300 break-all truncate font-normal group-hover/tag:text-text-200">Onsemi</span></span><span class="transition-all opacity-[0%] h-[17px] absolute right-[0.5px] inline rounded-r-full flex items-center px-1.5 bg-gradient-to-r from-accent-secondary-900/0 via-accent-secondary-900/100 via-30% to-accent-secondary-900/100 group-hover/tag:opacity-[100%]"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 256 256" class="transition-all group-hover/tag:ease-out duration-[500ms] ease-in text-accent-secondary-100 group-hover/tag:scale-[100%] scale-[80%] group-hover/tag:opacity-[100%] opacity-[0%] -mr-[2px]"><path d="M200,64V168a8,8,0,0,1-16,0V83.31L69.66,197.66a8,8,0,0,1-11.32-11.32L172.69,72H88a8,8,0,0,1,0-16H192A8,8,0,0,1,200,64Z"></path></svg></span></a></span> However, driving a 50Ω load (standard for oscilloscope inputs, coaxial transmission lines, and many laser driver inputs) at 5-6V requires:</p>
<div class="relative group/copy bg-bg-000/50 border-0.5 border-border-400 rounded-lg"><div class="sticky opacity-0 group-hover/copy:opacity-100 top-2 py-2 h-12 w-0 float-right"><div class="absolute right-0 h-8 px-2 items-center inline-flex z-10"><button class="inline-flex
  items-center
  justify-center
  relative
  shrink-0
  can-focus
  select-none
  disabled:pointer-events-none
  disabled:opacity-50
  disabled:shadow-none
  disabled:drop-shadow-none text-text-300
          border-transparent
          transition
          font-base
          duration-300
          ease-[cubic-bezier(0.165,0.85,0.45,1)]
          hover:bg-bg-300
          aria-checked:bg-bg-400
          aria-expanded:bg-bg-400
          hover:text-text-100
          aria-pressed:text-text-100
          aria-checked:text-text-100
          aria-expanded:text-text-100 h-8 w-8 rounded-md active:scale-95 backdrop-blur-md" type="button" aria-label="Copy to clipboard" data-state="closed"><div class="relative"><div class="flex items-center justify-center transition-all opacity-100 scale-100" style="width: 20px; height: 20px;"><svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor" xmlns="http://www.w3.org/2000/svg" class="shrink-0 transition-all opacity-100 scale-100" aria-hidden="true"><path d="M10 1.5C11.1097 1.5 12.0758 2.10424 12.5947 3H14.5C15.3284 3 16 3.67157 16 4.5V16.5C16 17.3284 15.3284 18 14.5 18H5.5C4.67157 18 4 17.3284 4 16.5V4.5C4 3.67157 4.67157 3 5.5 3H7.40527C7.92423 2.10424 8.89028 1.5 10 1.5ZM5.5 4C5.22386 4 5 4.22386 5 4.5V16.5C5 16.7761 5.22386 17 5.5 17H14.5C14.7761 17 15 16.7761 15 16.5V4.5C15 4.22386 14.7761 4 14.5 4H12.958C12.9853 4.16263 13 4.32961 13 4.5V5.5C13 5.77614 12.7761 6 12.5 6H7.5C7.22386 6 7 5.77614 7 5.5V4.5C7 4.32961 7.0147 4.16263 7.04199 4H5.5ZM12.54 13.3037C12.6486 13.05 12.9425 12.9317 13.1963 13.04C13.45 13.1486 13.5683 13.4425 13.46 13.6963C13.1651 14.3853 12.589 15 11.7998 15C11.3132 14.9999 10.908 14.7663 10.5996 14.4258C10.2913 14.7661 9.88667 14.9999 9.40039 15C8.91365 15 8.50769 14.7665 8.19922 14.4258C7.89083 14.7661 7.48636 15 7 15C6.72386 15 6.5 14.7761 6.5 14.5C6.5 14.2239 6.72386 14 7 14C7.21245 14 7.51918 13.8199 7.74023 13.3037L7.77441 13.2373C7.86451 13.0913 8.02513 13 8.2002 13C8.40022 13.0001 8.58145 13.1198 8.66016 13.3037C8.88121 13.8198 9.18796 14 9.40039 14C9.61284 13.9998 9.9197 13.8197 10.1406 13.3037L10.1748 13.2373C10.2649 13.0915 10.4248 13.0001 10.5996 13C10.7997 13 10.9808 13.1198 11.0596 13.3037C11.2806 13.8198 11.5874 13.9999 11.7998 14C12.0122 14 12.319 13.8198 12.54 13.3037ZM12.54 9.30371C12.6486 9.05001 12.9425 8.93174 13.1963 9.04004C13.45 9.14863 13.5683 9.44253 13.46 9.69629C13.1651 10.3853 12.589 11 11.7998 11C11.3132 10.9999 10.908 10.7663 10.5996 10.4258C10.2913 10.7661 9.88667 10.9999 9.40039 11C8.91365 11 8.50769 10.7665 8.19922 10.4258C7.89083 10.7661 7.48636 11 7 11C6.72386 11 6.5 10.7761 6.5 10.5C6.5 10.2239 6.72386 10 7 10C7.21245 10 7.51918 9.8199 7.74023 9.30371L7.77441 9.2373C7.86451 9.09126 8.02513 9 8.2002 9C8.40022 9.00008 8.58145 9.11981 8.66016 9.30371C8.88121 9.8198 9.18796 10 9.40039 10C9.61284 9.99978 9.9197 9.81969 10.1406 9.30371L10.1748 9.2373C10.2649 9.09147 10.4248 9.00014 10.5996 9C10.7997 9 10.9808 9.11975 11.0596 9.30371C11.2806 9.8198 11.5874 9.99989 11.7998 10C12.0122 10 12.319 9.81985 12.54 9.30371ZM10 2.5C8.89543 2.5 8 3.39543 8 4.5V5H12V4.5C12 3.39543 11.1046 2.5 10 2.5Z"></path></svg></div><div class="flex items-center justify-center absolute top-0 left-0 transition-all opacity-0 scale-50" style="width: 20px; height: 20px;"><svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor" xmlns="http://www.w3.org/2000/svg" class="shrink-0 absolute top-0 left-0 transition-all opacity-0 scale-50" aria-hidden="true"><path d="M15.1883 5.10908C15.3699 4.96398 15.6346 4.96153 15.8202 5.11592C16.0056 5.27067 16.0504 5.53125 15.9403 5.73605L15.8836 5.82003L8.38354 14.8202C8.29361 14.9279 8.16242 14.9925 8.02221 14.9989C7.88203 15.0051 7.74545 14.9526 7.64622 14.8534L4.14617 11.3533L4.08172 11.2752C3.95384 11.0811 3.97542 10.817 4.14617 10.6463C4.31693 10.4755 4.58105 10.4539 4.77509 10.5818L4.85321 10.6463L7.96556 13.7586L15.1161 5.1794L15.1883 5.10908Z"></path></svg></div></div></button></div></div><div><pre class="code-block__code !my-0 !rounded-lg !text-sm !leading-relaxed" style="background: transparent; color: rgb(171, 178, 191); text-shadow: rgba(0, 0, 0, 0.3) 0px 1px; font-family: var(--font-mono); direction: ltr; text-align: left; white-space: pre; word-spacing: normal; word-break: normal; line-height: 1.5; tab-size: 2; hyphens: none; padding: 1em; margin: 0.5em 0px; overflow: auto; border-radius: 0.3em;"><code style="background: transparent; color: rgb(171, 178, 191); text-shadow: rgba(0, 0, 0, 0.3) 0px 1px; font-family: var(--font-mono); direction: ltr; text-align: left; white-space: pre-wrap; word-spacing: normal; word-break: normal; line-height: 1.5; tab-size: 2; hyphens: none;"><span><span>I = V/R = 6V / 50Ω = 120mA</span></span></code></pre></div></div>
<p class="whitespace-normal break-words"><strong>Parallel inverter physics</strong>: When inverters are paralleled, their output current capabilities add directly. Four inverters provide approximately <strong>96mA combined drive current</strong> - sufficient to approach the theoretical 120mA requirement. The actual drive current slightly exceeds this due to the 6V supply (discussed below).</p>
<p class="whitespace-normal break-words"><strong>Critical performance benefits</strong>:</p>
<ul class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-disc space-y-2.5 pl-7">
<li class="whitespace-normal break-words"><strong>Faster edge rates</strong>: Higher available current allows the paralleled outputs to charge and discharge load capacitance more rapidly, resulting in "squarer" edges on the output waveform</li>
<li class="whitespace-normal break-words"><strong>Lower effective output impedance</strong>: ~12.5Ω with four inverters versus ~50Ω for a single gate</li>
<li class="whitespace-normal break-words"><strong>Reduced voltage droop</strong>: The output maintains amplitude when driving low-impedance loads</li>
<li class="whitespace-normal break-words"><strong>Better impedance matching</strong>: Closer match to 50Ω systems minimizes reflections</li>
</ul>
<p class="whitespace-normal break-words"><strong>Engineering note</strong>: Good supply decoupling is mandatory when paralleling inverters. The simultaneous switching of multiple gates creates significant transient current demands. Multiple decoupling capacitors (0.1μF ceramic placed immediately adjacent to the IC pins, plus 10-47μF bulk capacitance) prevent supply rail collapse during switching transitions.</p>
<h3 class="text-lg font-bold text-text-100 mt-1 -mb-1.5">Operating at 6V instead of 5V: Maximizing performance headroom</h3>
<p class="whitespace-normal break-words">The circuit operates at <strong>6V rather than the standard 5V</strong> logic level, extracting maximum performance from the 74AC14 within its absolute maximum rating of 6.5V.</p>
<p class="whitespace-normal break-words"><strong>Rationale for 6V operation</strong>:</p>
<ol class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-decimal space-y-2.5 pl-7">
<li class="whitespace-normal break-words"><strong>Increased output swing</strong>: Higher supply voltage directly translates to higher output voltage amplitude, providing better signal-to-noise ratio for fast edges and ensuring full switching of subsequent stages</li>
<li class="whitespace-normal break-words"><strong>Enhanced drive current</strong>: CMOS output current capability increases with supply voltage. At 6V, each gate can source/sink slightly more than the 24mA specification at 5V, improving the combined 4-gate drive capacity</li>
<li class="whitespace-normal break-words"><strong>Optimized switching speed</strong>: AC-series logic family propagation delays decrease with increased V_CC. The gates switch faster at 6V than at 5V, further reducing rise/fall times</li>
<li class="whitespace-normal break-words"><strong>Headroom for voltage drops</strong>: The extra 1V compensates for resistive drops in PCB traces, paralleled output connections, and series output resistors used for impedance matching</li>
<li class="whitespace-normal break-words"><strong>Threshold margin</strong>: Higher voltage provides better noise margins relative to Schmitt trigger threshold levels, improving reliability in the presence of switching noise</li>
</ol>
<p class="whitespace-normal break-words">The 74AC14 datasheet specifies operation from 2V to 6V, making 6V a safe choice with 0.5V margin below the absolute maximum.</p>
<h2 class="text-xl font-bold text-text-100 mt-1 -mb-0.5">System integration and signal flow architecture</h2>
<p class="whitespace-normal break-words">The complete system comprises five major subsystems that must synchronize with sub-nanosecond precision across hundreds of thousands of laser pulses.</p>
<h3 class="text-lg font-bold text-text-100 mt-1 -mb-1.5">Power distribution: Multi-voltage supply tree</h3>
<p class="whitespace-normal break-words">A single <strong>16V wall-wart power supply</strong> feeds the entire system through cascaded voltage regulators:</p>
<ul class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-disc space-y-2.5 pl-7">
<li class="whitespace-normal break-words"><strong>16V input</strong> from wall adapter</li>
<li class="whitespace-normal break-words"><strong>15V regulated output</strong> powers the laser driver module (typically requiring 12-15V for sufficient LED/laser diode current)</li>
<li class="whitespace-normal break-words"><strong>6V regulated output</strong> powers the 74AC14 pulse generation logic</li>
<li class="whitespace-normal break-words"><strong>High-voltage PMT supply</strong> (separate, typically 1000-2000V) powers the photomultiplier tube</li>
</ul>
<p class="whitespace-normal break-words">This architecture isolates the sensitive high-speed logic from the noisy laser driver switching currents while minimizing the number of power adapters required.</p>
<h3 class="text-lg font-bold text-text-100 mt-1 -mb-1.5">Motor and encoder system: Generating the 3kHz repetition rate</h3>
<p class="whitespace-normal break-words">A <strong>DC motor drives a rotating scanning mirror</strong> that sweeps the laser beam across the scene. An <strong>optical encoder</strong> (likely reflective or transmissive optical interrupter) mounted on the motor shaft generates a pulse train synchronized to mirror position.</p>
<p class="whitespace-normal break-words"><strong>Encoder signal processing</strong>: The encoder's raw output feeds a <strong>555 timer configured as a monostable multivibrator</strong> via an <strong>optocoupler</strong>. The optocoupler provides electrical isolation, preventing motor noise from corrupting the sensitive timing circuits. Each encoder pulse triggers the 555, which generates a clean, debounced pulse that initiates the next laser flash. <span class="inline-flex" data-state="closed"><a href="https://www.electronics-tutorials.ws/waveforms/555_timer.html" target="_blank" class="group/tag relative h-[18px] rounded-full inline-flex items-center overflow-hidden -translate-y-px cursor-pointer"><span class="relative transition-colors h-full max-w-[180px] overflow-hidden px-1.5 inline-flex items-center font-small rounded-full border-0.5 border-border-300 bg-bg-200 group-hover/tag:bg-accent-secondary-900 group-hover/tag:border-accent-secondary-100/60"><span class="text-nowrap text-text-300 break-all truncate font-normal group-hover/tag:text-text-200">Electronics Tutorials</span></span><span class="transition-all opacity-[0%] h-[17px] absolute right-[0.5px] inline rounded-r-full flex items-center px-1.5 bg-gradient-to-r from-accent-secondary-900/0 via-accent-secondary-900/100 via-30% to-accent-secondary-900/100 group-hover/tag:opacity-[100%]"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 256 256" class="transition-all group-hover/tag:ease-out duration-[500ms] ease-in text-accent-secondary-100 group-hover/tag:scale-[100%] scale-[80%] group-hover/tag:opacity-[100%] opacity-[0%] -mr-[2px]"><path d="M200,64V168a8,8,0,0,1-16,0V83.31L69.66,197.66a8,8,0,0,1-11.32-11.32L172.69,72H88a8,8,0,0,1,0-16H192A8,8,0,0,1,200,64Z"></path></svg></span></a></span><span class="inline-flex w-1"></span><span class="inline-flex" data-state="closed"><a href="https://www.instructables.com/555-Timer/" target="_blank" class="group/tag relative h-[18px] rounded-full inline-flex items-center overflow-hidden -translate-y-px cursor-pointer"><span class="relative transition-colors h-full max-w-[180px] overflow-hidden px-1.5 inline-flex items-center font-small rounded-full border-0.5 border-border-300 bg-bg-200 group-hover/tag:bg-accent-secondary-900 group-hover/tag:border-accent-secondary-100/60"><span class="text-nowrap text-text-300 break-all truncate font-normal group-hover/tag:text-text-200">Instructables</span></span><span class="transition-all opacity-[0%] h-[17px] absolute right-[0.5px] inline rounded-r-full flex items-center px-1.5 bg-gradient-to-r from-accent-secondary-900/0 via-accent-secondary-900/100 via-30% to-accent-secondary-900/100 group-hover/tag:opacity-[100%]"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 256 256" class="transition-all group-hover/tag:ease-out duration-[500ms] ease-in text-accent-secondary-100 group-hover/tag:scale-[100%] scale-[80%] group-hover/tag:opacity-[100%] opacity-[0%] -mr-[2px]"><path d="M200,64V168a8,8,0,0,1-16,0V83.31L69.66,197.66a8,8,0,0,1-11.32-11.32L172.69,72H88a8,8,0,0,1,0-16H192A8,8,0,0,1,200,64Z"></path></svg></span></a></span></p>
<p class="whitespace-normal break-words"><strong>Repetition rate calculation</strong>: At approximately <strong>3000 Hz repetition rate</strong> and 921,600 total pixels:</p>
<div class="relative group/copy bg-bg-000/50 border-0.5 border-border-400 rounded-lg"><div class="sticky opacity-0 group-hover/copy:opacity-100 top-2 py-2 h-12 w-0 float-right"><div class="absolute right-0 h-8 px-2 items-center inline-flex z-10"><button class="inline-flex
  items-center
  justify-center
  relative
  shrink-0
  can-focus
  select-none
  disabled:pointer-events-none
  disabled:opacity-50
  disabled:shadow-none
  disabled:drop-shadow-none text-text-300
          border-transparent
          transition
          font-base
          duration-300
          ease-[cubic-bezier(0.165,0.85,0.45,1)]
          hover:bg-bg-300
          aria-checked:bg-bg-400
          aria-expanded:bg-bg-400
          hover:text-text-100
          aria-pressed:text-text-100
          aria-checked:text-text-100
          aria-expanded:text-text-100 h-8 w-8 rounded-md active:scale-95 backdrop-blur-md" type="button" aria-label="Copy to clipboard" data-state="closed"><div class="relative"><div class="flex items-center justify-center transition-all opacity-100 scale-100" style="width: 20px; height: 20px;"><svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor" xmlns="http://www.w3.org/2000/svg" class="shrink-0 transition-all opacity-100 scale-100" aria-hidden="true"><path d="M10 1.5C11.1097 1.5 12.0758 2.10424 12.5947 3H14.5C15.3284 3 16 3.67157 16 4.5V16.5C16 17.3284 15.3284 18 14.5 18H5.5C4.67157 18 4 17.3284 4 16.5V4.5C4 3.67157 4.67157 3 5.5 3H7.40527C7.92423 2.10424 8.89028 1.5 10 1.5ZM5.5 4C5.22386 4 5 4.22386 5 4.5V16.5C5 16.7761 5.22386 17 5.5 17H14.5C14.7761 17 15 16.7761 15 16.5V4.5C15 4.22386 14.7761 4 14.5 4H12.958C12.9853 4.16263 13 4.32961 13 4.5V5.5C13 5.77614 12.7761 6 12.5 6H7.5C7.22386 6 7 5.77614 7 5.5V4.5C7 4.32961 7.0147 4.16263 7.04199 4H5.5ZM12.54 13.3037C12.6486 13.05 12.9425 12.9317 13.1963 13.04C13.45 13.1486 13.5683 13.4425 13.46 13.6963C13.1651 14.3853 12.589 15 11.7998 15C11.3132 14.9999 10.908 14.7663 10.5996 14.4258C10.2913 14.7661 9.88667 14.9999 9.40039 15C8.91365 15 8.50769 14.7665 8.19922 14.4258C7.89083 14.7661 7.48636 15 7 15C6.72386 15 6.5 14.7761 6.5 14.5C6.5 14.2239 6.72386 14 7 14C7.21245 14 7.51918 13.8199 7.74023 13.3037L7.77441 13.2373C7.86451 13.0913 8.02513 13 8.2002 13C8.40022 13.0001 8.58145 13.1198 8.66016 13.3037C8.88121 13.8198 9.18796 14 9.40039 14C9.61284 13.9998 9.9197 13.8197 10.1406 13.3037L10.1748 13.2373C10.2649 13.0915 10.4248 13.0001 10.5996 13C10.7997 13 10.9808 13.1198 11.0596 13.3037C11.2806 13.8198 11.5874 13.9999 11.7998 14C12.0122 14 12.319 13.8198 12.54 13.3037ZM12.54 9.30371C12.6486 9.05001 12.9425 8.93174 13.1963 9.04004C13.45 9.14863 13.5683 9.44253 13.46 9.69629C13.1651 10.3853 12.589 11 11.7998 11C11.3132 10.9999 10.908 10.7663 10.5996 10.4258C10.2913 10.7661 9.88667 10.9999 9.40039 11C8.91365 11 8.50769 10.7665 8.19922 10.4258C7.89083 10.7661 7.48636 11 7 11C6.72386 11 6.5 10.7761 6.5 10.5C6.5 10.2239 6.72386 10 7 10C7.21245 10 7.51918 9.8199 7.74023 9.30371L7.77441 9.2373C7.86451 9.09126 8.02513 9 8.2002 9C8.40022 9.00008 8.58145 9.11981 8.66016 9.30371C8.88121 9.8198 9.18796 10 9.40039 10C9.61284 9.99978 9.9197 9.81969 10.1406 9.30371L10.1748 9.2373C10.2649 9.09147 10.4248 9.00014 10.5996 9C10.7997 9 10.9808 9.11975 11.0596 9.30371C11.2806 9.8198 11.5874 9.99989 11.7998 10C12.0122 10 12.319 9.81985 12.54 9.30371ZM10 2.5C8.89543 2.5 8 3.39543 8 4.5V5H12V4.5C12 3.39543 11.1046 2.5 10 2.5Z"></path></svg></div><div class="flex items-center justify-center absolute top-0 left-0 transition-all opacity-0 scale-50" style="width: 20px; height: 20px;"><svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor" xmlns="http://www.w3.org/2000/svg" class="shrink-0 absolute top-0 left-0 transition-all opacity-0 scale-50" aria-hidden="true"><path d="M15.1883 5.10908C15.3699 4.96398 15.6346 4.96153 15.8202 5.11592C16.0056 5.27067 16.0504 5.53125 15.9403 5.73605L15.8836 5.82003L8.38354 14.8202C8.29361 14.9279 8.16242 14.9925 8.02221 14.9989C7.88203 15.0051 7.74545 14.9526 7.64622 14.8534L4.14617 11.3533L4.08172 11.2752C3.95384 11.0811 3.97542 10.817 4.14617 10.6463C4.31693 10.4755 4.58105 10.4539 4.77509 10.5818L4.85321 10.6463L7.96556 13.7586L15.1161 5.1794L15.1883 5.10908Z"></path></svg></div></div></button></div></div><div><pre class="code-block__code !my-0 !rounded-lg !text-sm !leading-relaxed" style="background: transparent; color: rgb(171, 178, 191); text-shadow: rgba(0, 0, 0, 0.3) 0px 1px; font-family: var(--font-mono); direction: ltr; text-align: left; white-space: pre; word-spacing: normal; word-break: normal; line-height: 1.5; tab-size: 2; hyphens: none; padding: 1em; margin: 0.5em 0px; overflow: auto; border-radius: 0.3em;"><code style="background: transparent; color: rgb(171, 178, 191); text-shadow: rgba(0, 0, 0, 0.3) 0px 1px; font-family: var(--font-mono); direction: ltr; text-align: left; white-space: pre-wrap; word-spacing: normal; word-break: normal; line-height: 1.5; tab-size: 2; hyphens: none;"><span><span>Total acquisition time = 921,600 pixels / 3000 Hz = 307 seconds ≈ 5 minutes</span></span></code></pre></div></div>
<p class="whitespace-normal break-words">Each motor revolution captures one horizontal line of the image (1280 pixels), requiring 720 revolutions for the complete frame. The encoder must provide 1280 pulses per revolution, either through a high-resolution optical encoder disk or through electronic division of a higher-frequency carrier.</p>
<h3 class="text-lg font-bold text-text-100 mt-1 -mb-1.5">Signal chain: From encoder to laser to detector</h3>
<p class="whitespace-normal break-words"><strong>Timing sequence</strong> (see state diagram below):</p>
<ol class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-decimal space-y-2.5 pl-7">
<li class="whitespace-normal break-words"><strong>Motor rotation</strong> → Encoder generates position pulse</li>
<li class="whitespace-normal break-words"><strong>Encoder pulse</strong> → 555 timer (via optocoupler) generates clean trigger</li>
<li class="whitespace-normal break-words"><strong>555 output</strong> → 74AC14 differentiator generates 50ns pulse</li>
<li class="whitespace-normal break-words"><strong>50ns pulse</strong> → Laser driver produces brief, high-intensity laser pulse</li>
<li class="whitespace-normal break-words"><strong>Laser pulse</strong> → Propagates through scene, reflects/scatters</li>
<li class="whitespace-normal break-words"><strong>Scattered light</strong> → Photomultiplier tube detects arriving photons</li>
<li class="whitespace-normal break-words"><strong>PMT output</strong> → Oscilloscope captures and records signal amplitude</li>
<li class="whitespace-normal break-words"><strong>Oscilloscope</strong> → Computer samples data point corresponding to (x,y) mirror position</li>
</ol>
<p class="whitespace-normal break-words"><strong>Distinction between signal types</strong> (critical for understanding):</p>
<ul class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-disc space-y-2.5 pl-7">
<li class="whitespace-normal break-words"><strong>Red/black wire pair</strong>: Low-precision "start blinking" signal from 555 to laser driver (millivolt-level, timing accuracy ~100ns)</li>
<li class="whitespace-normal break-words"><strong>Coaxial cable</strong>: High-precision timing reference from laser driver feedback output to oscilloscope (timing accuracy &lt;1ns required)</li>
</ul>
<h3 class="text-lg font-bold text-text-100 mt-1 -mb-1.5">Coaxial cable delay system: The key to precision timing</h3>
<p class="whitespace-normal break-words">The most elegant aspect of this system is the <strong>~200-foot coaxial cable spool</strong> that provides a precisely calibrated time delay for oscilloscope triggering.</p>
<p class="whitespace-normal break-words"><strong>The fundamental problem</strong>: The oscilloscope must trigger at precisely the moment the laser fires, not when the PMT detects light. However, the PMT signal arrives microseconds after the laser pulse (due to light travel time through the scene), and triggering on the PMT signal itself would create circular causality - you can't trigger on data you're trying to measure.</p>
<p class="whitespace-normal break-words"><strong>The solution</strong>: The laser driver includes a feedback output that generates a timing pulse exactly coincident with the laser emission. This signal travels through <strong>~200 feet of coaxial cable</strong> before reaching the oscilloscope trigger input.</p>
<p class="whitespace-normal break-words"><strong>Delay calculation</strong>:</p>
<div class="relative group/copy bg-bg-000/50 border-0.5 border-border-400 rounded-lg"><div class="sticky opacity-0 group-hover/copy:opacity-100 top-2 py-2 h-12 w-0 float-right"><div class="absolute right-0 h-8 px-2 items-center inline-flex z-10"><button class="inline-flex
  items-center
  justify-center
  relative
  shrink-0
  can-focus
  select-none
  disabled:pointer-events-none
  disabled:opacity-50
  disabled:shadow-none
  disabled:drop-shadow-none text-text-300
          border-transparent
          transition
          font-base
          duration-300
          ease-[cubic-bezier(0.165,0.85,0.45,1)]
          hover:bg-bg-300
          aria-checked:bg-bg-400
          aria-expanded:bg-bg-400
          hover:text-text-100
          aria-pressed:text-text-100
          aria-checked:text-text-100
          aria-expanded:text-text-100 h-8 w-8 rounded-md active:scale-95 backdrop-blur-md" type="button" aria-label="Copy to clipboard" data-state="closed"><div class="relative"><div class="flex items-center justify-center transition-all opacity-100 scale-100" style="width: 20px; height: 20px;"><svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor" xmlns="http://www.w3.org/2000/svg" class="shrink-0 transition-all opacity-100 scale-100" aria-hidden="true"><path d="M10 1.5C11.1097 1.5 12.0758 2.10424 12.5947 3H14.5C15.3284 3 16 3.67157 16 4.5V16.5C16 17.3284 15.3284 18 14.5 18H5.5C4.67157 18 4 17.3284 4 16.5V4.5C4 3.67157 4.67157 3 5.5 3H7.40527C7.92423 2.10424 8.89028 1.5 10 1.5ZM5.5 4C5.22386 4 5 4.22386 5 4.5V16.5C5 16.7761 5.22386 17 5.5 17H14.5C14.7761 17 15 16.7761 15 16.5V4.5C15 4.22386 14.7761 4 14.5 4H12.958C12.9853 4.16263 13 4.32961 13 4.5V5.5C13 5.77614 12.7761 6 12.5 6H7.5C7.22386 6 7 5.77614 7 5.5V4.5C7 4.32961 7.0147 4.16263 7.04199 4H5.5ZM12.54 13.3037C12.6486 13.05 12.9425 12.9317 13.1963 13.04C13.45 13.1486 13.5683 13.4425 13.46 13.6963C13.1651 14.3853 12.589 15 11.7998 15C11.3132 14.9999 10.908 14.7663 10.5996 14.4258C10.2913 14.7661 9.88667 14.9999 9.40039 15C8.91365 15 8.50769 14.7665 8.19922 14.4258C7.89083 14.7661 7.48636 15 7 15C6.72386 15 6.5 14.7761 6.5 14.5C6.5 14.2239 6.72386 14 7 14C7.21245 14 7.51918 13.8199 7.74023 13.3037L7.77441 13.2373C7.86451 13.0913 8.02513 13 8.2002 13C8.40022 13.0001 8.58145 13.1198 8.66016 13.3037C8.88121 13.8198 9.18796 14 9.40039 14C9.61284 13.9998 9.9197 13.8197 10.1406 13.3037L10.1748 13.2373C10.2649 13.0915 10.4248 13.0001 10.5996 13C10.7997 13 10.9808 13.1198 11.0596 13.3037C11.2806 13.8198 11.5874 13.9999 11.7998 14C12.0122 14 12.319 13.8198 12.54 13.3037ZM12.54 9.30371C12.6486 9.05001 12.9425 8.93174 13.1963 9.04004C13.45 9.14863 13.5683 9.44253 13.46 9.69629C13.1651 10.3853 12.589 11 11.7998 11C11.3132 10.9999 10.908 10.7663 10.5996 10.4258C10.2913 10.7661 9.88667 10.9999 9.40039 11C8.91365 11 8.50769 10.7665 8.19922 10.4258C7.89083 10.7661 7.48636 11 7 11C6.72386 11 6.5 10.7761 6.5 10.5C6.5 10.2239 6.72386 10 7 10C7.21245 10 7.51918 9.8199 7.74023 9.30371L7.77441 9.2373C7.86451 9.09126 8.02513 9 8.2002 9C8.40022 9.00008 8.58145 9.11981 8.66016 9.30371C8.88121 9.8198 9.18796 10 9.40039 10C9.61284 9.99978 9.9197 9.81969 10.1406 9.30371L10.1748 9.2373C10.2649 9.09147 10.4248 9.00014 10.5996 9C10.7997 9 10.9808 9.11975 11.0596 9.30371C11.2806 9.8198 11.5874 9.99989 11.7998 10C12.0122 10 12.319 9.81985 12.54 9.30371ZM10 2.5C8.89543 2.5 8 3.39543 8 4.5V5H12V4.5C12 3.39543 11.1046 2.5 10 2.5Z"></path></svg></div><div class="flex items-center justify-center absolute top-0 left-0 transition-all opacity-0 scale-50" style="width: 20px; height: 20px;"><svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor" xmlns="http://www.w3.org/2000/svg" class="shrink-0 absolute top-0 left-0 transition-all opacity-0 scale-50" aria-hidden="true"><path d="M15.1883 5.10908C15.3699 4.96398 15.6346 4.96153 15.8202 5.11592C16.0056 5.27067 16.0504 5.53125 15.9403 5.73605L15.8836 5.82003L8.38354 14.8202C8.29361 14.9279 8.16242 14.9925 8.02221 14.9989C7.88203 15.0051 7.74545 14.9526 7.64622 14.8534L4.14617 11.3533L4.08172 11.2752C3.95384 11.0811 3.97542 10.817 4.14617 10.6463C4.31693 10.4755 4.58105 10.4539 4.77509 10.5818L4.85321 10.6463L7.96556 13.7586L15.1161 5.1794L15.1883 5.10908Z"></path></svg></div></div></button></div></div><div><pre class="code-block__code !my-0 !rounded-lg !text-sm !leading-relaxed" style="background: transparent; color: rgb(171, 178, 191); text-shadow: rgba(0, 0, 0, 0.3) 0px 1px; font-family: var(--font-mono); direction: ltr; text-align: left; white-space: pre; word-spacing: normal; word-break: normal; line-height: 1.5; tab-size: 2; hyphens: none; padding: 1em; margin: 0.5em 0px; overflow: auto; border-radius: 0.3em;"><code style="background: transparent; color: rgb(171, 178, 191); text-shadow: rgba(0, 0, 0, 0.3) 0px 1px; font-family: var(--font-mono); direction: ltr; text-align: left; white-space: pre-wrap; word-spacing: normal; word-break: normal; line-height: 1.5; tab-size: 2; hyphens: none;"><span><span>Speed of light in coax ≈ 0.66c (typical for polyethylene dielectric)
</span></span><span>= 0.66 × 3×10^8 m/s = 2×10^8 m/s
</span><span>
</span><span>For 200 feet (61 meters):
</span><span>Delay = 61m / (2×10^8 m/s) = 305 nanoseconds</span></code></pre></div></div>
<p class="whitespace-normal break-words">This <strong>~300ns delay</strong> allows the following sequence:</p>
<ol class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-decimal space-y-2.5 pl-7">
<li class="whitespace-normal break-words">Laser fires, generating a timing pulse on the coax cable</li>
<li class="whitespace-normal break-words">Light propagates through scene (~50ns for a 15-meter path)</li>
<li class="whitespace-normal break-words">PMT detects light and generates output signal</li>
<li class="whitespace-normal break-words">PMT signal arrives at oscilloscope (~200-250ns after laser fired)</li>
<li class="whitespace-normal break-words">Timing signal arrives via coax delay (~300ns after laser fired)</li>
<li class="whitespace-normal break-words">Oscilloscope triggers on coax signal, capturing PMT data that occurred 50-100ns earlier</li>
</ol>
<p class="whitespace-normal break-words">By carefully trimming the cable length and adjusting the oscilloscope trigger delay settings, the operator positions the PMT signal in the optimal portion of the oscilloscope's capture window.</p>
<p class="whitespace-normal break-words"><strong>Why sub-nanosecond accuracy matters</strong>: At 2 billion fps, each frame represents 0.5 nanoseconds of elapsed time. Timing jitter of even 1ns would blur two frames together, destroying temporal resolution. The coaxial delay system provides stable, repeatable timing because the cable's propagation delay is constant and temperature-stable (varying by only ~100 ppm/°C for quality coax).</p>
<h2 class="text-xl font-bold text-text-100 mt-1 -mb-0.5">Photomultiplier tube data acquisition</h2>
<p class="whitespace-normal break-words">The <strong>photomultiplier tube (PMT)</strong> serves as the single-pixel detector, converting individual photons arriving from the scene into measurable electrical pulses. <span class="inline-flex" data-state="closed"><a href="https://en.wikipedia.org/wiki/Photomultiplier_tube" target="_blank" class="group/tag relative h-[18px] rounded-full inline-flex items-center overflow-hidden -translate-y-px cursor-pointer"><span class="relative transition-colors h-full max-w-[180px] overflow-hidden px-1.5 inline-flex items-center font-small rounded-full border-0.5 border-border-300 bg-bg-200 group-hover/tag:bg-accent-secondary-900 group-hover/tag:border-accent-secondary-100/60"><span class="text-nowrap text-text-300 break-all truncate font-normal group-hover/tag:text-text-200">Wikipedia</span></span><span class="transition-all opacity-[0%] h-[17px] absolute right-[0.5px] inline rounded-r-full flex items-center px-1.5 bg-gradient-to-r from-accent-secondary-900/0 via-accent-secondary-900/100 via-30% to-accent-secondary-900/100 group-hover/tag:opacity-[100%]"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 256 256" class="transition-all group-hover/tag:ease-out duration-[500ms] ease-in text-accent-secondary-100 group-hover/tag:scale-[100%] scale-[80%] group-hover/tag:opacity-[100%] opacity-[0%] -mr-[2px]"><path d="M200,64V168a8,8,0,0,1-16,0V83.31L69.66,197.66a8,8,0,0,1-11.32-11.32L172.69,72H88a8,8,0,0,1,0-16H192A8,8,0,0,1,200,64Z"></path></svg></span></a></span></p>
<h3 class="text-lg font-bold text-text-100 mt-1 -mb-1.5">PMT operating principles and requirements</h3>
<p class="whitespace-normal break-words">PMTs operate at <strong>high voltage (1000-2000V)</strong> to create sufficient electron multiplication gain. <span class="inline-flex" data-state="closed"><a href="https://en.wikipedia.org/wiki/Photomultiplier_tube" target="_blank" class="group/tag relative h-[18px] rounded-full inline-flex items-center overflow-hidden -translate-y-px cursor-pointer"><span class="relative transition-colors h-full max-w-[180px] overflow-hidden px-1.5 inline-flex items-center font-small rounded-full border-0.5 border-border-300 bg-bg-200 group-hover/tag:bg-accent-secondary-900 group-hover/tag:border-accent-secondary-100/60"><span class="text-nowrap text-text-300 break-all truncate font-normal group-hover/tag:text-text-200">Wikipedia</span></span><span class="transition-all opacity-[0%] h-[17px] absolute right-[0.5px] inline rounded-r-full flex items-center px-1.5 bg-gradient-to-r from-accent-secondary-900/0 via-accent-secondary-900/100 via-30% to-accent-secondary-900/100 group-hover/tag:opacity-[100%]"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 256 256" class="transition-all group-hover/tag:ease-out duration-[500ms] ease-in text-accent-secondary-100 group-hover/tag:scale-[100%] scale-[80%] group-hover/tag:opacity-[100%] opacity-[0%] -mr-[2px]"><path d="M200,64V168a8,8,0,0,1-16,0V83.31L69.66,197.66a8,8,0,0,1-11.32-11.32L172.69,72H88a8,8,0,0,1,0-16H192A8,8,0,0,1,200,64Z"></path></svg></span></a></span> Each incident photon ejects an electron from the photocathode; this electron is accelerated through a series of dynodes, each ejecting multiple secondary electrons, creating a cascade that amplifies the signal by factors of 10^6 or more. <span class="inline-flex" data-state="closed"><a href="https://en.wikipedia.org/wiki/Photomultiplier_tube" target="_blank" class="group/tag relative h-[18px] rounded-full inline-flex items-center overflow-hidden -translate-y-px cursor-pointer"><span class="relative transition-colors h-full max-w-[180px] overflow-hidden px-1.5 inline-flex items-center font-small rounded-full border-0.5 border-border-300 bg-bg-200 group-hover/tag:bg-accent-secondary-900 group-hover/tag:border-accent-secondary-100/60"><span class="text-nowrap text-text-300 break-all truncate font-normal group-hover/tag:text-text-200">Wikipedia</span></span><span class="transition-all opacity-[0%] h-[17px] absolute right-[0.5px] inline rounded-r-full flex items-center px-1.5 bg-gradient-to-r from-accent-secondary-900/0 via-accent-secondary-900/100 via-30% to-accent-secondary-900/100 group-hover/tag:opacity-[100%]"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 256 256" class="transition-all group-hover/tag:ease-out duration-[500ms] ease-in text-accent-secondary-100 group-hover/tag:scale-[100%] scale-[80%] group-hover/tag:opacity-[100%] opacity-[0%] -mr-[2px]"><path d="M200,64V168a8,8,0,0,1-16,0V83.31L69.66,197.66a8,8,0,0,1-11.32-11.32L172.69,72H88a8,8,0,0,1,0-16H192A8,8,0,0,1,200,64Z"></path></svg></span></a></span><span class="inline-flex w-1"></span><span class="inline-flex" data-state="closed"><a href="https://www.laserfocusworld.com/detectors-imaging/article/16550346/photomultiplier-tubes-count-photons" target="_blank" class="group/tag relative h-[18px] rounded-full inline-flex items-center overflow-hidden -translate-y-px cursor-pointer"><span class="relative transition-colors h-full max-w-[180px] overflow-hidden px-1.5 inline-flex items-center font-small rounded-full border-0.5 border-border-300 bg-bg-200 group-hover/tag:bg-accent-secondary-900 group-hover/tag:border-accent-secondary-100/60"><span class="text-nowrap text-text-300 break-all truncate font-normal group-hover/tag:text-text-200">Laser Focus World</span></span><span class="transition-all opacity-[0%] h-[17px] absolute right-[0.5px] inline rounded-r-full flex items-center px-1.5 bg-gradient-to-r from-accent-secondary-900/0 via-accent-secondary-900/100 via-30% to-accent-secondary-900/100 group-hover/tag:opacity-[100%]"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 256 256" class="transition-all group-hover/tag:ease-out duration-[500ms] ease-in text-accent-secondary-100 group-hover/tag:scale-[100%] scale-[80%] group-hover/tag:opacity-[100%] opacity-[0%] -mr-[2px]"><path d="M200,64V168a8,8,0,0,1-16,0V83.31L69.66,197.66a8,8,0,0,1-11.32-11.32L172.69,72H88a8,8,0,0,1,0-16H192A8,8,0,0,1,200,64Z"></path></svg></span></a></span></p>
<p class="whitespace-normal break-words"><strong>Critical warm-up period</strong>: PMTs require <strong>10-30 minutes of warm-up time</strong> after power application to achieve stable gain. During warm-up, thermionic emission (dark current) decreases as the photocathode reaches thermal equilibrium, <span class="inline-flex" data-state="closed"><a href="https://www.laserfocusworld.com/detectors-imaging/article/16554117/select-the-photomultiplier-tube-that-matches-your-application" target="_blank" class="group/tag relative h-[18px] rounded-full inline-flex items-center overflow-hidden -translate-y-px cursor-pointer"><span class="relative transition-colors h-full max-w-[180px] overflow-hidden px-1.5 inline-flex items-center font-small rounded-full border-0.5 border-border-300 bg-bg-200 group-hover/tag:bg-accent-secondary-900 group-hover/tag:border-accent-secondary-100/60"><span class="text-nowrap text-text-300 break-all truncate font-normal group-hover/tag:text-text-200">Laser Focus World</span></span><span class="transition-all opacity-[0%] h-[17px] absolute right-[0.5px] inline rounded-r-full flex items-center px-1.5 bg-gradient-to-r from-accent-secondary-900/0 via-accent-secondary-900/100 via-30% to-accent-secondary-900/100 group-hover/tag:opacity-[100%]"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 256 256" class="transition-all group-hover/tag:ease-out duration-[500ms] ease-in text-accent-secondary-100 group-hover/tag:scale-[100%] scale-[80%] group-hover/tag:opacity-[100%] opacity-[0%] -mr-[2px]"><path d="M200,64V168a8,8,0,0,1-16,0V83.31L69.66,197.66a8,8,0,0,1-11.32-11.32L172.69,72H88a8,8,0,0,1,0-16H192A8,8,0,0,1,200,64Z"></path></svg></span></a></span> and the dynode chain stabilizes. Attempting to acquire data before warm-up completion results in drift artifacts and inconsistent pixel intensities.</p>
<p class="whitespace-normal break-words"><strong>Operating mode</strong>: For this application, the PMT likely operates in <strong>analog current mode</strong> rather than photon-counting mode. Each laser pulse reflects thousands of photons from the scene, and the PMT output current is proportional to instantaneous photon flux.</p>
<h3 class="text-lg font-bold text-text-100 mt-1 -mb-1.5">Data capture methodology: Single-pixel scanning</h3>
<p class="whitespace-normal break-words">The PMT is <strong>spatially fixed</strong> - it doesn't move. Instead, the rotating mirror scans the laser beam across the scene while simultaneously scanning the reflected light across the PMT's photocathode. Each mirror position corresponds to one pixel location.</p>
<p class="whitespace-normal break-words"><strong>Angular encoder registration</strong>: An angular encoder (either optical or magnetic) mounted on the motor shaft provides precise mirror position feedback. The acquisition computer reads:</p>
<ul class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-disc space-y-2.5 pl-7">
<li class="whitespace-normal break-words"><strong>X-position</strong>: Incremental encoder count modulo 1280 (horizontal pixel position)</li>
<li class="whitespace-normal break-words"><strong>Y-position</strong>: Encoder count divided by 1280 (vertical line number, 0-719)</li>
<li class="whitespace-normal break-words"><strong>PMT amplitude</strong>: Oscilloscope measurement at the predetermined time offset</li>
</ul>
<p class="whitespace-normal break-words"><strong>Pixel intensity mapping</strong>: The oscilloscope samples the PMT signal at a specific time delay after the laser pulse. By adjusting this delay across multiple experimental runs, the system captures different temporal "slices" of the light propagation. A complete "video" requires:</p>
<div class="relative group/copy bg-bg-000/50 border-0.5 border-border-400 rounded-lg"><div class="sticky opacity-0 group-hover/copy:opacity-100 top-2 py-2 h-12 w-0 float-right"><div class="absolute right-0 h-8 px-2 items-center inline-flex z-10"><button class="inline-flex
  items-center
  justify-center
  relative
  shrink-0
  can-focus
  select-none
  disabled:pointer-events-none
  disabled:opacity-50
  disabled:shadow-none
  disabled:drop-shadow-none text-text-300
          border-transparent
          transition
          font-base
          duration-300
          ease-[cubic-bezier(0.165,0.85,0.45,1)]
          hover:bg-bg-300
          aria-checked:bg-bg-400
          aria-expanded:bg-bg-400
          hover:text-text-100
          aria-pressed:text-text-100
          aria-checked:text-text-100
          aria-expanded:text-text-100 h-8 w-8 rounded-md active:scale-95 backdrop-blur-md" type="button" aria-label="Copy to clipboard" data-state="closed"><div class="relative"><div class="flex items-center justify-center transition-all opacity-100 scale-100" style="width: 20px; height: 20px;"><svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor" xmlns="http://www.w3.org/2000/svg" class="shrink-0 transition-all opacity-100 scale-100" aria-hidden="true"><path d="M10 1.5C11.1097 1.5 12.0758 2.10424 12.5947 3H14.5C15.3284 3 16 3.67157 16 4.5V16.5C16 17.3284 15.3284 18 14.5 18H5.5C4.67157 18 4 17.3284 4 16.5V4.5C4 3.67157 4.67157 3 5.5 3H7.40527C7.92423 2.10424 8.89028 1.5 10 1.5ZM5.5 4C5.22386 4 5 4.22386 5 4.5V16.5C5 16.7761 5.22386 17 5.5 17H14.5C14.7761 17 15 16.7761 15 16.5V4.5C15 4.22386 14.7761 4 14.5 4H12.958C12.9853 4.16263 13 4.32961 13 4.5V5.5C13 5.77614 12.7761 6 12.5 6H7.5C7.22386 6 7 5.77614 7 5.5V4.5C7 4.32961 7.0147 4.16263 7.04199 4H5.5ZM12.54 13.3037C12.6486 13.05 12.9425 12.9317 13.1963 13.04C13.45 13.1486 13.5683 13.4425 13.46 13.6963C13.1651 14.3853 12.589 15 11.7998 15C11.3132 14.9999 10.908 14.7663 10.5996 14.4258C10.2913 14.7661 9.88667 14.9999 9.40039 15C8.91365 15 8.50769 14.7665 8.19922 14.4258C7.89083 14.7661 7.48636 15 7 15C6.72386 15 6.5 14.7761 6.5 14.5C6.5 14.2239 6.72386 14 7 14C7.21245 14 7.51918 13.8199 7.74023 13.3037L7.77441 13.2373C7.86451 13.0913 8.02513 13 8.2002 13C8.40022 13.0001 8.58145 13.1198 8.66016 13.3037C8.88121 13.8198 9.18796 14 9.40039 14C9.61284 13.9998 9.9197 13.8197 10.1406 13.3037L10.1748 13.2373C10.2649 13.0915 10.4248 13.0001 10.5996 13C10.7997 13 10.9808 13.1198 11.0596 13.3037C11.2806 13.8198 11.5874 13.9999 11.7998 14C12.0122 14 12.319 13.8198 12.54 13.3037ZM12.54 9.30371C12.6486 9.05001 12.9425 8.93174 13.1963 9.04004C13.45 9.14863 13.5683 9.44253 13.46 9.69629C13.1651 10.3853 12.589 11 11.7998 11C11.3132 10.9999 10.908 10.7663 10.5996 10.4258C10.2913 10.7661 9.88667 10.9999 9.40039 11C8.91365 11 8.50769 10.7665 8.19922 10.4258C7.89083 10.7661 7.48636 11 7 11C6.72386 11 6.5 10.7761 6.5 10.5C6.5 10.2239 6.72386 10 7 10C7.21245 10 7.51918 9.8199 7.74023 9.30371L7.77441 9.2373C7.86451 9.09126 8.02513 9 8.2002 9C8.40022 9.00008 8.58145 9.11981 8.66016 9.30371C8.88121 9.8198 9.18796 10 9.40039 10C9.61284 9.99978 9.9197 9.81969 10.1406 9.30371L10.1748 9.2373C10.2649 9.09147 10.4248 9.00014 10.5996 9C10.7997 9 10.9808 9.11975 11.0596 9.30371C11.2806 9.8198 11.5874 9.99989 11.7998 10C12.0122 10 12.319 9.81985 12.54 9.30371ZM10 2.5C8.89543 2.5 8 3.39543 8 4.5V5H12V4.5C12 3.39543 11.1046 2.5 10 2.5Z"></path></svg></div><div class="flex items-center justify-center absolute top-0 left-0 transition-all opacity-0 scale-50" style="width: 20px; height: 20px;"><svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor" xmlns="http://www.w3.org/2000/svg" class="shrink-0 absolute top-0 left-0 transition-all opacity-0 scale-50" aria-hidden="true"><path d="M15.1883 5.10908C15.3699 4.96398 15.6346 4.96153 15.8202 5.11592C16.0056 5.27067 16.0504 5.53125 15.9403 5.73605L15.8836 5.82003L8.38354 14.8202C8.29361 14.9279 8.16242 14.9925 8.02221 14.9989C7.88203 15.0051 7.74545 14.9526 7.64622 14.8534L4.14617 11.3533L4.08172 11.2752C3.95384 11.0811 3.97542 10.817 4.14617 10.6463C4.31693 10.4755 4.58105 10.4539 4.77509 10.5818L4.85321 10.6463L7.96556 13.7586L15.1161 5.1794L15.1883 5.10908Z"></path></svg></div></div></button></div></div><div><pre class="code-block__code !my-0 !rounded-lg !text-sm !leading-relaxed" style="background: transparent; color: rgb(171, 178, 191); text-shadow: rgba(0, 0, 0, 0.3) 0px 1px; font-family: var(--font-mono); direction: ltr; text-align: left; white-space: pre; word-spacing: normal; word-break: normal; line-height: 1.5; tab-size: 2; hyphens: none; padding: 1em; margin: 0.5em 0px; overflow: auto; border-radius: 0.3em;"><code style="background: transparent; color: rgb(171, 178, 191); text-shadow: rgba(0, 0, 0, 0.3) 0px 1px; font-family: var(--font-mono); direction: ltr; text-align: left; white-space: pre-wrap; word-spacing: normal; word-break: normal; line-height: 1.5; tab-size: 2; hyphens: none;"><span><span>Total measurements = 1280 × 720 pixels × N temporal samples
</span></span><span>For N=30 time samples: 27,648,000 individual laser pulses
</span><span>At 3 kHz: 9,216 seconds = 2.56 hours acquisition time</span></code></pre></div></div>
<h2 class="text-xl font-bold text-text-100 mt-1 -mb-0.5">Oscilloscope triggering and synchronization architecture</h2>
<p class="whitespace-normal break-words">The oscilloscope serves as both the timing arbiter and data acquisition system, requiring careful configuration to avoid false triggers and timing artifacts.</p>
<h3 class="text-lg font-bold text-text-100 mt-1 -mb-1.5">Trigger signal isolation: Why the coax feedback is essential</h3>
<p class="whitespace-normal break-words"><strong>The problem with triggering on PMT data</strong>: If the oscilloscope triggered directly on the PMT signal, it would face an ambiguity - is this signal due to the current laser pulse or a reflection from a previous pulse? Additionally, the PMT signal amplitude varies with scene reflectivity, making threshold-based triggering unreliable.</p>
<p class="whitespace-normal break-words"><strong>The feedback coax solution</strong>: The laser driver's feedback output provides a <strong>clean, constant-amplitude timing reference</strong> that is perfectly synchronized to laser emission but electrically isolated from the PMT signal path. This feedback signal:</p>
<ul class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-disc space-y-2.5 pl-7">
<li class="whitespace-normal break-words">Has consistent amplitude regardless of scene content</li>
<li class="whitespace-normal break-words">Has fast rise time (~5ns) for precise trigger point definition</li>
<li class="whitespace-normal break-words">Is electrically isolated from the PMT circuit, preventing crosstalk</li>
<li class="whitespace-normal break-words">Arrives at a known, fixed delay via the coax cable</li>
</ul>
<h3 class="text-lg font-bold text-text-100 mt-1 -mb-1.5">Trim pot adjustment for Schmitt trigger threshold matching</h3>
<p class="whitespace-normal break-words">A <strong>trim potentiometer in the pulse generator circuit</strong> allows fine-tuning of the pulse amplitude to precisely match the <strong>74AC14 Schmitt trigger thresholds</strong>. The Schmitt trigger has two threshold voltages:</p>
<ul class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-disc space-y-2.5 pl-7">
<li class="whitespace-normal break-words"><strong>V_T+</strong> (positive-going threshold): ~3.5V at 6V supply</li>
<li class="whitespace-normal break-words"><strong>V_T-</strong> (negative-going threshold): ~2.5V at 6V supply</li>
</ul>
<p class="whitespace-normal break-words">The trim pot adjusts the pulse peak voltage to:</p>
<ol class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-decimal space-y-2.5 pl-7">
<li class="whitespace-normal break-words">Reliably exceed V_T+ for consistent triggering</li>
<li class="whitespace-normal break-words">Maintain sufficient noise margin above V_T+ to reject EMI from the motor and laser driver</li>
<li class="whitespace-normal break-words">Optimize pulse width by controlling the RC network charging voltage</li>
</ol>
<p class="whitespace-normal break-words"><strong>Adjustment procedure</strong>: While monitoring the oscilloscope trigger signal on one channel and the laser driver output on another, the operator adjusts the trim pot to achieve:</p>
<ul class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-disc space-y-2.5 pl-7">
<li class="whitespace-normal break-words">Stable, jitter-free triggering (indicated by stationary oscilloscope trace)</li>
<li class="whitespace-normal break-words">Maximum laser pulse intensity (indicating optimal driver triggering)</li>
<li class="whitespace-normal break-words">Minimum pulse width variation (measured on oscilloscope's persistence display)</li>
</ul>
<h2 class="text-xl font-bold text-text-100 mt-1 -mb-0.5">Complete system timing flow and state diagram</h2>
<p class="whitespace-normal break-words">The following state diagram illustrates the complete experimental sequence:</p>
<div class="relative group/copy bg-bg-000/50 border-0.5 border-border-400 rounded-lg"><div class="sticky opacity-0 group-hover/copy:opacity-100 top-2 py-2 h-12 w-0 float-right"><div class="absolute right-0 h-8 px-2 items-center inline-flex z-10"><button class="inline-flex
  items-center
  justify-center
  relative
  shrink-0
  can-focus
  select-none
  disabled:pointer-events-none
  disabled:opacity-50
  disabled:shadow-none
  disabled:drop-shadow-none text-text-300
          border-transparent
          transition
          font-base
          duration-300
          ease-[cubic-bezier(0.165,0.85,0.45,1)]
          hover:bg-bg-300
          aria-checked:bg-bg-400
          aria-expanded:bg-bg-400
          hover:text-text-100
          aria-pressed:text-text-100
          aria-checked:text-text-100
          aria-expanded:text-text-100 h-8 w-8 rounded-md active:scale-95 backdrop-blur-md" type="button" aria-label="Copy to clipboard" data-state="closed"><div class="relative"><div class="flex items-center justify-center transition-all opacity-100 scale-100" style="width: 20px; height: 20px;"><svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor" xmlns="http://www.w3.org/2000/svg" class="shrink-0 transition-all opacity-100 scale-100" aria-hidden="true"><path d="M10 1.5C11.1097 1.5 12.0758 2.10424 12.5947 3H14.5C15.3284 3 16 3.67157 16 4.5V16.5C16 17.3284 15.3284 18 14.5 18H5.5C4.67157 18 4 17.3284 4 16.5V4.5C4 3.67157 4.67157 3 5.5 3H7.40527C7.92423 2.10424 8.89028 1.5 10 1.5ZM5.5 4C5.22386 4 5 4.22386 5 4.5V16.5C5 16.7761 5.22386 17 5.5 17H14.5C14.7761 17 15 16.7761 15 16.5V4.5C15 4.22386 14.7761 4 14.5 4H12.958C12.9853 4.16263 13 4.32961 13 4.5V5.5C13 5.77614 12.7761 6 12.5 6H7.5C7.22386 6 7 5.77614 7 5.5V4.5C7 4.32961 7.0147 4.16263 7.04199 4H5.5ZM12.54 13.3037C12.6486 13.05 12.9425 12.9317 13.1963 13.04C13.45 13.1486 13.5683 13.4425 13.46 13.6963C13.1651 14.3853 12.589 15 11.7998 15C11.3132 14.9999 10.908 14.7663 10.5996 14.4258C10.2913 14.7661 9.88667 14.9999 9.40039 15C8.91365 15 8.50769 14.7665 8.19922 14.4258C7.89083 14.7661 7.48636 15 7 15C6.72386 15 6.5 14.7761 6.5 14.5C6.5 14.2239 6.72386 14 7 14C7.21245 14 7.51918 13.8199 7.74023 13.3037L7.77441 13.2373C7.86451 13.0913 8.02513 13 8.2002 13C8.40022 13.0001 8.58145 13.1198 8.66016 13.3037C8.88121 13.8198 9.18796 14 9.40039 14C9.61284 13.9998 9.9197 13.8197 10.1406 13.3037L10.1748 13.2373C10.2649 13.0915 10.4248 13.0001 10.5996 13C10.7997 13 10.9808 13.1198 11.0596 13.3037C11.2806 13.8198 11.5874 13.9999 11.7998 14C12.0122 14 12.319 13.8198 12.54 13.3037ZM12.54 9.30371C12.6486 9.05001 12.9425 8.93174 13.1963 9.04004C13.45 9.14863 13.5683 9.44253 13.46 9.69629C13.1651 10.3853 12.589 11 11.7998 11C11.3132 10.9999 10.908 10.7663 10.5996 10.4258C10.2913 10.7661 9.88667 10.9999 9.40039 11C8.91365 11 8.50769 10.7665 8.19922 10.4258C7.89083 10.7661 7.48636 11 7 11C6.72386 11 6.5 10.7761 6.5 10.5C6.5 10.2239 6.72386 10 7 10C7.21245 10 7.51918 9.8199 7.74023 9.30371L7.77441 9.2373C7.86451 9.09126 8.02513 9 8.2002 9C8.40022 9.00008 8.58145 9.11981 8.66016 9.30371C8.88121 9.8198 9.18796 10 9.40039 10C9.61284 9.99978 9.9197 9.81969 10.1406 9.30371L10.1748 9.2373C10.2649 9.09147 10.4248 9.00014 10.5996 9C10.7997 9 10.9808 9.11975 11.0596 9.30371C11.2806 9.8198 11.5874 9.99989 11.7998 10C12.0122 10 12.319 9.81985 12.54 9.30371ZM10 2.5C8.89543 2.5 8 3.39543 8 4.5V5H12V4.5C12 3.39543 11.1046 2.5 10 2.5Z"></path></svg></div><div class="flex items-center justify-center absolute top-0 left-0 transition-all opacity-0 scale-50" style="width: 20px; height: 20px;"><svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor" xmlns="http://www.w3.org/2000/svg" class="shrink-0 absolute top-0 left-0 transition-all opacity-0 scale-50" aria-hidden="true"><path d="M15.1883 5.10908C15.3699 4.96398 15.6346 4.96153 15.8202 5.11592C16.0056 5.27067 16.0504 5.53125 15.9403 5.73605L15.8836 5.82003L8.38354 14.8202C8.29361 14.9279 8.16242 14.9925 8.02221 14.9989C7.88203 15.0051 7.74545 14.9526 7.64622 14.8534L4.14617 11.3533L4.08172 11.2752C3.95384 11.0811 3.97542 10.817 4.14617 10.6463C4.31693 10.4755 4.58105 10.4539 4.77509 10.5818L4.85321 10.6463L7.96556 13.7586L15.1161 5.1794L15.1883 5.10908Z"></path></svg></div></div></button></div></div><div><pre class="code-block__code !my-0 !rounded-lg !text-sm !leading-relaxed" style="background: transparent; color: rgb(171, 178, 191); text-shadow: rgba(0, 0, 0, 0.3) 0px 1px; font-family: var(--font-mono); direction: ltr; text-align: left; white-space: pre; word-spacing: normal; word-break: normal; line-height: 1.5; tab-size: 2; hyphens: none; padding: 1em; margin: 0.5em 0px; overflow: auto; border-radius: 0.3em;"><code style="background: transparent; color: rgb(171, 178, 191); text-shadow: rgba(0, 0, 0, 0.3) 0px 1px; font-family: var(--font-mono); direction: ltr; text-align: left; white-space: pre-wrap; word-spacing: normal; word-break: normal; line-height: 1.5; tab-size: 2; hyphens: none;"><span><span>                    ┌─────────────┐
</span></span><span>                    │   SYSTEM    │
</span><span>                    │  POWER ON   │
</span><span>                    └──────┬──────┘
</span><span>                           │
</span><span>                           ▼
</span><span>                    ┌─────────────┐
</span><span>                    │   PMT       │
</span><span>                    │  WARM-UP    │
</span><span>                    │  (10-30min) │
</span><span>                    └──────┬──────┘
</span><span>                           │
</span><span>                           ▼
</span><span>                    ┌─────────────┐
</span><span>          ┌─────────┤   MOTOR     │◄────────┐
</span><span>          │         │   RUNNING   │         │
</span><span>          │         └──────┬──────┘         │
</span><span>          │                │                │
</span><span>          │                ▼                │
</span><span>          │         ┌─────────────┐         │
</span><span>          │         │  ENCODER    │         │
</span><span>          │         │  GENERATES  │         │
</span><span>          │         │   PULSE     │         │
</span><span>          │         └──────┬──────┘         │
</span><span>          │                │                │
</span><span>          │                ▼                │
</span><span>          │         ┌─────────────┐         │
</span><span>          │         │ 555 TIMER   │         │
</span><span>          │         │  TRIGGERS   │         │
</span><span>          │         │(via opto)   │         │
</span><span>          │         └──────┬──────┘         │
</span><span>          │                │                │
</span><span>          │                ▼                │
</span><span>          │         ┌─────────────┐         │
</span><span>          │         │  74AC14     │         │
</span><span>          │         │ GENERATES   │         │
</span><span>          │         │  50ns PULSE │         │
</span><span>          │         └──────┬──────┘         │
</span><span>          │                │                │
</span><span>          │                ▼                │
</span><span>          │         ┌─────────────┐         │
</span><span>          │         │ LASER       │         │
</span><span>          │         │ DRIVER      │         │
</span><span>          │         │ FIRES       │         │
</span><span>          │         └──┬───────┬──┘         │
</span><span>          │            │       │            │
</span><span>          │            │       └─────┐      │
</span><span>          │            │             │      │
</span><span>          │            ▼             ▼      │
</span><span>          │    ┌──────────────┐  ┌─────────────┐
</span><span>          │    │   LASER      │  │  FEEDBACK   │
</span><span>          │    │   PULSE      │  │   SIGNAL    │
</span><span>          │    │ PROPAGATES   │  │  TO COAX    │
</span><span>          │    └──────┬───────┘  └──────┬──────┘
</span><span>          │           │                 │
</span><span>          │           ▼                 │ (~300ns delay)
</span><span>          │    ┌──────────────┐         │
</span><span>          │    │  LIGHT       │         │
</span><span>          │    │  REFLECTS    │         │
</span><span>          │    │  FROM SCENE  │         │
</span><span>          │    └──────┬───────┘         │
</span><span>          │           │                 │
</span><span>          │           ▼                 │
</span><span>          │    ┌──────────────┐         │
</span><span>          │    │    PMT       │         │
</span><span>          │    │   DETECTS    │         │
</span><span>          │    │   PHOTONS    │         │
</span><span>          │    └──────┬───────┘         │
</span><span>          │           │                 │
</span><span>          │           ▼                 ▼
</span><span>          │    ┌─────────────────────────┐
</span><span>          │    │    OSCILLOSCOPE         │
</span><span>          │    │  - Trigger on coax      │
</span><span>          │    │  - Sample PMT output    │
</span><span>          │    │  - Record amplitude     │
</span><span>          │    └──────┬──────────────────┘
</span><span>          │           │
</span><span>          │           ▼
</span><span>          │    ┌─────────────┐
</span><span>          │    │  COMPUTER   │
</span><span>          │    │  STORES     │
</span><span>          │    │ PIXEL DATA  │
</span><span>          │    └──────┬──────┘
</span><span>          │           │
</span><span>          │           │    ┌──────────────┐
</span><span>          └───────────┴────┤  COMPLETE    │
</span><span>                           │ ONE PIXEL    │
</span><span>                           │  RETURN TO   │
</span><span>                           │  NEXT ENCODER│
</span><span>                           │  PULSE       │
</span><span>                           └──────────────┘</span></code></pre></div></div>
<h3 class="text-lg font-bold text-text-100 mt-1 -mb-1.5">Timing relationships and critical delays</h3>
<p class="whitespace-normal break-words"><strong>Key timing parameters</strong>:</p>
<pre class="font-ui border-border-100/50 overflow-x-scroll w-full rounded border-[0.5px] shadow-[0_2px_12px_hsl(var(--always-black)/5%)]"><table class="bg-bg-100 min-w-full border-separate border-spacing-0 text-sm leading-[1.88888] whitespace-normal"><thead class="border-b-border-100/50 border-b-[0.5px] text-left"><tr class="[tbody&gt;&amp;]:odd:bg-bg-500/10"><th class="text-text-000 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">Event</th><th class="text-text-000 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">Time (relative to laser fire)</th><th class="text-text-000 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">Precision required</th></tr></thead><tbody><tr class="[tbody&gt;&amp;]:odd:bg-bg-500/10"><td class="border-t-border-100/50 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] border-t-[0.5px] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">Laser driver receives 50ns pulse</td><td class="border-t-border-100/50 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] border-t-[0.5px] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">T₀</td><td class="border-t-border-100/50 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] border-t-[0.5px] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">±0.5ns</td></tr><tr class="[tbody&gt;&amp;]:odd:bg-bg-500/10"><td class="border-t-border-100/50 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] border-t-[0.5px] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">Laser emission begins</td><td class="border-t-border-100/50 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] border-t-[0.5px] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">T₀ + 5ns</td><td class="border-t-border-100/50 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] border-t-[0.5px] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">±1ns</td></tr><tr class="[tbody&gt;&amp;]:odd:bg-bg-500/10"><td class="border-t-border-100/50 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] border-t-[0.5px] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">Light travels 15m through scene</td><td class="border-t-border-100/50 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] border-t-[0.5px] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">T₀ + 50ns</td><td class="border-t-border-100/50 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] border-t-[0.5px] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">N/A (physics)</td></tr><tr class="[tbody&gt;&amp;]:odd:bg-bg-500/10"><td class="border-t-border-100/50 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] border-t-[0.5px] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">PMT detects photons</td><td class="border-t-border-100/50 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] border-t-[0.5px] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">T₀ + 50-100ns</td><td class="border-t-border-100/50 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] border-t-[0.5px] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">±2ns (detector response)</td></tr><tr class="[tbody&gt;&amp;]:odd:bg-bg-500/10"><td class="border-t-border-100/50 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] border-t-[0.5px] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">Feedback signal starts down coax</td><td class="border-t-border-100/50 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] border-t-[0.5px] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">T₀ + 2ns</td><td class="border-t-border-100/50 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] border-t-[0.5px] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">±0.5ns</td></tr><tr class="[tbody&gt;&amp;]:odd:bg-bg-500/10"><td class="border-t-border-100/50 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] border-t-[0.5px] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">Feedback signal arrives at oscilloscope</td><td class="border-t-border-100/50 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] border-t-[0.5px] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">T₀ + 305ns</td><td class="border-t-border-100/50 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] border-t-[0.5px] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">±0.5ns (cable stability)</td></tr><tr class="[tbody&gt;&amp;]:odd:bg-bg-500/10"><td class="border-t-border-100/50 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] border-t-[0.5px] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">Oscilloscope triggers</td><td class="border-t-border-100/50 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] border-t-[0.5px] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">T₀ + 305ns</td><td class="border-t-border-100/50 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] border-t-[0.5px] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">±1ns (trigger jitter)</td></tr><tr class="[tbody&gt;&amp;]:odd:bg-bg-500/10"><td class="border-t-border-100/50 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] border-t-[0.5px] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">Oscilloscope samples PMT</td><td class="border-t-border-100/50 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] border-t-[0.5px] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">T₀ + 50-100ns</td><td class="border-t-border-100/50 [&amp;:not(:first-child)]:-x-[hsla(var(--border-100) / 0.5)] border-t-[0.5px] px-2 [&amp;:not(:first-child)]:border-l-[0.5px]">±0.2ns (timebase accuracy)</td></tr></tbody></table></pre>
<p class="whitespace-normal break-words"><strong>Critical insight</strong>: The oscilloscope trigger occurs <strong>after</strong> the PMT signal has already arrived and been captured in the oscilloscope's analog memory. Modern digital oscilloscopes continuously buffer incoming signals; the trigger event simply tells the oscilloscope <strong>which portion of its buffer to save</strong>. This "post-trigger" capability is essential for capturing events that occur before the trigger signal arrives.</p>
<h2 class="text-xl font-bold text-text-100 mt-1 -mb-0.5">Video reconstruction: Assembling 921,600 individual measurements</h2>
<p class="whitespace-normal break-words">The final "video" is not a continuous recording but a <strong>composite reconstruction</strong> from hundreds of thousands of individual laser pulses, each capturing one spatial pixel at one temporal offset.</p>
<h3 class="text-lg font-bold text-text-100 mt-1 -mb-1.5">Pixel acquisition strategy</h3>
<p class="whitespace-normal break-words">For each pixel (x, y):</p>
<ol class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-decimal space-y-2.5 pl-7">
<li class="whitespace-normal break-words">Wait for encoder to indicate mirror at position (x, y)</li>
<li class="whitespace-normal break-words">Fire laser via 74AC14 pulse generator</li>
<li class="whitespace-normal break-words">Record PMT amplitude at time offset t₁</li>
<li class="whitespace-normal break-words">Store value as I(x, y, t₁)</li>
</ol>
<p class="whitespace-normal break-words">For each temporal frame:</p>
<ol class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-decimal space-y-2.5 pl-7">
<li class="whitespace-normal break-words">Acquire all 921,600 spatial pixels at the same time offset t_n</li>
<li class="whitespace-normal break-words">Assemble into 1280×720 image frame_n</li>
<li class="whitespace-normal break-words">Increment time offset: t_(n+1) = t_n + 0.5ns (for 2 billion fps)</li>
</ol>
<p class="whitespace-normal break-words"><strong>Total acquisition time</strong> (for 30-frame video):</p>
<div class="relative group/copy bg-bg-000/50 border-0.5 border-border-400 rounded-lg"><div class="sticky opacity-0 group-hover/copy:opacity-100 top-2 py-2 h-12 w-0 float-right"><div class="absolute right-0 h-8 px-2 items-center inline-flex z-10"><button class="inline-flex
  items-center
  justify-center
  relative
  shrink-0
  can-focus
  select-none
  disabled:pointer-events-none
  disabled:opacity-50
  disabled:shadow-none
  disabled:drop-shadow-none text-text-300
          border-transparent
          transition
          font-base
          duration-300
          ease-[cubic-bezier(0.165,0.85,0.45,1)]
          hover:bg-bg-300
          aria-checked:bg-bg-400
          aria-expanded:bg-bg-400
          hover:text-text-100
          aria-pressed:text-text-100
          aria-checked:text-text-100
          aria-expanded:text-text-100 h-8 w-8 rounded-md active:scale-95 backdrop-blur-md" type="button" aria-label="Copy to clipboard" data-state="closed"><div class="relative"><div class="flex items-center justify-center transition-all opacity-100 scale-100" style="width: 20px; height: 20px;"><svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor" xmlns="http://www.w3.org/2000/svg" class="shrink-0 transition-all opacity-100 scale-100" aria-hidden="true"><path d="M10 1.5C11.1097 1.5 12.0758 2.10424 12.5947 3H14.5C15.3284 3 16 3.67157 16 4.5V16.5C16 17.3284 15.3284 18 14.5 18H5.5C4.67157 18 4 17.3284 4 16.5V4.5C4 3.67157 4.67157 3 5.5 3H7.40527C7.92423 2.10424 8.89028 1.5 10 1.5ZM5.5 4C5.22386 4 5 4.22386 5 4.5V16.5C5 16.7761 5.22386 17 5.5 17H14.5C14.7761 17 15 16.7761 15 16.5V4.5C15 4.22386 14.7761 4 14.5 4H12.958C12.9853 4.16263 13 4.32961 13 4.5V5.5C13 5.77614 12.7761 6 12.5 6H7.5C7.22386 6 7 5.77614 7 5.5V4.5C7 4.32961 7.0147 4.16263 7.04199 4H5.5ZM12.54 13.3037C12.6486 13.05 12.9425 12.9317 13.1963 13.04C13.45 13.1486 13.5683 13.4425 13.46 13.6963C13.1651 14.3853 12.589 15 11.7998 15C11.3132 14.9999 10.908 14.7663 10.5996 14.4258C10.2913 14.7661 9.88667 14.9999 9.40039 15C8.91365 15 8.50769 14.7665 8.19922 14.4258C7.89083 14.7661 7.48636 15 7 15C6.72386 15 6.5 14.7761 6.5 14.5C6.5 14.2239 6.72386 14 7 14C7.21245 14 7.51918 13.8199 7.74023 13.3037L7.77441 13.2373C7.86451 13.0913 8.02513 13 8.2002 13C8.40022 13.0001 8.58145 13.1198 8.66016 13.3037C8.88121 13.8198 9.18796 14 9.40039 14C9.61284 13.9998 9.9197 13.8197 10.1406 13.3037L10.1748 13.2373C10.2649 13.0915 10.4248 13.0001 10.5996 13C10.7997 13 10.9808 13.1198 11.0596 13.3037C11.2806 13.8198 11.5874 13.9999 11.7998 14C12.0122 14 12.319 13.8198 12.54 13.3037ZM12.54 9.30371C12.6486 9.05001 12.9425 8.93174 13.1963 9.04004C13.45 9.14863 13.5683 9.44253 13.46 9.69629C13.1651 10.3853 12.589 11 11.7998 11C11.3132 10.9999 10.908 10.7663 10.5996 10.4258C10.2913 10.7661 9.88667 10.9999 9.40039 11C8.91365 11 8.50769 10.7665 8.19922 10.4258C7.89083 10.7661 7.48636 11 7 11C6.72386 11 6.5 10.7761 6.5 10.5C6.5 10.2239 6.72386 10 7 10C7.21245 10 7.51918 9.8199 7.74023 9.30371L7.77441 9.2373C7.86451 9.09126 8.02513 9 8.2002 9C8.40022 9.00008 8.58145 9.11981 8.66016 9.30371C8.88121 9.8198 9.18796 10 9.40039 10C9.61284 9.99978 9.9197 9.81969 10.1406 9.30371L10.1748 9.2373C10.2649 9.09147 10.4248 9.00014 10.5996 9C10.7997 9 10.9808 9.11975 11.0596 9.30371C11.2806 9.8198 11.5874 9.99989 11.7998 10C12.0122 10 12.319 9.81985 12.54 9.30371ZM10 2.5C8.89543 2.5 8 3.39543 8 4.5V5H12V4.5C12 3.39543 11.1046 2.5 10 2.5Z"></path></svg></div><div class="flex items-center justify-center absolute top-0 left-0 transition-all opacity-0 scale-50" style="width: 20px; height: 20px;"><svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor" xmlns="http://www.w3.org/2000/svg" class="shrink-0 absolute top-0 left-0 transition-all opacity-0 scale-50" aria-hidden="true"><path d="M15.1883 5.10908C15.3699 4.96398 15.6346 4.96153 15.8202 5.11592C16.0056 5.27067 16.0504 5.53125 15.9403 5.73605L15.8836 5.82003L8.38354 14.8202C8.29361 14.9279 8.16242 14.9925 8.02221 14.9989C7.88203 15.0051 7.74545 14.9526 7.64622 14.8534L4.14617 11.3533L4.08172 11.2752C3.95384 11.0811 3.97542 10.817 4.14617 10.6463C4.31693 10.4755 4.58105 10.4539 4.77509 10.5818L4.85321 10.6463L7.96556 13.7586L15.1161 5.1794L15.1883 5.10908Z"></path></svg></div></div></button></div></div><div><pre class="code-block__code !my-0 !rounded-lg !text-sm !leading-relaxed" style="background: transparent; color: rgb(171, 178, 191); text-shadow: rgba(0, 0, 0, 0.3) 0px 1px; font-family: var(--font-mono); direction: ltr; text-align: left; white-space: pre; word-spacing: normal; word-break: normal; line-height: 1.5; tab-size: 2; hyphens: none; padding: 1em; margin: 0.5em 0px; overflow: auto; border-radius: 0.3em;"><code style="background: transparent; color: rgb(171, 178, 191); text-shadow: rgba(0, 0, 0, 0.3) 0px 1px; font-family: var(--font-mono); direction: ltr; text-align: left; white-space: pre-wrap; word-spacing: normal; word-break: normal; line-height: 1.5; tab-size: 2; hyphens: none;"><span><span>30 frames × 921,600 pixels/frame × 0.33ms/pixel = 9,145 seconds ≈ 2.5 hours</span></span></code></pre></div></div>
<h3 class="text-lg font-bold text-text-100 mt-1 -mb-1.5">Assumptions required for reconstruction validity</h3>
<p class="whitespace-normal break-words">This technique <strong>requires deterministic, repeatable events</strong>:</p>
<ul class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-disc space-y-2.5 pl-7">
<li class="whitespace-normal break-words">Laser pulse energy must be constant (±1%) across all pulses</li>
<li class="whitespace-normal break-words">Scene must be static (no movement during 2.5-hour acquisition)</li>
<li class="whitespace-normal break-words">Mirror scan must be repeatable (±0.01° angular precision)</li>
<li class="whitespace-normal break-words">Environmental conditions stable (temperature, vibration)</li>
</ul>
<p class="whitespace-normal break-words">For filming light propagation through a static scene (milk-filled water tank, optical components on table), these requirements are readily met. For dynamic scenes, this technique fails - you cannot film a person walking using this method.</p>
<h3 class="text-lg font-bold text-text-100 mt-1 -mb-1.5">Data processing and image assembly</h3>
<p class="whitespace-normal break-words">Raw oscilloscope data requires processing before visualization:</p>
<ol class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-decimal space-y-2.5 pl-7">
<li class="whitespace-normal break-words"><strong>Background subtraction</strong>: Dark current from PMT creates offset; subtract baseline measured with laser off</li>
<li class="whitespace-normal break-words"><strong>Gain normalization</strong>: Compensate for PMT gain variations during long acquisition</li>
<li class="whitespace-normal break-words"><strong>Spatial interpolation</strong>: Encoder quantization may not align perfectly with desired pixel grid</li>
<li class="whitespace-normal break-words"><strong>Temporal interpolation</strong>: Generate intermediate frames via interpolation for smoother video</li>
<li class="whitespace-normal break-words"><strong>False-color mapping</strong>: Assign photon intensity to color map for visualization</li>
<li class="whitespace-normal break-words"><strong>Gamma correction</strong>: Apply γ≈0.5 to enhance dim features</li>
</ol>
<h2 class="text-xl font-bold text-text-100 mt-1 -mb-0.5">Practical considerations for reproduction</h2>
<h3 class="text-lg font-bold text-text-100 mt-1 -mb-1.5">Critical components and specifications</h3>
<p class="whitespace-normal break-words"><strong>Pulse generator</strong>:</p>
<ul class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-disc space-y-2.5 pl-7">
<li class="whitespace-normal break-words">74AC14 hex Schmitt trigger inverter (Texas Instruments SN74AC14N or equivalent)</li>
<li class="whitespace-normal break-words">100pF C0G/NP0 ceramic capacitor (timing, ±5% tolerance)</li>
<li class="whitespace-normal break-words">470Ω ±1% resistor + 1kΩ 10-turn trim pot (pulse width adjustment)</li>
<li class="whitespace-normal break-words">0.1μF ceramic + 47μF electrolytic decoupling capacitors</li>
<li class="whitespace-normal break-words">6V regulated power supply (low-noise LDO, ±1%)</li>
</ul>
<p class="whitespace-normal break-words"><strong>Laser driver</strong>:</p>
<ul class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-disc space-y-2.5 pl-7">
<li class="whitespace-normal break-words">Capable of &lt;10ns pulse generation from 50ns trigger input</li>
<li class="whitespace-normal break-words">Feedback output with &lt;5ns rise time</li>
<li class="whitespace-normal break-words">100-500mW peak optical power (for adequate SNR after 15m propagation)</li>
</ul>
<p class="whitespace-normal break-words"><strong>Photomultiplier tube</strong>:</p>
<ul class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-disc space-y-2.5 pl-7">
<li class="whitespace-normal break-words">Spectral response matched to laser wavelength</li>
<li class="whitespace-normal break-words">Rise time &lt;10ns (for temporal resolution)</li>
<li class="whitespace-normal break-words">Active area ≥5mm (for easier alignment)</li>
<li class="whitespace-normal break-words">High-voltage power supply (1500V typical, well-regulated)</li>
</ul>
<p class="whitespace-normal break-words"><strong>Coaxial cable</strong>:</p>
<ul class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-disc space-y-2.5 pl-7">
<li class="whitespace-normal break-words">200 feet RG-58/U or equivalent (50Ω)</li>
<li class="whitespace-normal break-words">Velocity factor 0.66 (verify with manufacturer datasheet)</li>
<li class="whitespace-normal break-words">BNC connectors on both ends (solder, not crimp, for reliability)</li>
</ul>
<p class="whitespace-normal break-words"><strong>Oscilloscope</strong>:</p>
<ul class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-disc space-y-2.5 pl-7">
<li class="whitespace-normal break-words">Bandwidth ≥500 MHz (for 5ns rise time observation)</li>
<li class="whitespace-normal break-words">Sample rate ≥2 GSa/s</li>
<li class="whitespace-normal break-words">Pre-trigger capture capability</li>
<li class="whitespace-normal break-words">External trigger input with &lt;500ps jitter</li>
</ul>
<p class="whitespace-normal break-words"><strong>Motor and encoder</strong>:</p>
<ul class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-disc space-y-2.5 pl-7">
<li class="whitespace-normal break-words">Stable speed regulation (±0.1%)</li>
<li class="whitespace-normal break-words">Encoder resolution ≥1280 pulses/revolution</li>
<li class="whitespace-normal break-words">Optical isolation (optocoupler) for encoder output</li>
</ul>
<h3 class="text-lg font-bold text-text-100 mt-1 -mb-1.5">Common failure modes and troubleshooting</h3>
<p class="whitespace-normal break-words"><strong>Unstable oscilloscope triggering</strong>:</p>
<ul class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-disc space-y-2.5 pl-7">
<li class="whitespace-normal break-words">Check coax cable connections (reflections from poor termination cause double triggers)</li>
<li class="whitespace-normal break-words">Verify 50Ω termination at oscilloscope input</li>
<li class="whitespace-normal break-words">Adjust trim pot to optimize feedback pulse amplitude</li>
<li class="whitespace-normal break-words">Add shielding to pulse generator circuit (EMI from motor can corrupt trigger)</li>
</ul>
<p class="whitespace-normal break-words"><strong>Inconsistent laser pulses</strong>:</p>
<ul class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-disc space-y-2.5 pl-7">
<li class="whitespace-normal break-words">Verify 6V supply regulation (ripple &lt;10mV p-p)</li>
<li class="whitespace-normal break-words">Check for ringing on 74AC14 outputs (add series damping resistor if present)</li>
<li class="whitespace-normal break-words">Ensure adequate decoupling capacitors close to IC</li>
<li class="whitespace-normal break-words">Verify all four paralleled inverters are functional (one failed gate reduces drive current)</li>
</ul>
<p class="whitespace-normal break-words"><strong>PMT signal too noisy</strong>:</p>
<ul class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-disc space-y-2.5 pl-7">
<li class="whitespace-normal break-words">Extend warm-up time (some PMTs require &gt;30 minutes)</li>
<li class="whitespace-normal break-words">Shield PMT housing from ambient light leaks</li>
<li class="whitespace-normal break-words">Reduce PMT gain (lower high voltage) if signal is saturating</li>
<li class="whitespace-normal break-words">Add RC low-pass filter to PMT output (cutoff ~100 MHz to reject high-frequency noise)</li>
</ul>
<p class="whitespace-normal break-words"><strong>Spatial registration errors</strong>:</p>
<ul class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-disc space-y-2.5 pl-7">
<li class="whitespace-normal break-words">Verify encoder mechanical coupling (backlash causes position errors)</li>
<li class="whitespace-normal break-words">Check for motor speed variations (bearing friction, supply voltage ripple)</li>
<li class="whitespace-normal break-words">Calibrate encoder zero position using fixed reference marker</li>
</ul>
<h3 class="text-lg font-bold text-text-100 mt-1 -mb-1.5">Timing calibration procedure</h3>
<ol class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-decimal space-y-2.5 pl-7">
<li class="whitespace-normal break-words"><strong>Measure actual coax delay</strong>: Use oscilloscope in dual-channel mode, send pulse down coax, measure delay</li>
<li class="whitespace-normal break-words"><strong>Determine scene light travel time</strong>: For 15m scene, expected delay ≈ 50ns</li>
<li class="whitespace-normal break-words"><strong>Calculate required trigger delay</strong>: Trigger delay = PMT signal time - coax delay + desired observation offset</li>
<li class="whitespace-normal break-words"><strong>Verify temporal resolution</strong>: Fire laser at two different time offsets separated by 1ns; confirm visible difference in captured image</li>
<li class="whitespace-normal break-words"><strong>Characterize system jitter</strong>: Acquire 1000 measurements of the same pixel; calculate standard deviation (should be &lt;1ns)</li>
</ol>
<h2 class="text-xl font-bold text-text-100 mt-1 -mb-0.5">Conclusion: Why this approach enables billion-fps imaging on a budget</h2>
<p class="whitespace-normal break-words">This experimental system demonstrates that <strong>ultra-high-speed imaging is achievable without million-dollar commercial cameras</strong> by exploiting three key principles:</p>
<p class="whitespace-normal break-words"><strong>Time-domain multiplexing eliminates bandwidth requirements</strong>: Rather than capturing all pixels simultaneously (requiring terahertz-bandwidth detectors and electronics), this system captures one pixel at a time, with each measurement requiring only megahertz-bandwidth components. The 2 billion fps temporal resolution emerges from precision timing, not detector speed.</p>
<p class="whitespace-normal break-words"><strong>Nanosecond pulse generation is achievable with commodity logic ICs</strong>: The 74AC14 Schmitt trigger, costing under $1, provides rise times adequate for sub-10ns pulse generation when properly implemented. Parallel ganging overcomes drive current limitations, while the RC differentiator shapes pulses without requiring specialized components.</p>
<p class="whitespace-normal break-words"><strong>Coaxial cable delay provides picosecond-stable timing reference</strong>: A $20 spool of coax cable becomes a precision delay line with &lt;100ps jitter, enabling oscilloscope triggering that would otherwise require atomic clocks and complex synchronization electronics.</p>
<p class="whitespace-normal break-words">For researchers seeking to reproduce this work, the essential requirements are patience (2.5-hour acquisition times), precision (sub-nanosecond timing alignment), and deterministic events (static scenes or perfectly repeatable phenomena). Within these constraints, the system enables visualization of light-speed phenomena that remain invisible to human perception and conventional cameras alike - all from parts available at electronics distributors for under $500.</p>
<p class="whitespace-normal break-words"><strong>Complete bill of materials estimate</strong>: $450 (excluding oscilloscope and computer)</p>
<ul class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-disc space-y-2.5 pl-7">
<li class="whitespace-normal break-words">PMT with HV power supply: $200</li>
<li class="whitespace-normal break-words">Laser diode and driver: $100</li>
<li class="whitespace-normal break-words">Motor, encoder, mirror: $75</li>
<li class="whitespace-normal break-words">74AC14 and supporting components: $25</li>
<li class="whitespace-normal break-words">Coax cable and connectors: $50</li>
</ul>
<p class="whitespace-normal break-words">The true cost lies not in hardware but in the weeks of iterative debugging required to achieve sub-nanosecond timing stability across a system built from hobby electronics components - making this documentation essential for future experimenters seeking to reproduce these results without reinventing every troubleshooting step.</p>
<hr class="border-border-300 my-2">
<p class="whitespace-normal break-words"><strong>Source Videos</strong>:</p>
<ul class="[&amp;:not(:last-child)_ul]:pb-1 [&amp;:not(:last-child)_ol]:pb-1 list-disc space-y-2.5 pl-7">
<li class="whitespace-normal break-words">Pulse Generation Circuit: <a class="underline" href="https://www.youtube.com/watch?v=WLJuC0q84IQ">https://www.youtube.com/watch?v=WLJuC0q84IQ</a></li>
<li class="whitespace-normal break-words">System Integration: <a class="underline" href="https://www.youtube.com/watch?v=lWIXnL8RAcc">https://www.youtube.com/watch?v=lWIXnL8RAcc</a></li>
</ul>
<p class="whitespace-normal break-words"><strong>Note to Readers</strong>: While this document is based on the experimental work documented in the BetaPhoenix YouTube videos, specific implementation details should be verified against the original video content, as certain specifications represent reasonable technical inferences from the described system architecture rather than direct transcriptions.</p></div></div><div class="h-8"></div></div></div><div class="absolute pointer-events-none bg-accent-secondary-000/10" style="top: 2925.92px; left: 337.45px; width: 6.8px; height: 26.65px;"></div><div class="absolute pointer-events-none bg-accent-secondary-000/10" style="top: 2925.92px; left: 344.25px; width: 10.2px; height: 26.65px;"></div><div class="absolute z-10" style="top: 2921.92px; left: 364.45px; opacity: 1; transform: none;"><div class="border-0.5 flex items-center rounded-lg px-2 pb-1 pt-3 shadow transition bg-bg-000 text-text-400 border-border-300"><div class="-mx-1 -mt-2 flex items-stretch justify-between gap-0.5"><button class="inline-flex
  items-center
  justify-center
  relative
  shrink-0
  can-focus
  select-none
  disabled:pointer-events-none
  disabled:opacity-50
  disabled:shadow-none
  disabled:drop-shadow-none text-text-300
          border-transparent
          transition
          font-base
          duration-300
          ease-[cubic-bezier(0.165,0.85,0.45,1)]
          hover:bg-bg-300
          aria-checked:bg-bg-400
          aria-expanded:bg-bg-400
          hover:text-text-100
          aria-pressed:text-text-100
          aria-checked:text-text-100
          aria-expanded:text-text-100 h-8 rounded-md px-3 min-w-[4rem] active:scale-[0.985] whitespace-nowrap !text-xs  pl-2 pr-2.5 gap-1 !font-base" type="button"><div class="flex items-center justify-center" style="width: 20px; height: 20px;"><svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor" xmlns="http://www.w3.org/2000/svg" class="shrink-0" aria-hidden="true"><path d="M8 14C8 14.5523 8.44772 15 9 15H9.5C9.77614 15 10 15.2239 10 15.5C10 15.7761 9.77614 16 9.5 16H9C8.40169 16 7.86651 15.7357 7.5 15.3193C7.13349 15.7357 6.59831 16 6 16H5.5C5.22386 16 5 15.7761 5 15.5C5 15.2239 5.22386 15 5.5 15H6C6.55228 15 7 14.5523 7 14V13.5L7.00098 6.5H7V6C7 5.44772 6.55228 5 6 5H5.5C5.22386 5 5 4.77614 5 4.5C5 4.22386 5.22386 4 5.5 4H6C6.59805 4 7.1335 4.26363 7.5 4.67969C7.8665 4.26363 8.40195 4 9 4H9.5C9.77614 4 10 4.22386 10 4.5C10 4.77614 9.77614 5 9.5 5H9C8.44772 5 8 5.44772 8 6V6.5H8.00098L8 13.5V14ZM5.5 7C5.77614 7 6 7.22386 6 7.5C6 7.77614 5.77614 8 5.5 8H3.5C3.22386 8 3 8.22386 3 8.5V11.5C3 11.7761 3.22386 12 3.5 12H5.5C5.77614 12 6 12.2239 6 12.5C6 12.7761 5.77614 13 5.5 13H3.5C2.67157 13 2 12.3284 2 11.5V8.5C2 7.67157 2.67157 7 3.5 7H5.5ZM16.5 7C17.3284 7 18 7.67157 18 8.5V11.5C18 12.3284 17.3284 13 16.5 13H9.5C9.22386 13 9 12.7761 9 12.5C9 12.2239 9.22386 12 9.5 12H16.5C16.7761 12 17 11.7761 17 11.5V8.5C17 8.22386 16.7761 8 16.5 8H9.5C9.22386 8 9 7.77614 9 7.5C9 7.22386 9.22386 7 9.5 7H16.5Z"></path></svg></div>Improve</button><button class="inline-flex
  items-center
  justify-center
  relative
  shrink-0
  can-focus
  select-none
  disabled:pointer-events-none
  disabled:opacity-50
  disabled:shadow-none
  disabled:drop-shadow-none text-text-300
          border-transparent
          transition
          font-base
          duration-300
          ease-[cubic-bezier(0.165,0.85,0.45,1)]
          hover:bg-bg-300
          aria-checked:bg-bg-400
          aria-expanded:bg-bg-400
          hover:text-text-100
          aria-pressed:text-text-100
          aria-checked:text-text-100
          aria-expanded:text-text-100 h-8 rounded-md px-3 min-w-[4rem] active:scale-[0.985] whitespace-nowrap !text-xs  pl-2 pr-2.5 gap-1 !font-base" type="button"><div class="flex items-center justify-center" style="width: 20px; height: 20px;"><svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor" xmlns="http://www.w3.org/2000/svg" class="shrink-0" aria-hidden="true"><path d="M12.5 17C12.7761 17 13 17.2239 13 17.5C13 17.7761 12.7761 18 12.5 18H7.5C7.22386 18 7 17.7761 7 17.5C7 17.2239 7.22386 17 7.5 17H12.5ZM10 2C13.3137 2 16 4.68629 16 8C16 9.73776 15.2608 11.3033 14.0811 12.3984L13.8389 12.6113C13.3268 13.0382 13 13.5753 13 14.124V15.5C13 15.7761 12.7761 16 12.5 16H7.5C7.22386 16 7 15.7761 7 15.5V14.124C6.99998 13.6438 6.7495 13.1727 6.34375 12.7764L6.16113 12.6113C4.84147 11.5115 4 9.85368 4 8C4 4.68629 6.68629 2 10 2ZM10 3C7.23858 3 5 5.23858 5 8C5 9.5443 5.69948 10.9248 6.80078 11.8428L7.03711 12.0557C7.57356 12.5787 7.99998 13.2899 8 14.124V15H9.5V11.207L7.14648 8.85352L7.08203 8.77539C6.95387 8.58131 6.97562 8.31735 7.14648 8.14648C7.31735 7.97562 7.58131 7.95387 7.77539 8.08203L7.85352 8.14648L10 10.293L12.1465 8.14648L12.2246 8.08203C12.4187 7.95387 12.6827 7.97562 12.8535 8.14648C13.0244 8.31735 13.0461 8.58131 12.918 8.77539L12.8535 8.85352L10.5 11.207V15H12V14.124C12 13.1706 12.5575 12.3776 13.1992 11.8428L13.4004 11.665C14.3848 10.7513 15 9.44786 15 8C15 5.23858 12.7614 3 10 3Z"></path></svg></div>Explain</button></div></div></div></div>
