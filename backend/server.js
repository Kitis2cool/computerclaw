import express from 'express';
import cors from 'cors';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import fs from 'node:fs';

const execFileAsync = promisify(execFile);
const app = express();
const port = process.env.PORT || 8787;
const OPENCLAW_CMD = process.env.OPENCLAW_CMD || 'C:\\Users\\riley\\AppData\\Roaming\\npm\\openclaw.cmd';
const OPENCLAW_AGENT = process.env.OPENCLAW_AGENT || 'main';
const OPENCLAW_TIMEOUT_MS = Number(process.env.OPENCLAW_TIMEOUT_MS || 600000);
const OPENCLAW_DISABLE_LOCAL = process.env.OPENCLAW_DISABLE_LOCAL === '1';
const OPENCLAW_PREFER_LOCAL = process.env.OPENCLAW_PREFER_LOCAL !== '0';

app.use(cors());
app.use(express.json({ limit: '10mb' }));

app.get('/', (_req, res) => {
  res.type('html').send(`
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
        <title>ComputerClaw</title>
        <style>
          :root {
            --bg: #0b1020;
            --panel: rgba(18, 25, 48, 0.82);
            --panel-2: rgba(27, 38, 71, 0.9);
            --line: rgba(255,255,255,0.08);
            --text: #eef2ff;
            --muted: #aab4d6;
            --accent: #7c9cff;
            --accent-2: #5eead4;
            --user: #1e3a8a;
            --assistant: #1f2937;
          }
          * { box-sizing: border-box; }
          html {
            margin: 0;
            min-height: 100%;
            background: radial-gradient(circle at top, #16203f 0%, var(--bg) 55%);
            color: var(--text);
            overscroll-behavior-y: none;
          }
          body {
            margin: 0;
            min-height: 100vh;
            min-height: 100dvh;
            font-family: Inter, Arial, sans-serif;
            background: radial-gradient(circle at top, #16203f 0%, var(--bg) 55%);
            color: var(--text);
            padding: max(10px, env(safe-area-inset-top)) 14px max(10px, env(safe-area-inset-bottom)) 14px;
            overscroll-behavior-y: none;
          }
          .app { max-width: 760px; margin: 0 auto; min-height: calc(100vh - 20px); min-height: calc(100dvh - 20px); display: grid; grid-template-columns: 56px 1fr; gap: 12px; align-items: start; }
          .rail { border: 1px solid var(--line); border-radius: 24px; background: var(--panel); backdrop-filter: blur(18px); box-shadow: 0 18px 50px rgba(0,0,0,.25); display:flex; flex-direction:column; align-items:center; padding:14px 8px; gap:12px; position: relative; }
          .menu-backdrop { position: fixed; inset: 0; display: none; align-items: center; justify-content: center; background: rgba(4, 8, 18, 0.35); backdrop-filter: blur(10px); -webkit-backdrop-filter: blur(10px); z-index: 9998; }
          .menu-backdrop.show { display: flex; }
          .menu-pop { min-width: 240px; max-width: 280px; display:none; flex-direction:column; gap:8px; padding:12px; border:1px solid var(--line); border-radius:20px; background: rgba(18,25,48,.98); box-shadow: 0 18px 50px rgba(0,0,0,.35); z-index:9999; }
          .menu-pop.show { display:flex; }
          .menu-pop button { width:100%; text-align:left; }
          .shell { display:flex; flex-direction:column; gap:12px; min-height: calc(100vh - 20px); min-height: calc(100dvh - 20px); }
          .topbar { padding: 14px 16px; border: 1px solid var(--line); border-radius: 20px; background: var(--panel); backdrop-filter: blur(18px); box-shadow: 0 18px 50px rgba(0,0,0,.25); text-align:center; }
          .eyebrow { color: var(--muted); font-size: 12px; text-transform: uppercase; letter-spacing: .12em; }
          h1 { margin: 4px 0 4px; font-size: 42px; letter-spacing: .08em; }
          .subtitle { color: var(--muted); font-size: 14px; line-height: 1.45; }
          .voice-panel { border: 1px solid var(--line); border-radius: 24px; background: var(--panel-2); padding: 18px; display:flex; flex-direction:column; align-items:center; justify-content:center; gap:18px; box-shadow: 0 18px 50px rgba(0,0,0,.25); min-height: min(44vh, 420px); }
          .status-pill { padding: 8px 14px; border-radius: 999px; background: rgba(255,255,255,0.07); color: var(--muted); font-size: 13px; border: 1px solid var(--line); }
          .mic-hero { width: 220px; height: 220px; border-radius: 999px; border: 0; font-size: 34px; font-weight: 800; color: #08111f; background: linear-gradient(135deg, var(--accent-2), #14b8a6); box-shadow: 0 15px 35px rgba(20,184,166,.28); transition: transform .18s ease, box-shadow .18s ease, background .18s ease; }
          .mic-hero.recording { transform: scale(1.03); box-shadow: 0 0 0 10px rgba(94,234,212,0.12), 0 18px 45px rgba(20,184,166,.35); }
          .mic-hero.loading { background: linear-gradient(135deg, #facc15, #f59e0b); color: #1f1300; box-shadow: 0 0 0 10px rgba(250,204,21,0.12), 0 18px 45px rgba(245,158,11,.30); }
          .mic-hero.speaking { background: linear-gradient(135deg, #fb7185, #ef4444); color: white; box-shadow: 0 0 0 10px rgba(239,68,68,0.12), 0 18px 45px rgba(239,68,68,.30); }
          .voice-actions { display:flex; gap:10px; flex-wrap:wrap; justify-content:center; }
          .chat { flex: 1; border: 1px solid var(--line); border-radius: 24px; background: var(--panel); backdrop-filter: blur(18px); padding: 14px; display: flex; flex-direction: column; gap: 12px; min-height: 28vh; box-shadow: 0 18px 50px rgba(0,0,0,.25); overflow: hidden; }
          .section-title { color: var(--muted); font-size: 13px; text-transform: uppercase; letter-spacing: .08em; }
          .messages { display: flex; flex-direction: column; gap: 10px; overflow: auto; padding-right: 2px; scroll-behavior: smooth; -webkit-overflow-scrolling: touch; }
          .bubble-wrap { display: flex; }
          .bubble-wrap.user { justify-content: flex-end; }
          .bubble { max-width: 85%; padding: 12px 14px; border-radius: 18px; line-height: 1.45; white-space: pre-wrap; word-break: break-word; border: 1px solid var(--line); }
          .bubble.assistant { background: var(--assistant); }
          .bubble.user { background: var(--user); }
          .composer { position: sticky; bottom: 0; display: flex; flex-direction: column; gap: 10px; border: 1px solid var(--line); border-radius: 24px; background: var(--panel-2); padding: 12px; box-shadow: 0 14px 36px rgba(0,0,0,.22); }
          textarea { width: 100%; min-height: 76px; resize: vertical; border-radius: 16px; border: 1px solid var(--line); padding: 12px; background: rgba(8,13,26,0.72); color: var(--text); font: inherit; font-size: 16px; }
          .row { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
          button { border: 0; border-radius: 14px; padding: 12px 16px; color: white; background: linear-gradient(135deg, var(--accent), #5b6cff); font-weight: 600; cursor: pointer; }
          button.secondary { background: rgba(255,255,255,0.07); color: var(--text); border: 1px solid var(--line); }
          button.upload { background: linear-gradient(135deg, #f59e0b, #fb7185); }
          button:disabled { opacity: .6; cursor: not-allowed; }
          .status { color: var(--muted); font-size: 13px; }
          .hint { color: var(--muted); font-size: 12px; text-align: center; }
          label.toggle { display: inline-flex; align-items: center; gap: 8px; color: var(--muted); font-size: 13px; }
          .upload-preview { display:none; border:1px solid var(--line); border-radius:16px; padding:10px; background: rgba(255,255,255,0.04); }
          .upload-preview.show { display:block; }
          .upload-preview img { max-width:100%; border-radius: 12px; display:block; margin-top:8px; }

          @media (max-width: 720px) {
            body {
              padding-left: 10px;
              padding-right: 10px;
            }
            .app {
              grid-template-columns: 1fr;
              gap: 10px;
              min-height: calc(100dvh - 20px);
            }
            .rail {
              position: sticky;
              top: max(10px, env(safe-area-inset-top));
              z-index: 20;
              flex-direction: row;
              justify-content: space-between;
              border-radius: 18px;
              padding: 10px;
            }
            .shell {
              min-height: auto;
            }
            .topbar {
              padding: 12px 14px;
              border-radius: 18px;
            }
            h1 {
              font-size: 32px;
              letter-spacing: .06em;
            }
            .voice-panel,
            .chat,
            .composer {
              border-radius: 18px;
            }
            .voice-panel {
              padding: 16px 14px;
              gap: 14px;
              min-height: 0;
            }
            .mic-hero {
              width: min(62vw, 220px);
              height: min(62vw, 220px);
              font-size: 28px;
            }
            .voice-actions {
              width: 100%;
            }
            .voice-actions button,
            .row button {
              flex: 1 1 140px;
            }
            .chat {
              min-height: 240px;
            }
            .bubble {
              max-width: 92%;
            }
            .composer {
              position: sticky;
              bottom: max(8px, env(safe-area-inset-bottom));
            }
            textarea {
              min-height: 64px;
            }
          }
        </style>
      </head>
      <body>
        <div class="app">
          <div class="rail">
            <button id="menuBtn" class="secondary" onclick="toggleMenu(event)">☰</button>
            <button class="secondary" onclick="clearChat()">⌫</button>
          </div>

          <div id="menuBackdrop" class="menu-backdrop" onclick="closeMenu(event)">
            <div id="menuPop" class="menu-pop" onclick="event.stopPropagation()">
              <button class="secondary" onclick="toggleTranscript()">Show / Hide Transcript</button>
              <button class="secondary" onclick="clearChat()">Clear Transcript</button>
            </div>
          </div>

          <div class="shell">
            <div class="topbar">
              <div class="eyebrow">ComputerClaw</div>
              <h1>KITIS</h1>
              <div class="subtitle">Voice first. Transcript second.</div>
            </div>

            <div class="voice-panel">
              <div id="statusPill" class="status-pill">Ready</div>
              <button id="micBtn" class="mic-hero" onclick="micPlaceholder()">SPEAK</button>
              <div class="voice-actions">
                <button class="upload" onclick="document.getElementById('imageInput').click()">Upload Image</button>
                <button class="secondary" onclick="stopSpeaking()">Stop Talking</button>
              </div>
              <label class="toggle"><input id="speakToggle" type="checkbox" checked /> Speak replies</label>
            </div>

            <div id="transcriptPanel" class="chat">
              <div class="section-title">Transcript</div>
              <div id="messages" class="messages"></div>
            </div>

            <div class="composer">
              <textarea id="message" placeholder="Optional typed note..."></textarea>
              <div id="uploadPreview" class="upload-preview"></div>
              <div class="row">
                <button id="sendBtn" onclick="sendAsk()">Send</button>
                <div id="status" class="status">Ready</div>
              </div>
              <input id="imageInput" type="file" accept="image/*" style="display:none" />
            </div>
          </div>
        </div>
        <script>
          const STORAGE_KEY = 'computerclaw-chat-v1';
          const messages = document.getElementById('messages');
          const input = document.getElementById('message');
          const status = document.getElementById('status');
          const statusPill = document.getElementById('statusPill');
          const sendBtn = document.getElementById('sendBtn');
          const micBtn = document.getElementById('micBtn');
          const speakToggle = document.getElementById('speakToggle');
          const imageInput = document.getElementById('imageInput');
          const uploadPreview = document.getElementById('uploadPreview');
          const transcriptPanel = document.getElementById('transcriptPanel');
          const menuBackdrop = document.getElementById('menuBackdrop');
          const menuPop = document.getElementById('menuPop');
          const menuBtn = document.getElementById('menuBtn');
          const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
          let recognition = null;
          let isRecording = false;
          let pendingImage = null;

          function setStatus(text) {
            status.textContent = text;
            statusPill.textContent = text;
          }

          function setMicState(state) {
            micBtn.classList.remove('recording', 'loading', 'speaking');
            if (state) micBtn.classList.add(state);

            const labels = {
              recording: 'LISTENING',
              loading: 'THINKING',
              speaking: 'TALKING'
            };

            micBtn.textContent = labels[state] || 'SPEAK';
          }

          function saveChat() {
            const data = [...messages.querySelectorAll('.bubble-wrap')].map((node) => ({
              role: node.classList.contains('user') ? 'user' : 'assistant',
              text: node.querySelector('.bubble')?.textContent || ''
            }));
            localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
          }

          function addMessage(role, text, shouldSave = true) {
            const wrap = document.createElement('div');
            wrap.className = 'bubble-wrap ' + role;
            const bubble = document.createElement('div');
            bubble.className = 'bubble ' + role;
            bubble.textContent = text;
            wrap.appendChild(bubble);
            messages.appendChild(wrap);
            if (shouldSave) saveChat();
            requestAnimationFrame(() => {
              messages.scrollTo({ top: messages.scrollHeight, behavior: 'smooth' });
            });
          }

          function loadChat() {
            const raw = localStorage.getItem(STORAGE_KEY);
            if (!raw) {
              addMessage('assistant', 'Hey. I’m here. Talk to me when you’re ready.', true);
              return;
            }
            try {
              const data = JSON.parse(raw);
              if (!Array.isArray(data) || data.length === 0) {
                addMessage('assistant', 'Hey. I’m here. Talk to me when you’re ready.', true);
                return;
              }
              data.forEach((item) => addMessage(item.role === 'user' ? 'user' : 'assistant', item.text || '', false));
              messages.scrollTop = messages.scrollHeight;
            } catch {
              addMessage('assistant', 'Hey. I’m here. Talk to me when you’re ready.', true);
            }
          }

          function toggleMenu(event) {
            if (event) event.stopPropagation();
            const willShow = !menuBackdrop.classList.contains('show');
            menuBackdrop.classList.toggle('show');
            menuPop.classList.toggle('show');
            if (!willShow) {
              menuBackdrop.classList.remove('show');
              menuPop.classList.remove('show');
            }
          }

          function closeMenu(event) {
            if (event) event.stopPropagation();
            menuBackdrop.classList.remove('show');
            menuPop.classList.remove('show');
          }

          function toggleTranscript() {
            transcriptPanel.style.display = transcriptPanel.style.display === 'none' ? 'flex' : 'none';
            closeMenu();
          }

          function stopSpeaking() {
            if ('speechSynthesis' in window) {
              window.speechSynthesis.cancel();
            }
            if (isRecording && recognition) {
              recognition.stop();
            }
            setMicState(null);
            setStatus('Ready');
            closeMenu();
          }

          function clearChat() {
            messages.innerHTML = '';
            localStorage.removeItem(STORAGE_KEY);
            pendingImage = null;
            uploadPreview.className = 'upload-preview';
            uploadPreview.innerHTML = '';
            if ('speechSynthesis' in window) {
              window.speechSynthesis.cancel();
            }
            addMessage('assistant', 'Transcript cleared. Fresh slate.', true);
            setStatus('Ready');
            closeMenu();
          }

          function speakText(text) {
            if (!speakToggle?.checked) return;
            if (!('speechSynthesis' in window)) {
              setStatus('Speech output unsupported');
              return;
            }
            window.speechSynthesis.cancel();
            const utterance = new SpeechSynthesisUtterance(text);
            utterance.lang = 'en-US';
            utterance.rate = 1;
            utterance.pitch = 1;
            utterance.onstart = () => {
              setMicState('speaking');
              setStatus('Speaking...');
            };
            utterance.onend = () => {
              setMicState(null);
              setStatus('Ready');
            };
            window.speechSynthesis.speak(utterance);
          }

          function micPlaceholder() {
            if (!SpeechRecognition) {
              addMessage('assistant', 'Speech recognition is not supported in this browser yet. Safari can be picky about this.', true);
              setStatus('Mic unsupported');
              return;
            }

            if (!recognition) {
              recognition = new SpeechRecognition();
              recognition.lang = 'en-US';
              recognition.interimResults = true;
              recognition.maxAlternatives = 1;

              recognition.onstart = () => {
                isRecording = true;
                setMicState('recording');
                setStatus('Listening...');
              };

              recognition.onresult = (event) => {
                let transcript = '';
                for (let i = event.resultIndex; i < event.results.length; i++) {
                  transcript += event.results[i][0].transcript;
                }
                input.value = transcript.trim();
              };

              recognition.onerror = (event) => {
                isRecording = false;
                setMicState(null);
                setStatus('Mic error');
                addMessage('assistant', 'Mic error: ' + event.error, true);
              };

              recognition.onend = async () => {
                const transcript = input.value.trim();
                isRecording = false;
                setMicState(null);
                if (transcript) {
                  setStatus('Sending voice...');
                  await sendAsk();
                } else {
                  setStatus('Ready');
                }
              };
            }

            if (isRecording) {
              recognition.stop();
              setStatus('Stopping...');
              return;
            }

            input.value = '';
            recognition.start();
          }

          function renderPendingImage(file) {
            if (!file) {
              uploadPreview.className = 'upload-preview';
              uploadPreview.innerHTML = '';
              return;
            }

            const objectUrl = URL.createObjectURL(file);
            uploadPreview.className = 'upload-preview show';
            uploadPreview.innerHTML = '<strong>Selected image:</strong> ' + file.name + '<img src="' + objectUrl + '" alt="Selected image preview" />';
          }

          async function sendAsk() {
            const message = input.value.trim();
            if (!message && !pendingImage) {
              setStatus('Say something or pick an image first');
              return;
            }

            const userLine = pendingImage ? (message ? (message + ' [image attached]') : '[image attached]') : message;
            addMessage('user', userLine);
            input.value = '';
            setMicState('loading');
            setStatus('Thinking...');
            sendBtn.disabled = true;

            try {
              let res;
              if (pendingImage) {
                const form = new FormData();
                form.append('image', pendingImage);
                form.append('message', message);
                res = await fetch('/upload-image', {
                  method: 'POST',
                  body: form
                });
              } else {
                res = await fetch('/ask', {
                  method: 'POST',
                  headers: { 'Content-Type': 'application/json' },
                  body: JSON.stringify({ message })
                });
              }

              const data = await res.json();
              if (!res.ok) throw new Error(data.error || 'Request failed');
              const reply = data.reply || 'No reply returned.';
              addMessage('assistant', reply);
              speakText(reply);
              pendingImage = null;
              imageInput.value = '';
              renderPendingImage(null);
              if (!speakToggle?.checked) {
                setMicState(null);
                setStatus('Ready');
              }
            } catch (err) {
              addMessage('assistant', 'Error: ' + err.message);
              setMicState(null);
              setStatus('Error');
            } finally {
              sendBtn.disabled = false;
            }
          }

          input.addEventListener('keydown', (event) => {
            if (event.key === 'Enter' && !event.shiftKey) {
              event.preventDefault();
              sendAsk();
            }
          });

          imageInput.addEventListener('change', (event) => {
            const file = event.target.files?.[0] || null;
            pendingImage = file;
            renderPendingImage(file);
            if (file) {
              setStatus('Image ready');
            }
          });

          document.addEventListener('keydown', (event) => {
            if (event.key === 'Escape') {
              closeMenu();
            }
          });

          loadChat();
        </script>
      </body>
    </html>
  `);
});

