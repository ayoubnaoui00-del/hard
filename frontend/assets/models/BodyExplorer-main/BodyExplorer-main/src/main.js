import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

// ───────────── Muscle Group Mapping System ─────────────
const MUSCLE_MAPPINGS = {
  chest: [
    'pectoralis',
    'subclavius',
    'serratus anterior'
  ],
  shoulders: [
    'deltoid',
    'supraspinatus',
    'infraspinatus',
    'subscapularis',
    'teres',
    'levator scapulae'
  ],
  arms: [
    'biceps',
    'triceps',
    'brachialis',
    'coracobrachialis',
    'anconeus',
    'brachioradialis',
    'pronator',
    'supinator',
    'flexor carpi',
    'extensor carpi',
    'flexor digitorum',
    'extensor digitorum',
    'palmaris'
  ],
  back: [
    'latissimus',
    'trapezius',
    'rhomboid',
    'erector',
    'iliocostalis',
    'longissimus',
    'spinalis',
    'semispinalis',
    'multifidus',
    'quadratus lumborum',
    'serratus posterior'
  ],
  legs: [
    'rectus femoris',
    'vastus',
    'quadriceps',
    'biceps femoris',
    'semitendinosus',
    'semimembranosus',
    'gluteus',
    'gastrocnemius',
    'soleus',
    'tibialis',
    'gracilis',
    'sartorius',
    'adductor',
    'peroneus',
    'tensor fasciae'
  ],
  core: [
    'rectus abdominis',
    'oblique',
    'transversus',
    'pyramidalis'
  ]
};

function classifyMuscleGroup(name) {
  const n = name.toLowerCase().replace(/_/g, ' ');
  for (const [group, keywords] of Object.entries(MUSCLE_MAPPINGS)) {
    for (const kw of keywords) {
      if (n.includes(kw)) return group;
    }
  }
  return null;
}

// ───────────── Materials ─────────────
const baselineMaterial = new THREE.MeshStandardMaterial({
  color: new THREE.Color(0xd1d5db), // High-visibility anatomical light grey
  roughness: 0.45,
  metalness: 0.08,
  side: THREE.DoubleSide,
});

const highlightMaterial = new THREE.MeshStandardMaterial({
  color: new THREE.Color(0xcefa2b), // Signature Velocity Lime highlight
  roughness: 0.32,
  metalness: 0.12,
  emissive: new THREE.Color(0x354700),
  emissiveIntensity: 0.7,
  side: THREE.DoubleSide,
});

const tendonMaterial = new THREE.MeshStandardMaterial({
  color: new THREE.Color(0x9ca3af), // Slate grey for tendons/ligaments
  roughness: 0.55,
  metalness: 0.05,
  side: THREE.DoubleSide,
});

// ───────────── Scene & Camera Setup ─────────────
const canvas = document.getElementById('canvas3d');
const renderer = new THREE.WebGLRenderer({
  canvas,
  antialias: true,
  alpha: true,
  powerPreference: 'high-performance'
});

renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.35;

const scene = new THREE.Scene();

function getOptimalCameraDistance() {
  const aspect = window.innerWidth / window.innerHeight;
  if (aspect < 0.6) return 36;
  if (aspect < 0.8) return 33;
  return 31;
}

const camera = new THREE.PerspectiveCamera(
  45,
  window.innerWidth / window.innerHeight,
  0.1,
  150
);
camera.position.set(0, 0, getOptimalCameraDistance());

const controls = new OrbitControls(camera, canvas);
controls.enableDamping = true;
controls.dampingFactor = 0.08;
controls.minDistance = 10;
controls.maxDistance = 50;
controls.target.set(0, 0, 0);
controls.enablePan = false;
controls.autoRotate = false;
controls.autoRotateSpeed = 0.8;

// ───────────── Lighting ─────────────
const ambientLight = new THREE.AmbientLight(0xffffff, 1.35);
scene.add(ambientLight);

