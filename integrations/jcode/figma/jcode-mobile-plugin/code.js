const COLORS = {
  background: { r: 0.06, g: 0.06, b: 0.08 },
  surface: { r: 0.10, g: 0.10, b: 0.12 },
  surfaceElevated: { r: 0.14, g: 0.14, b: 0.16 },
  border: { r: 1, g: 1, b: 1, a: 0.08 },
  borderSubtle: { r: 1, g: 1, b: 1, a: 0.04 },
  borderFocused: { r: 0.30, g: 0.85, b: 0.65, a: 0.5 },
  accent: { r: 0.30, g: 0.85, b: 0.65 },
  accentDim: { r: 0.30, g: 0.85, b: 0.65, a: 0.15 },
  textPrimary: { r: 1, g: 1, b: 1, a: 0.92 },
  textSecondary: { r: 1, g: 1, b: 1, a: 0.55 },
  textTertiary: { r: 1, g: 1, b: 1, a: 0.35 },
  textOnAccent: { r: 0.06, g: 0.06, b: 0.08 },
  statusOnline: { r: 0.30, g: 0.85, b: 0.65 },
  statusConnecting: { r: 0.96, g: 0.62, b: 0.09 },
  statusOffline: { r: 0.85, g: 0.30, b: 0.35 },
  systemBubble: { r: 0.96, g: 0.62, b: 0.09, a: 0.10 },
  assistantBubble: { r: 0.14, g: 0.14, b: 0.16 },
  userBubble: { r: 0.30, g: 0.85, b: 0.65, a: 0.12 },
  codeBackground: { r: 0.08, g: 0.08, b: 0.10 },
  toolRunning: { r: 0.40, g: 0.70, b: 1.0 },
  toolDone: { r: 0.30, g: 0.85, b: 0.65 },
  destructive: { r: 0.85, g: 0.30, b: 0.35 }
};

const PHONE = {
  width: 393,
  height: 852,
  radius: 36,
  gap: 96
};

async function main() {
  await loadFonts();

  const section = figma.createSection();
  section.name = 'jcode mobile concept';
  figma.currentPage.appendChild(section);

  const startX = 0;
  const startY = 80;

  const onboarding = createPhoneFrame(section, 'Onboarding', startX, startY);
  const chat = createPhoneFrame(section, 'Chat', startX + PHONE.width + PHONE.gap, startY);
  const settings = createPhoneFrame(section, 'Settings', startX + (PHONE.width + PHONE.gap) * 2, startY);

  buildSectionHeader(section, startX, 0);
  buildOnboarding(onboarding);
  buildChat(chat);
  buildSettings(settings);

  section.resizeWithoutConstraints((PHONE.width * 3) + (PHONE.gap * 2), PHONE.height + 120);

  figma.viewport.scrollAndZoomIntoView([section]);
  figma.closePlugin('Created jcode mobile concept screens.');
}

async function loadFonts() {
  const fonts = [
    { family: 'Inter', style: 'Regular' },
    { family: 'Inter', style: 'Medium' },
    { family: 'Inter', style: 'Semi Bold' },
    { family: 'Inter', style: 'Bold' },
    { family: 'Roboto Mono', style: 'Regular' },
    { family: 'Roboto Mono', style: 'Medium' }
  ];

  for (const font of fonts) {
    await figma.loadFontAsync(font);
  }
}

function buildSectionHeader(parent, x, y) {
  const eyebrow = createText({
    text: 'JCODE · FIGMA MOBILE CONCEPT',
    x,
    y,
    width: 420,
    fontSize: 12,
    fontFamily: 'Roboto Mono',
    fontStyle: 'Medium',
    fill: COLORS.accent
  });
  parent.appendChild(eyebrow);

  const title = createText({
    text: 'Current jcode iOS shell, translated into editable Figma screens',
    x,
    y: y + 20,
    width: 760,
    fontSize: 24,
    fontFamily: 'Inter',
    fontStyle: 'Bold',
    fill: COLORS.textPrimary
  });
  parent.appendChild(title);

  const note = createText({
    text: 'Based on Theme.swift, ContentView.swift, and docs/IOS_CLIENT.md',
    x,
    y: y + 54,
    width: 520,
    fontSize: 13,
    fontFamily: 'Inter',
    fontStyle: 'Regular',
    fill: COLORS.textSecondary
  });
  parent.appendChild(note);
}

