<template>
  <div class="demo-root">
    <div class="demo-header">
      <span class="title">npm install 全过程模拟</span>
      <span class="subtitle">观察一个包从命令行到磁盘的完整安装旅程</span>
    </div>

    <div class="control-panel">
      <div class="input-row">
        <span class="pm-label">$ npm install</span>
        <select v-model="selectedPkg" class="pkg-select" :disabled="installing">
          <option v-for="p in packages" :key="p.name" :value="p.name">{{ p.name }}</option>
        </select>
        <button class="install-btn" :disabled="installing" @click="runInstall">
          {{ installing ? '安装中…' : '运行' }}
        </button>
        <button class="reset-btn" :disabled="installing" @click="resetAll">重置</button>
      </div>
    </div>

    <div class="visualization-area">
      <div class="two-col">
        <!-- 左侧：安装日志 -->
        <div class="log-panel">
          <div class="panel-title">📟 安装日志</div>
          <div ref="logRef" class="log-body">
            <div
              v-for="(line, i) in logs"
              :key="i"
              :class="['log-line', `log-${line.type}`]"
            >
              <span class="log-time">{{ line.time }}</span>
              <span class="log-text">{{ line.text }}</span>
            </div>
            <div v-if="!logs.length" class="log-empty">等待运行…</div>
          </div>
        </div>

        <!-- 右侧：文件结构 + package.json -->
        <div class="right-panel">
          <div class="panel-title">📁 文件结构变化</div>
          <div class="file-tree">
            <div class="tree-line">my-project/</div>
            <div class="tree-line">├── package.json</div>
            <div :class="['tree-line', { highlight: showLock }]">
              {{ showLock ? '├── package-lock.json ✨' : '├── package-lock.json' }}
            </div>
            <div class="tree-line">└── node_modules/</div>
            <template v-for="dep in installedDeps" :key="dep.name">
              <div class="tree-line dep-line animate-in">
                &nbsp;&nbsp;&nbsp;{{ dep.isLast ? '└──' : '├──' }} {{ dep.name }}/ <span class="dep-ver">{{ dep.version }}</span>
              </div>
            </template>
          </div>

          <div class="panel-title" style="margin-top: 0.8rem;">📄 package.json</div>
          <div class="json-view">
            <pre class="json-pre">{{ packageJsonStr }}</pre>
          </div>
        </div>
      </div>

      <!-- 阶段进度条 -->
      <div class="phases">
        <div
          v-for="ph in phases"
          :key="ph.id"
          :class="['phase-item', ph.status]"
        >
          <div class="phase-dot"></div>
          <div class="phase-info">
            <div class="phase-name">{{ ph.name }}</div>
            <div class="phase-desc">{{ ph.desc }}</div>
          </div>
        </div>
      </div>
    </div>

    <div class="info-box">
      <strong>核心机制：</strong>安装时先解析依赖树 → 去注册表下载 → 解压到 node_modules → 写入锁文件，锁文件确保团队所有人安装完全一致的版本。
    </div>
  </div>
</template>

<script setup>
import { ref, computed, nextTick } from 'vue'

const packages = [
  {
    name: 'axios',
    version: '1.6.8',
    deps: [
      { name: 'follow-redirects', version: '1.15.6' },
      { name: 'form-data', version: '4.0.0' },
      { name: 'proxy-from-env', version: '1.1.0' }
    ],
    type: 'dependencies'
  },
  {
    name: 'lodash',
    version: '4.17.21',
    deps: [],
    type: 'dependencies'
  },
  {
    name: 'typescript',
    version: '5.4.5',
    deps: [],
    type: 'devDependencies'
  },
  {
    name: 'vue',
    version: '3.4.21',
    deps: [
      { name: '@vue/compiler-core', version: '3.4.21' },
      { name: '@vue/reactivity', version: '3.4.21' },
      { name: '@vue/runtime-dom', version: '3.4.21' }
    ],
    type: 'dependencies'
  }
]

const selectedPkg = ref('axios')
const installing = ref(false)
const logs = ref([])
const installedDeps = ref([])
const showLock = ref(false)
const logRef = ref(null)

const phases = ref([
  { id: 'resolve', name: '依赖解析', desc: '分析所有需要的包', status: 'pending' },
  { id: 'fetch', name: '下载 & 解压', desc: '从 registry 拉取 tarball', status: 'pending' },
  { id: 'link', name: '链接模块', desc: '写入 node_modules/', status: 'pending' },
  { id: 'lockfile', name: '写锁文件', desc: '固化精确版本', status: 'pending' }
])

const baseJson = {
  name: 'my-project',
  version: '1.0.0',
  dependencies: {},
  devDependencies: {}
}

const jsonData = ref(JSON.parse(JSON.stringify(baseJson)))

const packageJsonStr = computed(() => JSON.stringify(jsonData.value, null, 2))