// Key directional light (top-front-right)
const keyLight = new THREE.DirectionalLight(0xffffff, 1.4);
keyLight.position.set(10, 18, 14);
scene.add(keyLight);

// Soft fill light (bottom-left)
const fillLight = new THREE.DirectionalLight(0xe2e8f0, 0.75);
fillLight.position.set(-12, 6, 10);
scene.add(fillLight);

// Back light for posterior definition
const backLight = new THREE.DirectionalLight(0xffffff, 0.9);
backLight.position.set(0, 10, -18);
scene.add(backLight);

// Subtle rim light (from top-back)
const rimLight = new THREE.DirectionalLight(0xcefa2b, 0.4);
rimLight.position.set(8, 14, -12);
scene.add(rimLight);

// Front fill light
const frontLight = new THREE.DirectionalLight(0xffffff, 0.85);
frontLight.position.set(0, 4, 20);
scene.add(frontLight);

// ───────────── State ─────────────
const muscleMeshes = [];
let currentSelectedGroup = 'chest';

// ───────────── Coordinate Transform ─────────────
function transformGeometry(geometry, center, scaleFactor) {
  const posAttr = geometry.getAttribute('position');
  if (posAttr) {
    const pos = posAttr.array;
    for (let i = 0; i < pos.length; i += 3) {
      const bx = pos[i];
      const by = pos[i + 1];
      const bz = pos[i + 2];
      pos[i]     = (bx - center.x) * scaleFactor;
      pos[i + 1] = (bz - center.z) * scaleFactor;
      pos[i + 2] = -(by - center.y) * scaleFactor;
    }
    posAttr.needsUpdate = true;
  }

  const normAttr = geometry.getAttribute('normal');
  if (normAttr) {
    const norms = normAttr.array;
    for (let i = 0; i < norms.length; i += 3) {
      const nx = norms[i];
      const ny = norms[i + 1];
      const nz = norms[i + 2];
      norms[i]     = nx;
      norms[i + 1] = nz;
      norms[i + 2] = -ny;
    }
    normAttr.needsUpdate = true;
  }

  geometry.computeBoundingBox();
  geometry.computeBoundingSphere();
}

// ───────────── Model Loader ─────────────
const loadingOverlay = document.getElementById('loading-overlay');
const loadingText = document.getElementById('loading-text');

function updateProgress(pct) {
  if (loadingText) loadingText.textContent = `Loading 3D Anatomy... ${pct}%`;
}

function hideOverlay() {
  if (loadingOverlay) {
    loadingOverlay.style.opacity = '0';
    setTimeout(() => { loadingOverlay.style.display = 'none'; }, 400);
  }
}

const loader = new GLTFLoader();

// Load anatomy.glb
loader.load(
  './anatomy.glb',
  (gltf) => {
    const root = gltf.scene;
    const box = new THREE.Box3().setFromObject(root);
    const center = box.getCenter(new THREE.Vector3());
    const size = box.getSize(new THREE.Vector3());

    const targetHeight = 22.0;
    const scaleFactor = targetHeight / size.z;

    root.traverse((child) => {
      if (!child.isMesh) return;

      const name = child.name || '';
      const nameLower = name.toLowerCase();
      const isTendon = nameLower.includes('tendon') ||
        nameLower.includes('ligament') ||
        nameLower.includes('retinaculum') ||
        nameLower.includes('membrane');

      const group = classifyMuscleGroup(name);

      const geom = child.geometry.clone();
      transformGeometry(geom, center, scaleFactor);

      const mat = isTendon ? tendonMaterial : baselineMaterial;
      const mesh = new THREE.Mesh(geom, mat);

      mesh.userData = {
        name: name,
        muscleGroup: group,
        isTendon: isTendon
      };

      muscleMeshes.push(mesh);
      scene.add(mesh);
    });

    hideOverlay();
    // Apply initial selected group
    window.selectMuscleGroup(currentSelectedGroup);

    // Notify Flutter model loaded
    notifyFlutter('modelLoaded', 'ready');
  },
  (progress) => {
    if (progress.total > 0) {
      updateProgress(Math.round((progress.loaded / progress.total) * 100));
    }
  },
  (error) => {
    console.error('Failed to load anatomy.glb:', error);
    if (loadingText) loadingText.textContent = 'Loading failed, retrying...';
  }
);