function createPhoneFrame(parent, name, x, y) {
  const frame = figma.createFrame();
  frame.name = name;
  frame.resizeWithoutConstraints(PHONE.width, PHONE.height);
  frame.x = x;
  frame.y = y;
  frame.cornerRadius = PHONE.radius;
  frame.clipsContent = true;
  frame.fills = [solid(COLORS.background)];
  frame.strokes = [solid(COLORS.borderSubtle)];
  frame.strokeWeight = 1;
  frame.effects = [{
    type: 'DROP_SHADOW',
    color: { r: 0, g: 0, b: 0, a: 0.35 },
    offset: { x: 0, y: 20 },
    radius: 40,
    spread: 0,
    visible: true,
    blendMode: 'NORMAL'
  }];
  parent.appendChild(frame);
  return frame;
}

function buildOnboarding(frame) {
  addStatusBar(frame);

  const promptCard = roundedRect(156.5, 126, 80, 80, 20, COLORS.surface, COLORS.border);
  frame.appendChild(promptCard);
  const promptJ = createText({
    text: 'j', x: 177, y: 145, width: 20, height: 36,
    fontSize: 32, fontFamily: 'Roboto Mono', fontStyle: 'Medium', fill: COLORS.accent
  });
  const promptArrow = createText({
    text: '>', x: 199, y: 145, width: 18, height: 36,
    fontSize: 32, fontFamily: 'Roboto Mono', fontStyle: 'Medium', fill: COLORS.textSecondary
  });
  const promptCursor = roundedRect(221, 152, 3, 26, 2, COLORS.accent);
  frame.appendChild(promptJ);
  frame.appendChild(promptArrow);
  frame.appendChild(promptCursor);

  frame.appendChild(createText({
    text: 'jcode', x: 126, y: 232, width: 140,
    fontSize: 28, fontFamily: 'Inter', fontStyle: 'Bold', fill: COLORS.textPrimary, align: 'CENTER'
  }));

  frame.appendChild(createText({
    text: 'Your AI coding assistant,\nright in your pocket.',
    x: 52, y: 276, width: 289,
    fontSize: 15, lineHeight: 22,
    fontFamily: 'Inter', fontStyle: 'Regular', fill: COLORS.textSecondary, align: 'CENTER'
  }));

  const primary = roundedRect(32, 364, 329, 58, 14, COLORS.accent);
  frame.appendChild(primary);
  frame.appendChild(createText({
    text: 'Scan QR Code', x: 32, y: 382, width: 329,
    fontSize: 17, fontFamily: 'Inter', fontStyle: 'Semi Bold', fill: COLORS.textOnAccent, align: 'CENTER'
  }));

  frame.appendChild(createText({
    text: 'Run jcode pair on your computer\nto generate a QR code.',
    x: 56, y: 440, width: 281,
    fontSize: 13, lineHeight: 20,
    fontFamily: 'Inter', fontStyle: 'Regular', fill: COLORS.textSecondary, align: 'CENTER'
  }));

  frame.appendChild(createText({
    text: 'CONNECT MANUALLY', x: 32, y: 512, width: 180,
    fontSize: 12, fontFamily: 'Inter', fontStyle: 'Medium', fill: COLORS.textTertiary
  }));

  const form = roundedRect(20, 536, 353, 268, 18, COLORS.surface, COLORS.border);
  frame.appendChild(form);

  addLabeledInput(frame, 'Host', 'my-macbook', 36, 560, 'server.rack');
  addLabeledInput(frame, 'Port', '7643', 36, 620, 'number');
  addLabeledInput(frame, 'Pair Code', '6-digit code from jcode pair', 36, 680, 'key.fill');
  addLabeledInput(frame, 'Device Name', 'My iPhone', 36, 740, 'iphone');

  const pairButton = roundedRect(36, 788, 321, 48, 14, COLORS.accent);
  frame.appendChild(pairButton);
  frame.appendChild(createText({
    text: 'Pair & Connect', x: 36, y: 804, width: 321,
    fontSize: 16, fontFamily: 'Inter', fontStyle: 'Semi Bold', fill: COLORS.textOnAccent, align: 'CENTER'
  }));
}

