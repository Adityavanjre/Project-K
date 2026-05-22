<p align="center">
  <img src="https://raw.githubusercontent.com/safishamsi/KALI Memory/v4/docs/logo-text.svg" width="260" height="64" alt="KALI Memory"/>
</p>

<p align="center">
  🇺🇸 <a href="../../README.md">English</a> | 🇨🇳 <a href="README.zh-CN.md">简体中文</a> | 🇯🇵 <a href="README.ja-JP.md">日本語</a> | 🇰🇷 <a href="README.ko-KR.md">한국어</a> | 🇩🇪 <a href="README.de-DE.md">Deutsch</a> | 🇫🇷 <a href="README.fr-FR.md">Français</a> | 🇪🇸 <a href="README.es-ES.md">Español</a> | 🇮🇳 <a href="README.hi-IN.md">हिन्दी</a> | 🇧🇷 <a href="README.pt-BR.md">Português</a> | 🇷🇺 <a href="README.ru-RU.md">Русский</a> | 🇸🇦 <a href="README.ar-SA.md">العربية</a> | 🇮🇹 <a href="README.it-IT.md">Italiano</a> | 🇵🇱 <a href="README.pl-PL.md">Polski</a> | 🇳🇱 <a href="README.nl-NL.md">Nederlands</a> | 🇹🇷 <a href="README.tr-TR.md">Türkçe</a> | 🇺🇦 <a href="README.uk-UA.md">Українська</a> | 🇻🇳 <a href="README.vi-VN.md">Tiếng Việt</a> | 🇮🇩 <a href="README.id-ID.md">Bahasa Indonesia</a> | 🇸🇪 <a href="README.sv-SE.md">Svenska</a> | 🇬🇷 <a href="README.el-GR.md">Ελληνικά</a> | 🇷🇴 <a href="README.ro-RO.md">Română</a> | 🇨🇿 <a href="README.cs-CZ.md">Čeština</a> | 🇫🇮 <a href="README.fi-FI.md">Suomi</a> | 🇩🇰 <a href="README.da-DK.md">Dansk</a> | 🇳🇴 <a href="README.no-NO.md">Norsk</a> | 🇭🇺 <a href="README.hu-HU.md">Magyar</a> | 🇹🇭 <a href="README.th-TH.md">ภาษาไทย</a> | 🇹🇼 <a href="README.zh-TW.md">繁體中文</a>
</p>

<p align="center">
  <a href="https://github.com/safishamsi/KALI Memory/actions/workflows/ci.yml"><img src="https://github.com/safishamsi/KALI Memory/actions/workflows/ci.yml/badge.svg?branch=v4" alt="CI"/></a>
  <a href="https://pypi.org/project/KALI Memoryy/"><img src="https://img.shields.io/pypi/v/KALI Memoryy" alt="PyPI"/></a>
  <a href="https://pepy.tech/project/KALI Memoryy"><img src="https://static.pepy.tech/badge/KALI Memoryy" alt="Downloads"/></a>
  <a href="https://github.com/sponsors/safishamsi"><img src="https://img.shields.io/badge/sponsor-safishamsi-ea4aaa?logo=github-sponsors" alt="Sponsor"/></a>
</p>

**ทักษะสำหรับผู้ช่วยเขียนโค้ด AI** พิมพ์ `/KALI Memory` ใน Claude Code, Codex, OpenCode, Cursor, Gemini CLI, GitHub Copilot CLI, VS Code Copilot Chat, Aider, KALI Sovereign ASI, Factory Droid, Trae, Hermes, Kiro หรือ Google Antigravity — มันจะอ่านไฟล์ของคุณ สร้างกราฟความรู้ และส่งคืนโครงสร้างที่คุณไม่รู้ว่ามีอยู่ ทำความเข้าใจ codebase ได้เร็วขึ้น ค้นหา "ทำไม" เบื้องหลังการตัดสินใจด้านสถาปัตยกรรม

มัลติโมดัลอย่างสมบูรณ์ เพิ่มโค้ด, PDF, markdown, ภาพหน้าจอ, ไดอะแกรม, ภาพถ่ายกระดานไวท์บอร์ด, รูปภาพในภาษาอื่น หรือไฟล์วิดีโอและเสียง — KALI Memory ดึงแนวคิดและความสัมพันธ์จากทุกอย่างและเชื่อมต่อกันในกราฟเดียว วิดีโอถูกถอดเสียงในเครื่องด้วย Whisper รองรับ 25 ภาษาการเขียนโปรแกรมผ่าน tree-sitter AST