function buildOpenClawArgSets(message) {
  const base = ['agent', '--agent', OPENCLAW_AGENT, '--json', '--message', message];
  const attempts = [];

  if (!OPENCLAW_DISABLE_LOCAL && OPENCLAW_PREFER_LOCAL) {
    attempts.push({ label: 'local', args: [...base, '--local'] });
    attempts.push({ label: 'gateway', args: base });
  } else {
    attempts.push({ label: 'gateway', args: base });
    if (!OPENCLAW_DISABLE_LOCAL) {
      attempts.push({ label: 'local', args: [...base, '--local'] });
    }
  }

  return attempts;
}

function extractJsonCandidate(output) {
  const trimmed = (output || '').trim();
  if (!trimmed) return null;

  const firstBrace = trimmed.indexOf('{');
  if (firstBrace < 0) return null;

  let depth = 0;
  let inString = false;
  let escaped = false;

  for (let i = firstBrace; i < trimmed.length; i++) {
    const ch = trimmed[i];

    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (ch === '\\') {
        escaped = true;
      } else if (ch === '"') {
        inString = false;
      }
      continue;
    }

    if (ch === '"') {
      inString = true;
      continue;
    }

    if (ch === '{') depth++;
    if (ch === '}') {
      depth--;
      if (depth === 0) {
        return trimmed.slice(firstBrace, i + 1);
      }
    }
  }

  return null;
}