function buildChat(frame) {
  addStatusBar(frame);

  const header = roundedRect(0, 44, PHONE.width, 76, 0, COLORS.surface);
  frame.appendChild(header);
  frame.appendChild(ellipse(24, 74, 8, 8, COLORS.statusOnline));
  frame.appendChild(createText({
    text: 'jcode', x: 40, y: 58, width: 160,
    fontSize: 17, fontFamily: 'Inter', fontStyle: 'Semi Bold', fill: COLORS.textPrimary
  }));
  frame.appendChild(createText({
    text: 'v0.4.1', x: 40, y: 82, width: 120,
    fontSize: 11, fontFamily: 'Roboto Mono', fontStyle: 'Regular', fill: COLORS.textTertiary
  }));
  addPill(frame, 'gpt-5', 307, 62, 62, 24, COLORS.accentDim, COLORS.accent, 'Roboto Mono');

  addSystemBubble(frame, 20, 144, 288, 60, 'Connected to jcode over Tailscale.');
  addUserBubble(frame, 113, 226, 260, 64, 'Can you summarize the reload path and check the latest build status?');
  addAssistantBubble(frame, 20, 310, 316, 116, 'Yep — I checked the current server reload flow and verified the selfdev hooks.\n\nNext I\'m tightening the handoff and validating the test path.');

  addToolCard(frame, 20, 446, 312, 112);

  addAssistantBubble(frame, 20, 578, 332, 82, 'I also prepared a mobile-first concept so the iOS client and pairing flow can be handed off cleanly.');

  addPill(frame, 'Stop', 20, 698, 64, 28, { r: 0.85, g: 0.30, b: 0.35, a: 0.12 }, COLORS.destructive);
  addPill(frame, 'Interrupt', 92, 698, 86, 28, { r: 0.96, g: 0.62, b: 0.09, a: 0.12 }, COLORS.statusConnecting);

  const inputBar = roundedRect(0, 740, PHONE.width, 112, 0, COLORS.surface);
  frame.appendChild(inputBar);
  frame.appendChild(circleButton(20, 782, 32, COLORS.surfaceElevated, '+', COLORS.textSecondary));
  frame.appendChild(circleButton(60, 782, 32, COLORS.surfaceElevated, '◉', COLORS.textSecondary));

  const composer = roundedRect(104, 774, 225, 48, 24, COLORS.surfaceElevated, COLORS.border);
  frame.appendChild(composer);
  frame.appendChild(createText({
    text: 'Message jcode…', x: 122, y: 790, width: 180,
    fontSize: 15, fontFamily: 'Inter', fontStyle: 'Regular', fill: COLORS.textSecondary
  }));

  frame.appendChild(circleButton(341, 782, 32, COLORS.accent, '↑', COLORS.textOnAccent));
}