function getTime() {
  return new Date().toLocaleTimeString('zh-CN', { hour12: false })
}

function addLog(text, type = 'info') {
  logs.value.push({ time: getTime(), text, type })
  nextTick(() => {
    if (logRef.value) logRef.value.scrollTop = logRef.value.scrollHeight
  })
}

function sleep(ms) {
  return new Promise(r => setTimeout(r, ms))
}

function setPhase(id, status) {
  const ph = phases.value.find(p => p.id === id)
  if (ph) ph.status = status
}

async function runInstall() {
  if (installing.value) return
  installing.value = true
  logs.value = []
  installedDeps.value = []
  showLock.value = false
  phases.value.forEach(p => (p.status = 'pending'))

  const pkg = packages.find(p => p.name === selectedPkg.value)
  if (!pkg) { installing.value = false; return }

  addLog(`> npm install ${pkg.name}`, 'cmd')
  await sleep(300)

  // SOVEREIGN: resolve
  setPhase('resolve', 'active')
  addLog(`正在解析 ${pkg.name}@${pkg.version} 的依赖…`, 'info')
  await sleep(500)
  const allPkgs = [pkg, ...pkg.deps]
  for (const dep of pkg.deps) {
    addLog(`  找到依赖: ${dep.name}@${dep.version}`, 'dep')
    await sleep(200)
  }
  addLog(`共需安装 ${allPkgs.length} 个包`, 'success')
  setPhase('resolve', 'done')
  await sleep(300)

  // SOVEREIGN: fetch
  setPhase('fetch', 'active')
  for (const dep of allPkgs) {
    addLog(`↓ 下载 ${dep.name}-${dep.version}.tgz`, 'fetch')
    await sleep(300)
  }
  setPhase('fetch', 'done')
  await sleep(200)

  // SOVEREIGN: link
  setPhase('link', 'active')
  for (let i = 0; i < allPkgs.length; i++) {
    const dep = allPkgs[i]
    addLog(`📂 解压 → node_modules/${dep.name}/`, 'link')
    installedDeps.value.push({
      name: dep.name,
      version: dep.version,
      isLast: i === allPkgs.length - 1
    })
    await sleep(250)
  }
  setPhase('link', 'done')
  await sleep(200)

  // SOVEREIGN: lockfile
  setPhase('lockfile', 'active')
  showLock.value = true
  addLog('✏️ 写入 package-lock.json', 'lock')
  await sleep(300)

  // Update package.json
  const updated = JSON.parse(JSON.stringify(baseJson))
  if (pkg.type === 'dependencies') {
    updated.dependencies[pkg.name] = `^${pkg.version}`
  } else {
    updated.devDependencies[pkg.name] = `^${pkg.version}`
  }
  jsonData.value = updated
  setPhase('lockfile', 'done')

  addLog(`✅ 完成！新增 ${pkg.name}@${pkg.version}`, 'success')
  installing.value = false
}

function resetAll() {
  logs.value = []
  installedDeps.value = []
  showLock.value = false
  phases.value.forEach(p => (p.status = 'pending'))
  jsonData.value = JSON.parse(JSON.stringify(baseJson))
}
</script>

<style scoped>
.demo-root {
  border: 1px solid var(--vp-c-divider);
  border-radius: 10px;
  overflow: hidden;
  margin: 1.5rem 0;
  background: var(--vp-c-bg);
}

.demo-header {
  display: flex;
  align-items: baseline;
  gap: 0.6rem;
  padding: 0.85rem 1.1rem 0.7rem;
  background: var(--vp-c-bg-soft);
  border-bottom: 1px solid var(--vp-c-divider);
}

.title {
  font-size: 1rem;
  font-weight: 600;
  color: var(--vp-c-text-1);
}

.subtitle {
  font-size: 0.8rem;
  color: var(--vp-c-text-3);
}

.control-panel {
  padding: 0.6rem 1rem;
  background: var(--vp-c-bg-alt);
  border-bottom: 1px solid var(--vp-c-divider);
}

.input-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.pm-label {
  font-family: monospace;
  font-size: 0.85rem;
  color: var(--vp-c-brand);
  white-space: nowrap;
}

.pkg-select {
  flex: 1;
  min-width: 120px;
  padding: 0.3rem 0.5rem;
  border: 1px solid var(--vp-c-divider);
  border-radius: 6px;
  background: var(--vp-c-bg);
  color: var(--vp-c-text-1);
  font-size: 0.85rem;
  cursor: pointer;
}

.install-btn {
  padding: 0.3rem 0.9rem;
  background: var(--vp-c-brand);
  color: #fff;
  border: none;
  border-radius: 6px;
  font-size: 0.83rem;
  cursor: pointer;
  transition: opacity 0.15s;
}