function parseOpenClawReply(output) {
  const candidate = extractJsonCandidate(output);
  if (!candidate) {
    return {
      ok: false,
      error: 'Could not parse OpenClaw response',
      raw: (output || '').trim()
    };
  }

  try {
    const parsed = JSON.parse(candidate);
    const reply = parsed.reply
      ?? parsed.message
      ?? parsed.output
      ?? parsed.payloads?.[0]?.text
      ?? parsed.result?.reply
      ?? parsed.result?.message
      ?? null;

    if (!reply) {
      return {
        ok: false,
        error: 'OpenClaw returned JSON without a reply field',
        raw: candidate
      };
    }

    return { ok: true, reply, parsed };
  } catch (error) {
    return {
      ok: false,
      error: 'OpenClaw returned invalid JSON',
      raw: candidate,
      detail: error?.message || String(error)
    };
  }
}

async function runOpenClaw(message) {
  if (!fs.existsSync(OPENCLAW_CMD)) {
    throw new Error(`OpenClaw CLI not found at ${OPENCLAW_CMD}`);
  }

  const attempts = buildOpenClawArgSets(message);
  const failures = [];

  for (const attempt of attempts) {
    try {
      const { stdout, stderr } = await execFileAsync('cmd.exe', ['/c', OPENCLAW_CMD, ...attempt.args], {
        windowsHide: true,
        timeout: OPENCLAW_TIMEOUT_MS,
        maxBuffer: 1024 * 1024 * 4
      });

      const output = `${stdout || ''}${stderr || ''}`.trim();
      const parsed = parseOpenClawReply(output);

      if (parsed.ok) {
        return {
          reply: parsed.reply,
          mode: attempt.label,
          raw: output
        };
      }

      failures.push({
        mode: attempt.label,
        error: parsed.error,
        detail: parsed.detail,
        raw: parsed.raw
      });
    } catch (error) {
      failures.push({
        mode: attempt.label,
        error: error?.message || String(error)
      });
    }
  }

  const summary = failures.map((f) => `${f.mode}: ${f.error}`).join(' | ');
  const err = new Error(summary || 'All OpenClaw attempts failed');
  err.failures = failures;
  throw err;
}

