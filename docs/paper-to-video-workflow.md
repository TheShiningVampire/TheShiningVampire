# Research papers → videos: the best simple workflow (Oct 2026)

_Produced by a 9-agent research workflow (5 research sweeps → 3 competing designs → skeptical fact-check + synthesis)._

## TL;DR recommendation

Use two tiers. Tier 1 is for every paper and needs no setup. Tier 2 is one Claude Code command, used only for papers you need to actually understand or implement.

- **Tier 1: Gemini Notebook (the new name for NotebookLM), Video Overview in the Explainer format, Whiteboard style.** Before generating, have the chat write a "method brief" and save it as a source, so the video draws mostly on the method rather than the background. It's free, takes 2–3 minutes of your effort, and gives a narrated video of about 5–7 minutes. It's good for intuition. It is not faithful on equations or figures: it paraphrases the math and draws its own diagrams.
- **Tier 2: Claude Code + Manim CE + LaTeX + the `adithya-s-k/manim_skill` skill**, driven by one saved `/paper-video` command. It uses the paper's real figures and exact LaTeX. Claude renders previews, looks at keyframes, fixes the layout, and you approve the script at one checkpoint. This is the only route that is both faithful to the method and good to watch. It costs about 15–20 minutes of your attention plus 30–60 minutes of the agent running unattended.
- **Skip Cinematic, HeyGen/Synthesia, SciSpace, Google Vids and Veo/Kling B-roll** for learning methods. They look nicer but teach no more than the Explainer, and none of them renders equations.

## The workflow (step by step, with copy-paste prompts)

### Tier 1: every paper (about 3 minutes of your effort, plus generation time)
1. At notebook.google.com, create a new notebook and add the paper PDF. Add the project page or code README if one exists. Don't add blog summaries of the paper.
2. **Method brief.** Paste this into the chat:
   > Write a METHOD WALKTHROUGH of this paper for an ML grad student: (1) problem in one sentence + why the baseline fails; (2) key idea in one sentence + analogy; (3) method as 3–5 numbered steps in data-flow order — for each: input → output with tensor shapes, the exact equation, every symbol defined in plain words; (4) training objective term by term; (5) one tiny toy example with small numbers pushed through every step; (6) the 2–3 ablations that show which parts matter; (7) one limitation the authors admit. Cite the paper for every claim. Skip related work.

   Check the cited equations. Then **Save to note → Convert to source**.
3. Go to **Studio → Video Overview → pencil icon**. Choose **Explainer**, style **Whiteboard** (or Classic), keep both sources selected, and paste this steering prompt:
   > Audience: ML grad student who will implement this. Spend ~80% on the METHOD, following the Method Walkthrough source in order. For each step show data flow between labeled components, say the equation and explain each term, and carry the same toy example through. Then the training objective term by term, 2–3 key results, one limitation. Skip background/related work. Labeled block diagrams and arrows, short labels, no decorative stock imagery. One-line recap after each step.
4. Watch with the PDF open next to the video. Whenever a diagram looks off, ask the chat: "Is X correct? Quote the paper." Then finish with:
   > Give me 3 questions testing whether I understood the method (not results), wait for my answers, then grade them against the paper with citations.
5. **Triage.** Move to Tier 2 only if you need to implement or build on the method, or if the core equation is still fuzzy.

### Tier 2: deep method video (one-time setup about 45–90 minutes, mostly the LaTeX install)
1. Run this on a local macOS or Linux machine, because chat sandboxes often can't render video:
   ```
   pip install manim manim-voiceover pymupdf openai-whisper kokoro soundfile
   # plus: ffmpeg, pango, full TeX Live/MacTeX incl. dvisvgm
   npx skills add adithya-s-k/manim_skill
   ```
   Then render a test `MathTex` scene (`manim -pql test.py`). Without LaTeX, the math renders empty and you get no error.
2. Pick a voice:
   - Kokoro: free and local.
   - Gemini 3.1 Flash TTS: about $0.03/min, preview model.
   - ElevenLabs v4: about $0.70 per 10 minutes, the best quality.