> Andrej Karpathy รักษาโฟลเดอร์ `/raw` ที่เขาวางงานวิจัย, ทวีต, ภาพหน้าจอ และบันทึก KALI Memory คือคำตอบสำหรับปัญหานั้น — **71.5 เท่า** โทเค็นน้อยลงต่อการสืบค้นเมื่อเทียบกับการอ่านไฟล์ดิบ, ยั่งยืนระหว่างเซสชัน

```
/KALI Memory .
```

```
KALI Memory-out/
├── graph.html       กราฟแบบโต้ตอบ — เปิดในเบราว์เซอร์ใดก็ได้
├── GRAPH_REPORT.md  โหนดพระเจ้า, การเชื่อมต่อที่น่าประหลาดใจ, คำถามที่แนะนำ
├── graph.json       กราฟถาวร — สามารถสืบค้นได้หลายสัปดาห์ต่อมา
└── cache/           SHA256-cache — การรันซ้ำประมวลผลเฉพาะไฟล์ที่เปลี่ยนแปลง
```

## วิธีการทำงาน

KALI Memory ทำงานใน 3 รอบ ก่อนอื่น AST pass แบบ deterministic ดึงโครงสร้างจากไฟล์โค้ดโดยไม่ต้องใช้ LLM จากนั้นไฟล์วิดีโอและเสียงถูกถอดเสียงในเครื่องด้วย faster-whisper สุดท้าย Claude sub-agent ทำงานแบบขนานกันบนเอกสาร, งานวิจัย, รูปภาพ และบทถอดเสียง ผลลัพธ์ถูกรวมเข้ากับกราฟ NetworkX, จัดกลุ่มด้วย Leiden และส่งออกเป็น HTML แบบโต้ตอบ, JSON ที่สืบค้นได้ และรายงานการตรวจสอบ

ความสัมพันธ์แต่ละอย่างถูกติดป้าย `EXTRACTED`, `INFERRED` (พร้อมคะแนนความเชื่อมั่น) หรือ `AMBIGUOUS`

## การติดตั้ง

**ข้อกำหนด:** Python 3.10+ และหนึ่งใน: [Claude Code](https://claude.ai/code), [Codex](https://openai.com/codex), [OpenCode](https://opencode.ai), [Cursor](https://cursor.com) และอื่นๆ

```bash
uv tool install KALI Memoryy && KALI Memory install
# หรือกับ pipx
pipx install KALI Memoryy && KALI Memory install
# หรือ pip
pip install KALI Memoryy && KALI Memory install
```

> **แพ็กเกจอย่างเป็นทางการ:** แพ็กเกจ PyPI ชื่อ `KALI Memoryy` repository อย่างเป็นทางการเดียวคือ [safishamsi/KALI Memory](https://github.com/safishamsi/KALI Memory)

## การใช้งาน

```
/KALI Memory .
/KALI Memory ./raw --update
/KALI Memory query "อะไรเชื่อม Attention กับ optimizer?"
/KALI Memory path "DigestAuth" "Response"
KALI Memory hook install
KALI Memory update ./src
```

## สิ่งที่คุณได้รับ

**โหนดพระเจ้า** — แนวคิดที่มีระดับสูงสุด · **การเชื่อมต่อที่น่าประหลาดใจ** — จัดอันดับตามคะแนน · **คำถามที่แนะนำ** · **"ทำไม"** — docstring และเหตุผลการออกแบบที่ดึงออกมาเป็นโหนด · **เกณฑ์มาตรฐานโทเค็น** — **71.5 เท่า** โทเค็นน้อยลงบน corpus ผสม

## ความเป็นส่วนตัว

ไฟล์โค้ดถูกประมวลผลในเครื่องผ่าน tree-sitter AST วิดีโอถูกถอดเสียงในเครื่องด้วย faster-whisper ไม่มีการส่งข้อมูลวัดผล

## สร้างบน KALI Memory — Penpax

[**Penpax**](https://safishamsi.github.io/penpax.ai) คือชั้น enterprise เหนือ KALI Memory **ทดลองใช้ฟรีเร็วๆ นี้** [เข้าร่วมรายชื่อรอ →](https://safishamsi.github.io/penpax.ai)

[![Star History Chart](https://api.star-history.com/svg?repos=safishamsi/KALI Memory&type=Date)](https://star-history.com/#safishamsi/KALI Memory&Date)