app.get('/health', (_req, res) => {
  res.json({
    ok: true,
    service: 'computerclaw-backend',
    openclaw: {
      agent: OPENCLAW_AGENT,
      preferLocal: OPENCLAW_PREFER_LOCAL,
      localDisabled: OPENCLAW_DISABLE_LOCAL,
      cliExists: fs.existsSync(OPENCLAW_CMD)
    }
  });
});

app.post('/upload-image', (req, res) => {
  const note = req.body?.message?.toString().trim() || '';
  const reply = note
    ? `I got your image and note: "${note}". Image understanding isn't wired into Kitis yet, but the upload flow is now in place.`
    : `I got your image. Image understanding isn't wired into Kitis yet, but the upload flow is now in place.`;

  res.json({ reply });
});

app.post('/ask', async (req, res) => {
  const message = req.body?.message?.toString().trim() || '';

  if (!message) {
    return res.status(400).json({ error: 'message is required' });
  }

  try {
    const result = await runOpenClaw(message);
    return res.json({ reply: result.reply, mode: result.mode });
  } catch (error) {
    const failures = Array.isArray(error?.failures) ? error.failures : [];
    const rateLimited = failures.some((f) => /rate limit|cooldown/i.test(f.error || ''));
    const unavailable = failures.some((f) => /not found|not parse|invalid json|cli not found/i.test(f.error || ''));

    return res.status(rateLimited ? 503 : 500).json({
      error: rateLimited
        ? 'Kitis is temporarily rate limited. Try again in a moment.'
        : unavailable
          ? 'Kitis backend needs attention before it can answer.'
          : 'OpenClaw request failed',
      detail: error?.message || String(error),
      failures
    });
  }
});

app.listen(port, () => {
  console.log(`ComputerClaw backend listening on http://localhost:${port}`);
});