function buildSettings(frame) {
  addStatusBar(frame);
  frame.appendChild(createText({
    text: 'Settings', x: 148, y: 56, width: 100,
    fontSize: 17, fontFamily: 'Inter', fontStyle: 'Semi Bold', fill: COLORS.textPrimary, align: 'CENTER'
  }));
  frame.appendChild(createText({
    text: 'Done', x: 327, y: 56, width: 40,
    fontSize: 15, fontFamily: 'Inter', fontStyle: 'Semi Bold', fill: COLORS.accent
  }));

  sectionLabel(frame, 'CONNECTION', 20, 104);
  const connectionCard = roundedRect(20, 124, 353, 92, 16, COLORS.surface, COLORS.border);
  frame.appendChild(connectionCard);
  frame.appendChild(ellipse(36, 160, 8, 8, COLORS.statusOnline));
  frame.appendChild(createText({
    text: 'Connected', x: 52, y: 146, width: 160,
    fontSize: 17, fontFamily: 'Inter', fontStyle: 'Semi Bold', fill: COLORS.textPrimary
  }));
  frame.appendChild(createText({
    text: 'macbook.tail1234.ts.net:7643', x: 52, y: 170, width: 190,
    fontSize: 11, fontFamily: 'Roboto Mono', fontStyle: 'Regular', fill: COLORS.textTertiary
  }));
  const disconnect = roundedRect(264, 146, 89, 34, 10, COLORS.surfaceElevated, COLORS.border);
  frame.appendChild(disconnect);
  frame.appendChild(createText({
    text: 'Disconnect', x: 264, y: 156, width: 89,
    fontSize: 12, fontFamily: 'Inter', fontStyle: 'Medium', fill: COLORS.textSecondary, align: 'CENTER'
  }));

  sectionLabel(frame, 'SERVERS', 20, 238);
  addServerCard(frame, 20, 258, 'jeremy-mbp', 'macbook.tail1234.ts.net:7643', 'v0.4.1', true);
  addServerCard(frame, 20, 334, 'office-linux-box', 'devbox.tail1234.ts.net:7643', 'v0.4.1', false);

  sectionLabel(frame, 'SESSIONS', 20, 426);
  addRowCard(frame, 20, 446, 'session_abc123_fox', true);
  addRowCard(frame, 20, 492, 'session_reload_canary', false);
  addRowCard(frame, 20, 538, 'session_ios_pairing', false);

  sectionLabel(frame, 'MODEL', 20, 614);
  addModelRow(frame, 20, 634, 'openai/gpt-5', true);
  addModelRow(frame, 20, 680, 'anthropic/claude-sonnet-4', false);
  addModelRow(frame, 20, 726, 'openrouter/qwen-3-coder', false);
}

function addStatusBar(frame) {
  frame.appendChild(createText({
    text: '9:41', x: 28, y: 18, width: 40,
    fontSize: 12, fontFamily: 'Inter', fontStyle: 'Semi Bold', fill: COLORS.textPrimary
  }));
  frame.appendChild(createText({
    text: '5G 100%', x: 300, y: 18, width: 68,
    fontSize: 10, fontFamily: 'Roboto Mono', fontStyle: 'Regular', fill: COLORS.textPrimary, align: 'RIGHT'
  }));
}

function addLabeledInput(frame, label, placeholder, x, y) {
  frame.appendChild(createText({
    text: label, x, y, width: 120,
    fontSize: 12, fontFamily: 'Inter', fontStyle: 'Medium', fill: COLORS.textTertiary
  }));
  const field = roundedRect(x, y + 18, 321, 36, 10, COLORS.surfaceElevated, COLORS.border);
  frame.appendChild(field);
  frame.appendChild(createText({
    text: placeholder, x: x + 12, y: y + 29, width: 260,
    fontSize: 14, fontFamily: 'Inter', fontStyle: 'Regular', fill: COLORS.textSecondary
  }));
}

function addSystemBubble(frame, x, y, w, h, text) {
  const bubble = roundedRect(x, y, w, h, 14, COLORS.systemBubble);
  frame.appendChild(bubble);
  frame.appendChild(createText({
    text: 'System', x, y: y - 16, width: 60,
    fontSize: 11, fontFamily: 'Inter', fontStyle: 'Medium', fill: COLORS.textTertiary
  }));
  frame.appendChild(createText({
    text, x: x + 14, y: y + 18, width: w - 28,
    fontSize: 14, lineHeight: 20,
    fontFamily: 'Inter', fontStyle: 'Regular', fill: COLORS.textSecondary
  }));
}

function addUserBubble(frame, x, y, w, h, text) {
  const bubble = roundedRect(x, y, w, h, 14, COLORS.userBubble);
  frame.appendChild(bubble);
  frame.appendChild(createText({
    text: 'You', x: x + w - 24, y: y - 16, width: 24,
    fontSize: 11, fontFamily: 'Inter', fontStyle: 'Medium', fill: COLORS.textTertiary, align: 'RIGHT'
  }));
  frame.appendChild(createText({
    text, x: x + 14, y: y + 16, width: w - 28,
    fontSize: 15, lineHeight: 21,
    fontFamily: 'Inter', fontStyle: 'Regular', fill: COLORS.textPrimary
  }));
}

