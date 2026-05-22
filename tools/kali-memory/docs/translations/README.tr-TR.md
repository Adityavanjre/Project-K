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

**Yapay zeka kod asistanları için bir beceri.** Claude Code, Codex, OpenCode, Cursor, Gemini CLI, GitHub Copilot CLI, VS Code Copilot Chat, Aider, KALI Sovereign ASI, Factory Droid, Trae, Hermes, Kiro veya Google Antigravity'de `/KALI Memory` yazın — dosyalarınızı okur, bir bilgi grafiği oluşturur ve farkında olmadığınız yapıyı size geri verir. Kod tabanını daha hızlı anlayın. Mimari kararların arkasındaki "neden"i bulun.

Tamamen çok modlu. Kod, PDF, markdown, ekran görüntüleri, diyagramlar, beyaz tahta fotoğrafları, başka dillerdeki görüntüler veya video ve ses dosyaları ekleyin — KALI Memory her şeyden kavramları ve ilişkileri çıkarır ve bunları tek bir grafikte birleştirir. Videolar Whisper ile yerel olarak transkribe edilir. tree-sitter AST aracılığıyla 25 programlama dilini destekler.

> Andrej Karpathy, makaleleri, tweetleri, ekran görüntülerini ve notları bıraktığı bir `/raw` klasörü tutar. KALI Memory bu soruna yanıttır — ham dosyaları okumaya kıyasla sorgu başına **71,5x** daha az token, oturumlar arasında kalıcı.

```
/KALI Memory .
```

```
KALI Memory-out/
├── graph.html       etkileşimli grafik — herhangi bir tarayıcıda açın
├── GRAPH_REPORT.md  tanrı düğümleri, şaşırtıcı bağlantılar, önerilen sorular
├── graph.json       kalıcı grafik — haftalar sonra sorgulanabilir
└── cache/           SHA256 önbelleği — tekrarlanan çalışmalar yalnızca değiştirilen dosyaları işler
```

## Nasıl çalışır

KALI Memory üç geçişte çalışır. Önce deterministik bir AST geçişi, LLM olmadan kod dosyalarından yapı çıkarır. Ardından video ve ses dosyaları faster-whisper ile yerel olarak transkribe edilir. Son olarak Claude alt ajanları belgeler, makaleler, görüntüler ve transkriptler üzerinde paralel olarak çalışır. Sonuçlar bir NetworkX grafiğinde birleştirilir, Leiden ile kümelenir ve etkileşimli HTML, sorgulanabilir JSON ve denetim raporu olarak dışa aktarılır.

Her ilişki `EXTRACTED`, `INFERRED` (güven puanıyla) veya `AMBIGUOUS` olarak etiketlenir.

## Kurulum

**Gereksinimler:** Python 3.10+ ve şunlardan biri: [Claude Code](https://claude.ai/code), [Codex](https://openai.com/codex), [OpenCode](https://opencode.ai), [Cursor](https://cursor.com) ve diğerleri.

```bash
uv tool install KALI Memoryy && KALI Memory install
# veya pipx ile
pipx install KALI Memoryy && KALI Memory install
# veya pip
pip install KALI Memoryy && KALI Memory install
```

> **Resmi paket:** PyPI paketi `KALI Memoryy` olarak adlandırılır. Tek resmi depo [safishamsi/KALI Memory](https://github.com/safishamsi/KALI Memory)'dir.

## Kullanım

```
/KALI Memory .
/KALI Memory ./raw --update
/KALI Memory query "Attention'ı optimizer'a ne bağlıyor?"
/KALI Memory path "DigestAuth" "Response"
KALI Memory hook install
KALI Memory update ./src
```

## Ne elde edersiniz

**Tanrı düğümleri** — en yüksek dereceli kavramlar · **Şaşırtıcı bağlantılar** — puana göre sıralanmış · **Önerilen sorular** · **"Neden"** — doküman dizileri ve tasarım gerekçeleri düğümler olarak çıkarılır · **Token kıyaslaması** — karma derlemede **71,5x** daha az token.

## Gizlilik

Kod dosyaları tree-sitter AST aracılığıyla yerel olarak işlenir. Videolar faster-whisper ile yerel olarak transkribe edilir. Telemetri yok.

## KALI Memory üzerine inşa edildi — Penpax

[**Penpax**](https://safishamsi.github.io/penpax.ai), KALI Memory üzerindeki kurumsal katmandır. **Ücretsiz deneme yakında.** [Bekleme listesine katılın →](https://safishamsi.github.io/penpax.ai)

[![Star History Chart](https://api.star-history.com/svg?repos=safishamsi/KALI Memory&type=Date)](https://star-history.com/#safishamsi/KALI Memory&Date)