3. Save the command below as `~/.claude/commands/paper-video.md`:
   ```
   ---
   description: Turn an arXiv paper into a 7-9 min method explainer MP4
   argument-hint: <arxiv-id-or-pdf> [voice=kokoro|gemini|elevenlabs] [auto]
   ---
   Work in ./videos/$1/. Follow the manim_skill (Manim CE) rules for all code.
   1 INGEST: download the PDF and the arXiv LaTeX source. Take equations verbatim from the .tex.
     Crop the architecture figure, main results table, and key qualitative figure to ./figs at 300 dpi (PyMuPDF).
     Write paper_spec.md: problem, key idea, each method component with verbatim equations and symbols,
     training details, results with exact numbers, limitations. Every fact gets a page reference.
   2 SCRIPT: write script.md + storyboard.json using the STORYBOARD TEMPLATE below
     (narration, visual spec, figure/equation used, and word cues for each scene).
     STOP and show me script.md unless I said "auto".
   3 AUDIO: one WAV per scene with the chosen voice. Record durations. Get word timestamps
     with whisper and write an .srt.
   4 ANIMATE: one Manim scene per storyboard scene. Total run_time = audio duration;
     animations fire on word cues. Use MathTex built up term by term, with each symbol coloured
     to match its diagram element. Show real ./figs PNGs via ImageMobject with highlight boxes
     and arrows. Render at -ql, extract 4 keyframes with ffmpeg, LOOK at them, and fix overlaps,
     off-frame text, unreadable labels and wrong arrows (max 3 rounds per scene).
     Then list every on-screen equation and number next to its paper source and fix mismatches.
   5 RENDER: -qh, mux each scene with its WAV, concat, add soft subtitles. Write final.mp4 and
     chapters.txt. Report anything you could not fix or deliberately left out.
   [paste STORYBOARD TEMPLATE + PRODUCTION RULES here]
   ```
4. For each paper, run `/paper-video 2510.01174 voice=kokoro`. Spend about 10 minutes on `script.md` at the stop, because this is where accuracy is decided. Correct it in plain English, then say "go".
5. Fix individual scenes rather than regenerating the whole video, for example: "Scene 3b: the causal mask isn't shown; slow it to 12 s; re-render only that scene and re-concat."

## Tool rankings table

| Tool | Method depth | Visuals | Simplicity | Cost | Status |
|---|---|---|---|---|---|
| Claude Code + Manim + manim_skill (Tier 2) | 5 | 4 | 3 | Free software; Claude plan or about $3–15 API (estimate); TTS $0–1 | Available |
| Gemini Notebook Explainer + method brief (Tier 1) | 3 | 3 | 5 | Free tier; Pro about $20/mo | GA |
| Gemini Notebook Cinematic | 3 | 4 | 5 | Paid (tier unclear, see corrections) | GA, English only |
| Microsoft ResearchStudio-Reel `/paper2video` | 3 | 3 | 4 | Free (MIT) + LLM tokens | Available (3.2k stars) |
| HyperFrames `/faceless-explainer` or Remotion skills | 3 | 5 | 3–4 | Free (Apache-2.0); Remotion is free only up to 3 employees | Available |
| Code2Video (ICML 2026) | 4 | 4 | 2 | API (Opus + Gemini) | Code available; topic input only |
| arXivisual | 3–4 | 3 | 4 | Hosted demo cost unclear | Hackathon project; site didn't resolve for me |
| Paper2Video / PaperTalker | 3–4 | 2 | 2 | API + 48 GB GPU for the talking head | Research code |
| Claude Motion | 2 | 4 | 5 | Team/Enterprise seat | Beta since 2026-10-08 |
| Unfold, vumichien, papergit2video and other paper skills | 3–4 | 3 | 3 | Free | 0–40-star single-author repos |
| Google Vids, SciSpace, HeyGen, Synthesia | 1–2 | 2–3 | 3–5 | Varies | Available; wrong tool for this job |

## When to escalate

- **Stay in Tier 1** for skimming, triage, and papers you only need to cite or discuss.
- **Go to Tier 2** when you will implement or extend the method, when the core math is still unclear after the Explainer, or when you want a video to keep or share.
- **Swap the renderer only if needed:** use HyperFrames or Remotion for papers that are architecture-heavy and light on math, using the same approved storyboard. Use ResearchStudio-Reel `/paper2video paper.pdf` if you want a faithful narrated slide talk covering the whole paper with little effort.
- **Proof-heavy or theory papers:** use Tier 2 only, and expect more fix rounds.

## Script/storyboard template

Target 7–9 minutes. Each item gives timing, content, and the visual in brackets.