// ───────────── Selection & Highlighting API ─────────────
window.selectMuscleGroup = function(groupName) {
  if (!groupName) return;
  const group = groupName.toLowerCase();
  currentSelectedGroup = group;

  for (const mesh of muscleMeshes) {
    if (mesh.userData.isTendon) continue;
    if (mesh.userData.muscleGroup === group) {
      mesh.material = highlightMaterial;
    } else {
      mesh.material = baselineMaterial;
    }
  }

  // Smoothly orient camera if selecting back or front muscles
  if (group === 'back') {
    smoothRotateTo(false);
  } else if (group === 'chest' || group === 'core') {
    smoothRotateTo(true);
  }
};

window.setCameraView = function(isFront) {
  smoothRotateTo(isFront);
};

window.resetCamera = function() {
  smoothRotateTo(true);
};

// ───────────── Smooth Camera Transitions ─────────────
function smoothRotateTo(isFront, duration = 650) {
  const dist = getOptimalCameraDistance();
  const targetZ = isFront ? dist : -dist;
  const startPos = camera.position.clone();
  const endPos = new THREE.Vector3(0, 0, targetZ);
  const startTime = performance.now();

  function step(now) {
    const elapsed = now - startTime;
    const progress = Math.min(elapsed / duration, 1);
    const ease = progress < 0.5 ? 4 * progress * progress * progress : 1 - Math.pow(-2 * progress + 2, 3) / 2;

    camera.position.lerpVectors(startPos, endPos, ease);
    controls.target.set(0, 0, 0);
    controls.update();

    if (progress < 1) {
      requestAnimationFrame(step);
    }
  }
  requestAnimationFrame(step);
}

// ───────────── Tap & Raycasting Interaction ─────────────
const raycaster = new THREE.Raycaster();
const mouse = new THREE.Vector2();
let pointerStartX = 0;
let pointerStartY = 0;

canvas.addEventListener('pointerdown', (e) => {
  pointerStartX = e.clientX;
  pointerStartY = e.clientY;
});

canvas.addEventListener('pointerup', (e) => {
  // Ignore drag / rotate gestures (> 8px movement)
  if (Math.hypot(e.clientX - pointerStartX, e.clientY - pointerStartY) > 8) {
    return;
  }

  mouse.x = (e.clientX / window.innerWidth) * 2 - 1;
  mouse.y = -(e.clientY / window.innerHeight) * 2 + 1;
  raycaster.setFromCamera(mouse, camera);

  const visibleTargets = muscleMeshes.filter(m => !m.userData.isTendon);
  const hits = raycaster.intersectObjects(visibleTargets, false);

  if (hits.length > 0) {
    const hitMesh = hits[0].object;
    const group = hitMesh.userData.muscleGroup;
    if (group) {
      window.selectMuscleGroup(group);
      notifyFlutter('muscleSelected', group);
    }
  }
});

// ───────────── Flutter Bridge ─────────────
function notifyFlutter(event, data) {
  if (window.FlutterBodyModel && window.FlutterBodyModel.postMessage) {
    window.FlutterBodyModel.postMessage(data);
  }
  if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
    window.flutter_inappwebview.callHandler(event, data);
  }
}

// ───────────── Resize Handler ─────────────
window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
  const dist = getOptimalCameraDistance();
  const isBack = camera.position.z < 0;
  camera.position.set(0, 0, isBack ? -dist : dist);
  controls.target.set(0, 0, 0);
  controls.update();
});

// ───────────── Render Loop ─────────────
function animate() {
  requestAnimationFrame(animate);
  controls.update();
  renderer.render(scene, camera);
}
animate();
