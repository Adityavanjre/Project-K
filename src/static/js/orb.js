/**
 * K.A.L.I. Neural Orb — Vanilla JS Fusion
 * Based on Project-K Sovereign Visualization
 */

window.createOrb = function(canvas) {
  let destroyed = false;
  const N = 1200; // Optimized for sidebar integration

  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
  renderer.setPixelRatio(window.devicePixelRatio);
  
  const container = canvas.parentElement;
  renderer.setSize(container.clientWidth, container.clientHeight);

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(45, container.clientWidth / container.clientHeight, 1, 1000);
  camera.position.z = 80;

  // ── Particles ──
  const geo = new THREE.BufferGeometry();
  const pos = new Float32Array(N * 3);
  const vel = new Float32Array(N * 3);
  const phase = new Float32Array(N);

  for (let i = 0; i < N; i++) {
    const theta = Math.random() * Math.PI * 2;
    const phi = Math.acos(2 * Math.random() - 1);
    const r = Math.pow(Math.random(), 0.5) * 25;
    pos[i * 3] = r * Math.sin(phi) * Math.cos(theta);
    pos[i * 3 + 1] = r * Math.sin(phi) * Math.sin(theta);
    pos[i * 3 + 2] = r * Math.cos(phi);
    phase[i] = Math.random() * 1000;
  }

  geo.setAttribute("position", new THREE.BufferAttribute(pos, 3));

  const mat = new THREE.PointsMaterial({
    color: 0x00d4ff, size: 0.5, transparent: true, opacity: 0.6,
    sizeAttenuation: true, blending: THREE.AdditiveBlending, depthWrite: false,
  });

  const points = new THREE.Points(geo, mat);
  scene.add(points);

  // ── Connection lines ──
  const MAX_LINES = 3000;
  const linePos = new Float32Array(MAX_LINES * 6);
  const lineGeo = new THREE.BufferGeometry();
  lineGeo.setAttribute("position", new THREE.BufferAttribute(linePos, 3));
  lineGeo.setDrawRange(0, 0);

  const lineMat = new THREE.LineBasicMaterial({
    color: 0x00d4ff, transparent: true, opacity: 0.0,
    blending: THREE.AdditiveBlending, depthWrite: false,
  });

  const lines = new THREE.LineSegments(lineGeo, lineMat);
  scene.add(lines);

  // ── State ──
  let state = "idle";
  let targetRadius = 25, currentRadius = 25;
  let targetSpeed = 0.3, currentSpeed = 0.3;
  let targetBright = 0.6, currentBright = 0.6;
  let targetSize = 0.4, currentSize = 0.4;
  let lineAmount = 0, targetLineAmount = 0;
  let lineDistance = 8;

  let spinX = 0, spinY = 0, spinZ = 0;
  let transitionEnergy = 0;
  let lastState = "idle";
  let cloudZ = 0, cloudZVel = 0;

  let analyser = null;
  let freqData = new Uint8Array(64);
  let bass = 0, mid = 0;

  const clock = new THREE.Clock();

  function animate() {
    if (destroyed) return;
    requestAnimationFrame(animate);
    const t = clock.getElapsedTime();

    switch (state) {
      case "idle":
        targetRadius = 28; targetSpeed = 0.2; targetBright = 0.5; targetSize = 0.35;
        targetLineAmount = 0.15; break;
      case "listening":
        targetRadius = 22; targetSpeed = 0.3; targetBright = 0.7; targetSize = 0.45;
        targetLineAmount = 0.4; break;
      case "thinking":
        targetRadius = 16; targetSpeed = 0.6; targetBright = 0.8; targetSize = 0.3;
        targetLineAmount = 1.0; break;
      case "speaking":
        targetRadius = 18; targetSpeed = 0.2; targetBright = 0.8; targetSize = 0.5;
        targetLineAmount = 0.8; break;
    }

    currentRadius += (targetRadius - currentRadius) * 0.02;
    currentSpeed += (targetSpeed - currentSpeed) * 0.02;
    currentBright += (targetBright - currentBright) * 0.02;
    currentSize += (targetSize - currentSize) * 0.02;
    lineAmount += (targetLineAmount - lineAmount) * 0.02;

    if (state !== lastState) { transitionEnergy = 1.0; lastState = state; }
    transitionEnergy *= 0.985;
    if (transitionEnergy > 0.05) {
      spinX += transitionEnergy * 0.012 * Math.sin(t * 1.7);
      spinY += transitionEnergy * 0.015;
      spinZ += transitionEnergy * 0.008 * Math.cos(t * 1.3);
    }

    bass = 0; mid = 0;
    if (analyser) {
      analyser.getByteFrequencyData(freqData);
      let bSum = 0, mSum = 0;
      for (let i = 0; i < 8; i++) bSum += freqData[i];
      for (let i = 8; i < 24; i++) mSum += freqData[i];
      bass = bSum / (8 * 255); mid = mSum / (16 * 255);
    }

    let zTarget = Math.sin(t * 0.12) * 8;
    if (state === "thinking") zTarget = Math.sin(t * 0.3) * 15 + Math.sin(t * 0.9) * 6;
    else if (state === "speaking") zTarget = Math.sin(t * 0.15) * 6 - bass * 10;
    cloudZVel += (zTarget - cloudZ) * 0.008;
    cloudZVel *= 0.94;
    cloudZ += cloudZVel;

    points.rotation.x = spinX; points.rotation.y = spinY; points.rotation.z = spinZ;
    points.position.z = cloudZ;
    lines.rotation.x = spinX; lines.rotation.y = spinY; lines.rotation.z = spinZ;
    lines.position.z = cloudZ;

    const p = geo.getAttribute("position");
    const a = p.array;

    for (let i = 0; i < N; i++) {
      const i3 = i * 3;
      let x = a[i3], y = a[i3 + 1], z = a[i3 + 2];
      const px = phase[i];

      vel[i3] += Math.sin(t * 0.05 + px) * 0.001 * currentSpeed;
      vel[i3 + 1] += Math.cos(t * 0.06 + px * 1.3) * 0.001 * currentSpeed;
      vel[i3 + 2] += Math.sin(t * 0.055 + px * 0.7) * 0.001 * currentSpeed;

      const dist = Math.sqrt(x * x + y * y + z * z) || 0.01;
      const pull = Math.max(0, dist - currentRadius) * 0.002 + 0.0003;
      vel[i3] -= (x / dist) * pull;
      vel[i3 + 1] -= (y / dist) * pull;
      vel[i3 + 2] -= (z / dist) * pull;

      if (bass > 0.05) {
        vel[i3] += (x / dist) * bass * 0.02;
        vel[i3 + 1] += (y / dist) * bass * 0.02;
        vel[i3 + 2] += (z / dist) * bass * 0.02;
      }

      vel[i3] *= 0.992; vel[i3 + 1] *= 0.992; vel[i3 + 2] *= 0.992;
      a[i3] += vel[i3]; a[i3 + 1] += vel[i3 + 1]; a[i3 + 2] += vel[i3 + 2];
    }
    p.needsUpdate = true;

    if (lineAmount > 0.01) {
      const lp = lineGeo.getAttribute("position");
      const la = lp.array;
      let lineCount = 0;
      const maxDist = lineDistance * (1 + bass * 0.5);
      const maxDistSq = maxDist * maxDist;
      const step = 4;

      for (let i = 0; i < N && lineCount < MAX_LINES; i += step) {
        const i3 = i * 3;
        const x1 = a[i3], y1 = a[i3 + 1], z1 = a[i3 + 2];
        for (let j = i + step; j < N && lineCount < MAX_LINES; j += step) {
          const j3 = j * 3;
          const dx = a[j3] - x1, dy = a[j3 + 1] - y1, dz = a[j3 + 2] - z1;
          if (dx * dx + dy * dy + dz * dz < maxDistSq) {
            const idx = lineCount * 6;
            la[idx] = x1; la[idx+1] = y1; la[idx+2] = z1;
            la[idx+3] = a[j3]; la[idx+4] = a[j3+1]; la[idx+5] = a[j3+2];
            lineCount++;
          }
        }
      }
      lineGeo.setDrawRange(0, lineCount * 2);
      lp.needsUpdate = true;
      lineMat.opacity = lineAmount * 0.12;
    } else {
      lineGeo.setDrawRange(0, 0);
    }

    mat.opacity = currentBright + bass * 0.08;
    mat.size = currentSize + bass * 0.05;

    camera.position.x = Math.sin(t * 0.02) * 5;
    camera.position.y = Math.cos(t * 0.03) * 3;
    camera.lookAt(0, 0, cloudZ * 0.2);

    renderer.render(scene, camera);
  }

  function onResize() {
    const w = container.clientWidth;
    const h = container.clientHeight;
    camera.aspect = w / h;
    camera.updateProjectionMatrix();
    renderer.setSize(w, h);
  }

  window.addEventListener("resize", onResize);
  animate();

  return {
    setState(s) { state = s; },
    setAnalyser(a) {
      analyser = a;
      if (a) freqData = new Uint8Array(a.frequencyBinCount);
    },
    destroy() {
      destroyed = true;
      window.removeEventListener("resize", onResize);
      renderer.dispose();
    },
  };
};