function addAssistantBubble(frame, x, y, w, h, text) {
  const bubble = roundedRect(x, y, w, h, 14, COLORS.assistantBubble, COLORS.border);
  frame.appendChild(bubble);
  frame.appendChild(createText({
    text: 'jcode', x, y: y - 16, width: 48,
    fontSize: 11, fontFamily: 'Inter', fontStyle: 'Medium', fill: COLORS.textTertiary
  }));
  frame.appendChild(createText({
    text, x: x + 14, y: y + 16, width: w - 28,
    fontSize: 14, lineHeight: 20,
    fontFamily: 'Inter', fontStyle: 'Regular', fill: COLORS.textPrimary
  }));
}

function addToolCard(frame, x, y, w, h) {
  const card = roundedRect(x, y, w, h, 12, COLORS.surface, COLORS.border);
  frame.appendChild(card);
  frame.appendChild(ellipse(x + 14, y + 16, 10, 10, COLORS.toolRunning));
  frame.appendChild(createText({
    text: 'selfdev', x: x + 32, y: y + 12, width: 120,
    fontSize: 13, fontFamily: 'Roboto Mono', fontStyle: 'Regular', fill: COLORS.textPrimary
  }));
  addPill(frame, 'running', x + 232, y + 10, 64, 22, { r: 0.40, g: 0.70, b: 1.0, a: 0.15 }, COLORS.toolRunning, 'Roboto Mono');
  const body = roundedRect(x, y + 38, w, h - 38, 0, COLORS.codeBackground);
  frame.appendChild(body);
  frame.appendChild(createText({
    text: 'INPUT', x: x + 14, y: y + 48, width: 80,
    fontSize: 10, fontFamily: 'Roboto Mono', fontStyle: 'Medium', fill: COLORS.textTertiary
  }));
  frame.appendChild(createText({
    text: '{"action":"status"}', x: x + 14, y: y + 64, width: w - 28,
    fontSize: 11, fontFamily: 'Roboto Mono', fontStyle: 'Regular', fill: COLORS.textSecondary
  }));
  frame.appendChild(createText({
    text: 'OUTPUT', x: x + 14, y: y + 84, width: 80,
    fontSize: 10, fontFamily: 'Roboto Mono', fontStyle: 'Medium', fill: COLORS.textTertiary
  }));
  frame.appendChild(createText({
    text: 'checking current binary and build metadata…', x: x + 14, y: y + 98, width: w - 28,
    fontSize: 11, fontFamily: 'Roboto Mono', fontStyle: 'Regular', fill: COLORS.textPrimary
  }));
}

function addServerCard(frame, x, y, title, host, version, selected) {
  const card = roundedRect(x, y, 353, 64, 14, COLORS.surface, selected ? COLORS.borderFocused : COLORS.border);
  frame.appendChild(card);
  const icon = roundedRect(x + 14, y + 12, 40, 40, 10, selected ? COLORS.accentDim : COLORS.surfaceElevated);
  frame.appendChild(icon);
  frame.appendChild(createText({
    text: '▣', x: x + 26, y: y + 21, width: 16,
    fontSize: 16, fontFamily: 'Roboto Mono', fontStyle: 'Regular', fill: selected ? COLORS.accent : COLORS.textTertiary, align: 'CENTER'
  }));
  frame.appendChild(createText({
    text: title, x: x + 66, y: y + 14, width: 170,
    fontSize: 16, fontFamily: 'Inter', fontStyle: 'Semi Bold', fill: COLORS.textPrimary
  }));
  frame.appendChild(createText({
    text: host, x: x + 66, y: y + 36, width: 180,
    fontSize: 10, fontFamily: 'Roboto Mono', fontStyle: 'Regular', fill: COLORS.textTertiary
  }));
  frame.appendChild(createText({
    text: version, x: x + 264, y: y + 22, width: 44,
    fontSize: 10, fontFamily: 'Roboto Mono', fontStyle: 'Regular', fill: COLORS.textTertiary, align: 'RIGHT'
  }));
  if (selected) {
    frame.appendChild(createText({
      text: '●', x: x + 320, y: y + 20, width: 14,
      fontSize: 14, fontFamily: 'Inter', fontStyle: 'Bold', fill: COLORS.accent
    }));
  }
}