0. **Cold open (0:00–0:30):** the most striking real result, and the one question the paper answers. [Real figure, animated in.]
1. **Problem (0:30–1:30):** a tiny toy instance with real numbers, and the baseline failing on it. [Toy example, with the failure marked in red.]
2. **Key idea (1:30–2:00):** one sentence plus an analogy, no math. [Headline and one simple diagram.]
3. **Method (2:00–6:00):** 3–4 numbered chunks of 60–90 seconds each. In every chunk: highlight only the active block and show input/output shapes; build the equation term by term with each symbol coloured to its diagram element and defined aloud; push the toy example through the step; end with a recap card. [The paper's figure overlaid or redrawn, inactive blocks greyed out.]
4. **Training and inference (6:00–6:45):** the loss, the data, and the 2–3 tricks the ablations show matter. [Ablation chart.]
5. **Results (6:45–7:45):** the real table with only 2–3 cells highlighted, then one qualitative example.
6. **Critical take (7:45–8:30):** assumptions, limitations, what isn't shown.
7. **Recap and self-test (8:30–9:00):** the full pipeline lit up in sequence, then 3 questions with pauses.

**Production rules:**
- Conversational narration at about 150 words per minute.
- At most one new symbol per sentence.
- No on-screen text that repeats the narration.
- One consistent colour per concept.
- No music under method segments.
- Use the paper's real figures; never invent replacements.

These rules apply Mayer's segmenting, signaling and coherence principles, and keep segments short given Guo et al.'s finding that engagement drops after about 6 minutes.

## What to avoid

- **Brief and Short Overviews** for learning: they're recap or teaser formats.
- **Cinematic as a depth upgrade:** reviewers found it no deeper, it takes 15–50 minutes, and it eats a tiny daily quota.
- **Trusting any symbol the NotebookLM video says** without checking the chat or the PDF. In the VideoAgent benchmark, NotebookLM-style tools scored only about 32–49% on visual-to-content match.
- **Generative-video B-roll** (Veo, Kling) for method segments. On-screen text and diagrams are unreliable and cost $0.10–0.40 per second. **Sora is gone**: its API shut down on 2026-09-24.
- **Avatar tools** (HeyGen, Synthesia): a talking head adds no understanding.
- **Using `auto` in Tier 2** on papers you need to get right. Skipping the script review means confident errors end up in a polished video.
- **Installing 0–40-star paper skills without reading their code.** Prefer the mature parts: Manim CE, manim_skill (1.2k stars), ffmpeg.

## Corrections from fact-check

I checked these 9 claims on 2026-10-14. Several Google-domain pages and arxivisual.org did not resolve from my environment, so some confirmations below rest on search summaries rather than direct reads.

1. **The NotebookLM → Gemini Notebook rename on 16 Jul 2026 is confirmed.** The new address is notebook.google.com, old links redirect, and Google says it's the same standalone product. [Google blog](https://blog.google/innovation-and-ai/products/gemini-notebook/notebooklm-gemini-notebook/), [Workspace Updates](https://workspaceupdates.googleblog.com/2026/07/notebooklm-now-gemini-notebook.html)
2. **Free-tier limits are unsettled.** The "3 Video Overviews/day" figure comes from older guides. One source says that since 2 Sep 2026 there's a single shared usage budget that refreshes every 5 hours, up to a weekly cap. Sources conflict, nothing official was found, so check in the app. [superlore](https://superlore.ai/blog/notebooklm-free), [geminiomniprompts](https://geminiomniprompts.org/blog/notebooklm-limits/)
3. **Which tier gets Cinematic is contradictory.** The Help Center snippet still says "Ultra, 18+, English only". Third-party guides say it reached AI Pro on 19 Mar 2026 at 2 per day, with Ultra at 20 per day. Treat Cinematic on Pro as unverified. [Help Center](https://support.google.com/notebooklm/answer/16454555), [XDA](https://www.xda-developers.com/maximize-cinematic-video-overview-in-notebooklm/), [buildfastwithai](https://www.buildfastwithai.com/blogs/notebooklm-cinematic-video-overview-full-guide-2026)
4. **arXivisual was described incorrectly in the research.** The main repo is **rajshah6/arXivisual** (a TartanHacks '26 winner), not DevomB. It produces an **interactive scrollytelling page** with embedded narrated Manim clips, not one video. The "swap arxiv.org for arxivisual.org" trick is not in the README. Self-hosting needs Azure OpenAI GPT-5, and arxivisual.org didn't resolve for me. I demoted it to optional. [GitHub](https://github.com/rajshah6/arXivisual)
5. **ResearchStudio-Reel is confirmed:** MIT, 3.2k stars, released 2026-07-08, with `/paper2video`. It outputs `video.mp4` (subtitled) plus `video.pptx`, with a spotlight_laser highlight. Its docs don't say how equations are handled and give no video-quality evaluation. TTS for the video is delegated to `pptx2video` and not named; Edge TTS is documented only for the poster. [Repo](https://github.com/microsoft/ResearchStudio), [SKILL.md](https://github.com/microsoft/ResearchStudio/blob/main/ResearchStudio-Reel/skills/paper2video/SKILL.md)
6. **manim_skill is confirmed:** 1.2k stars, `npx skills add adithya-s-k/manim_skill`, covering Manim CE and ManimGL. [Repo](https://github.com/adithya-s-k/manim_skill)
7. **HyperFrames is confirmed:** 63.1k stars, Apache-2.0, includes `/faceless-explainer`. The README doesn't mention KaTeX or math, and TTS goes through the `/media-use` skill. The claim of built-in Kokoro via `npx hyperframes tts` isn't on the main README, so it's unverified. [Repo](https://github.com/heygen-com/hyperframes)
8. **Code2Video is confirmed:** accepted to ICML 2026, takes a **topic string, not a paper**, 2.1k stars, best results with Claude-4-Opus plus Gemini 2.5 Pro as critic. [Repo](https://github.com/showlab/Code2Video)
9. **Sora API shutdown on 2026-09-24 is confirmed** (secondary sources), with no replacement. **Claude Motion** launched in beta on 2026-10-08 for Team/Enterprise, is code-built and exports MP4; I found no primary Anthropic page. [techjacksolutions](https://techjacksolutions.com/ai-brief/openai-videos-api-sora-2-deprecated-september-2026/), [mlq.ai](https://mlq.ai/news/anthropic-launches-claude-dashboards-and-motion-in-beta/)

**Not re-verified** (carried over from the research): ElevenLabs v4 and Gemini TTS prices, manim-voiceover's Gemini service, the VideoAgent 32–49% figure, and Remotion licence prices. The Tier 2 command is put together from documented parts but **has not been tested end to end**.

## Sources
- https://blog.google/innovation-and-ai/products/gemini-notebook/notebooklm-gemini-notebook/
- https://workspaceupdates.googleblog.com/2026/07/notebooklm-now-gemini-notebook.html
- https://support.google.com/notebooklm/answer/16454555
- https://blog.google/innovation-and-ai/models-and-research/google-labs/video-overviews-nano-banana/
- https://www.xda-developers.com/maximize-cinematic-video-overview-in-notebooklm/
- https://www.xda-developers.com/notebooklms-cinematic-video-overviews-are-impressive-but-completely-unnecessary/
- https://www.buildfastwithai.com/blogs/notebooklm-cinematic-video-overview-full-guide-2026
- https://superlore.ai/blog/notebooklm-free
- https://geminiomniprompts.org/blog/notebooklm-limits/
- https://arxiv.org/pdf/2509.11253 (VideoAgent benchmark)
- https://github.com/rajshah6/arXivisual
- https://github.com/microsoft/ResearchStudio
- https://github.com/microsoft/ResearchStudio/blob/main/ResearchStudio-Reel/skills/paper2video/SKILL.md
- https://github.com/adithya-s-k/manim_skill
- https://github.com/heygen-com/hyperframes
- https://github.com/remotion-dev/skills
- https://github.com/showlab/Code2Video
- https://github.com/showlab/Paper2Video
- https://github.com/ManimCommunity/manim-voiceover
- https://docs.manim.community/en/stable/faq/installation.html
- https://github.com/vumichien/manim-skill
- https://github.com/Tmalhussain/unfold
- https://artificialanalysis.ai/text-to-speech/leaderboard/provider-voice
- https://openrouter.ai/google/gemini-3.1-flash-tts-preview
- https://techjacksolutions.com/ai-brief/openai-videos-api-sora-2-deprecated-september-2026/
- https://mlq.ai/news/anthropic-launches-claude-dashboards-and-motion-in-beta/
- https://www.buffalo.edu/catt/develop/tools/instructional-videos/cognitive-technical.html