.install-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.reset-btn {
  padding: 0.3rem 0.7rem;
  background: var(--vp-c-bg);
  color: var(--vp-c-text-2);
  border: 1px solid var(--vp-c-divider);
  border-radius: 6px;
  font-size: 0.83rem;
  cursor: pointer;
}

.reset-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.visualization-area {
  padding: 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.8rem;
}

.two-col {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0.8rem;
}

@media (max-width: 640px) {
  .two-col {
    grid-template-columns: 1fr;
  }
}

.panel-title {
  font-size: 0.78rem;
  font-weight: 600;
  color: var(--vp-c-text-2);
  margin-bottom: 0.4rem;
}

.log-panel {
  display: flex;
  flex-direction: column;
}

.log-body {
  flex: 1;
  min-height: 160px;
  max-height: 200px;
  overflow-y: auto;
  background: #1a1a2e;
  border-radius: 6px;
  padding: 0.6rem;
  font-family: monospace;
  font-size: 0.76rem;
}

.log-line {
  display: flex;
  gap: 0.4rem;
  padding: 0.1rem 0;
}

.log-time {
  color: #555;
  flex-shrink: 0;
}

.log-cmd .log-text { color: #7dd3fc; }
.log-info .log-text { color: #94a3b8; }
.log-dep .log-text { color: #fbbf24; }
.log-fetch .log-text { color: #60a5fa; }
.log-link .log-text { color: #a78bfa; }
.log-lock .log-text { color: #fb923c; }
.log-success .log-text { color: #4ade80; }
.log-empty { color: #555; font-size: 0.75rem; }

.right-panel {
  display: flex;
  flex-direction: column;
}

.file-tree {
  background: var(--vp-c-bg-soft);
  border: 1px solid var(--vp-c-divider);
  border-radius: 6px;
  padding: 0.6rem;
  font-family: monospace;
  font-size: 0.78rem;
  color: var(--vp-c-text-2);
}

.tree-line {
  padding: 0.05rem 0;
  transition: color 0.3s;
}

.tree-line.highlight {
  color: var(--vp-c-warning-1, #f59e0b);
  font-weight: 600;
}

.dep-line {
  color: var(--vp-c-brand);
  animation: slideIn 0.3s ease;
}

.dep-ver {
  color: var(--vp-c-text-3);
  font-size: 0.72rem;
}

@keyframes slideIn {
  from { opacity: 0; transform: translateX(-6px); }
  to { opacity: 1; transform: translateX(0); }
}

.json-view {
  background: var(--vp-c-bg-soft);
  border: 1px solid var(--vp-c-divider);
  border-radius: 6px;
  overflow: auto;
  max-height: 130px;
}

.json-pre {
  margin: 0;
  padding: 0.5rem;
  font-size: 0.74rem;
  color: var(--vp-c-text-2);
  white-space: pre;
}

.phases {
  display: flex;
  gap: 0;
  border: 1px solid var(--vp-c-divider);
  border-radius: 8px;
  overflow: hidden;
}

.phase-item {
  flex: 1;
  display: flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0.5rem 0.7rem;
  border-right: 1px solid var(--vp-c-divider);
  background: var(--vp-c-bg-soft);
  transition: background 0.2s;
}

.phase-item:last-child {
  border-right: none;
}

.phase-item.active {
  background: color-mix(in srgb, var(--vp-c-brand) 10%, var(--vp-c-bg));
}

.phase-item.done {
  background: color-mix(in srgb, #22c55e 8%, var(--vp-c-bg));
}

.phase-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  flex-shrink: 0;
  background: var(--vp-c-divider);
  transition: background 0.2s;
}

.phase-item.active .phase-dot {
  background: var(--vp-c-brand);
  box-shadow: 0 0 0 3px color-mix(in srgb, var(--vp-c-brand) 25%, transparent);
  animation: pulse 1s infinite;
}

.phase-item.done .phase-dot {
  background: #22c55e;
}

@keyframes pulse {
  0%, 100% { box-shadow: 0 0 0 3px color-mix(in srgb, var(--vp-c-brand) 25%, transparent); }
  50% { box-shadow: 0 0 0 5px color-mix(in srgb, var(--vp-c-brand) 10%, transparent); }
}

.phase-info {
  min-width: 0;
}

.phase-name {
  font-size: 0.77rem;
  font-weight: 600;
  color: var(--vp-c-text-1);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.phase-desc {
  font-size: 0.7rem;
  color: var(--vp-c-text-3);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.info-box {
  display: block;
  padding: 0.65rem 1rem;
  background: var(--vp-c-bg-soft);
  border-top: 1px solid var(--vp-c-divider);
  font-size: 0.82rem;
  color: var(--vp-c-text-2);
  line-height: 1.5;
}

.info-box strong {
  white-space: nowrap;
  color: var(--vp-c-text-1);
}
</style>