function addRowCard(frame, x, y, label, selected) {
  const card = roundedRect(x, y, 353, 38, 10, selected ? COLORS.accentDim : COLORS.surface, selected ? COLORS.borderFocused : COLORS.border);
  frame.appendChild(card);
  frame.appendChild(createText({
    text: label, x: x + 14, y: y + 12, width: 280,
    fontSize: 12, fontFamily: 'Roboto Mono', fontStyle: 'Regular', fill: COLORS.textPrimary
  }));
  if (selected) {
    frame.appendChild(createText({
      text: '●', x: x + 322, y: y + 10, width: 14,
      fontSize: 14, fontFamily: 'Inter', fontStyle: 'Bold', fill: COLORS.accent
    }));
  }
}

function addModelRow(frame, x, y, label, selected) {
  const card = roundedRect(x, y, 353, 38, 10, selected ? COLORS.accentDim : COLORS.surface, selected ? COLORS.borderFocused : COLORS.border);
  frame.appendChild(card);
  frame.appendChild(createText({
    text: label, x: x + 14, y: y + 12, width: 290,
    fontSize: 12, fontFamily: 'Roboto Mono', fontStyle: 'Regular', fill: COLORS.textPrimary
  }));
  if (selected) {
    frame.appendChild(createText({
      text: '●', x: x + 322, y: y + 10, width: 14,
      fontSize: 14, fontFamily: 'Inter', fontStyle: 'Bold', fill: COLORS.accent
    }));
  }
}

function sectionLabel(frame, text, x, y) {
  frame.appendChild(createText({
    text, x, y, width: 140,
    fontSize: 12, fontFamily: 'Inter', fontStyle: 'Medium', fill: COLORS.textTertiary
  }));
}

function circleButton(x, y, size, fill, label, textFill) {
  const wrapper = figma.createFrame();
  wrapper.resizeWithoutConstraints(size, size);
  wrapper.x = x;
  wrapper.y = y;
  wrapper.fills = [];
  wrapper.strokes = [];
  wrapper.clipsContent = false;

  const circle = figma.createEllipse();
  circle.resize(size, size);
  circle.x = 0;
  circle.y = 0;
  circle.fills = [solid(fill)];
  wrapper.appendChild(circle);

  const txt = createText({
    text: label,
    x: 0,
    y: 6,
    width: size,
    fontSize: 16,
    fontFamily: 'Inter',
    fontStyle: 'Bold',
    fill: textFill,
    align: 'CENTER'
  });
  wrapper.appendChild(txt);
  return wrapper;
}

function addPill(parent, text, x, y, w, h, fill, textFill, family = 'Inter') {
  const pill = roundedRect(x, y, w, h, h / 2, fill);
  parent.appendChild(pill);
  parent.appendChild(createText({
    text, x, y: y + 6, width: w,
    fontSize: 10, fontFamily: family, fontStyle: family === 'Roboto Mono' ? 'Medium' : 'Semi Bold', fill: textFill, align: 'CENTER'
  }));
}

function createText({ text, x, y, width, height = 20, fontSize, fontFamily, fontStyle, fill, align = 'LEFT', lineHeight }) {
  const node = figma.createText();
  node.fontName = { family: fontFamily, style: fontStyle };
  node.characters = text;
  node.fontSize = fontSize;
  node.fills = [solid(fill)];
  node.textAlignHorizontal = align;
  if (lineHeight) {
    node.lineHeight = { unit: 'PIXELS', value: lineHeight };
  }
  node.resize(width, height);
  node.textAutoResize = 'HEIGHT';
  node.x = x;
  node.y = y;
  return node;
}

function roundedRect(x, y, w, h, radius, fill, stroke) {
  const rect = figma.createRectangle();
  rect.resize(w, h);
  rect.x = x;
  rect.y = y;
  rect.cornerRadius = radius;
  rect.fills = [solid(fill)];
  if (stroke) {
    rect.strokes = [solid(stroke)];
    rect.strokeWeight = 1;
  }
  return rect;
}

function ellipse(x, y, w, h, fill) {
  const node = figma.createEllipse();
  node.resize(w, h);
  node.x = x;
  node.y = y;
  node.fills = [solid(fill)];
  return node;
}

function solid(color) {
  const { r, g, b, a } = color;
  return {
    type: 'SOLID',
    color: { r, g, b },
    opacity: a === undefined ? 1 : a
  };
}

main().catch((err) => {
  console.error(err);
  figma.closePlugin(`Failed: ${err.message}`);
});
