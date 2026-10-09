import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { MUSCLE_GROUPS, getMuscleInfo, classifyMuscleGroup } from './muscleData.js';

/**
 * Loads both the BodyParts3D anatomy GLB (muscles/tendons) and skeleton GLB (bones).
 * Returns a Promise that resolves to { bodyGroup, muscleMeshes[], skeletonGroup }
 *
 * The GLBs contain named meshes from MRI-based data.
 * Coordinate transform: BP3D uses X=left-right, Y=front-back, Z=bottom-top (mm).
 * We remap to Three.js: X=left-right, Y=up, Z=front (scene units ~30 tall).
 *
 * Performance optimizations:
 * - Uses MeshStandardMaterial instead of MeshPhysicalMaterial (cheaper)
 * - Shares one material instance per muscle group (not cloned per mesh)
 * - Highlighting uses temporary material swap instead of mutating shared material
 */

// ───────────── Shared Materials (created once) ─────────────

// One material per muscle group — shared across all meshes in the group
const groupMaterials = {};
for (const [key, group] of Object.entries(MUSCLE_GROUPS)) {
  groupMaterials[key] = new THREE.MeshStandardMaterial({
    color: new THREE.Color(group.color),
    roughness: 0.55,
    metalness: 0.0,
    side: THREE.DoubleSide,
    flatShading: false,
  });
}

// Tendon material — shared by all tendons
const tendonMaterial = new THREE.MeshStandardMaterial({
  color: new THREE.Color(0.92, 0.88, 0.78),
  roughness: 0.45,
  metalness: 0.0,
  side: THREE.DoubleSide,
  flatShading: false,
});

// Default muscle material for unclassified muscles
const defaultMuscleMaterial = new THREE.MeshStandardMaterial({
  color: new THREE.Color(0.7, 0.18, 0.14),
  roughness: 0.6,
  metalness: 0.0,
  side: THREE.DoubleSide,
  flatShading: false,
});

// Bone material — semi-transparent off-white, shared by all bones
export const boneMaterial = new THREE.MeshStandardMaterial({
  color: new THREE.Color(0.95, 0.92, 0.85),
  roughness: 0.6,
  metalness: 0.0,
  side: THREE.DoubleSide,
  transparent: true,
  opacity: 0.6,
  flatShading: false,
  depthWrite: false, // avoids z-fighting artifacts with transparent bones
});

// Highlight material — used temporarily when hovering/selecting
export const highlightMaterial = new THREE.MeshStandardMaterial({
  color: new THREE.Color(1.0, 0.6, 0.4),
  roughness: 0.4,
  metalness: 0.0,
  emissive: new THREE.Color(0.3, 0.1, 0.05),
  side: THREE.DoubleSide,
  flatShading: false,
});

// Selected material — brighter highlight
export const selectedMaterial = new THREE.MeshStandardMaterial({
  color: new THREE.Color(1.0, 0.75, 0.55),
  roughness: 0.35,
  metalness: 0.0,
  emissive: new THREE.Color(0.4, 0.15, 0.05),
  side: THREE.DoubleSide,
  flatShading: false,
});

// ───────────── Coordinate Transform ─────────────

/**
 * Apply BP3D-to-Three.js coordinate transform to a geometry in place.
 * BP3D: X=left-right, Y=front-back, Z=bottom-top (mm)
 * Three.js: X=left-right, Y=up, Z=front
 *
 * @param {THREE.BufferGeometry} geometry - Geometry to transform
 * @param {THREE.Vector3} center - Center of the source bounding box
 * @param {number} scaleFactor - mm-to-scene-units scale
 */
function transformGeometry(geometry, center, scaleFactor) {
  const posAttr = geometry.getAttribute('position');
  if (posAttr) {
    const pos = posAttr.array;
    for (let i = 0; i < pos.length; i += 3) {
      const bx = pos[i];     // left-right
      const by = pos[i + 1]; // front-back
      const bz = pos[i + 2]; // bottom-top

      pos[i]     = (bx - center.x) * scaleFactor;    // X: left-right
      pos[i + 1] = (bz - center.z) * scaleFactor;    // Y: up (was Z)
      pos[i + 2] = -(by - center.y) * scaleFactor;   // Z: front (was -Y)
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

// ───────────── Main Loader ─────────────

export function buildBody(onProgress) {
  return new Promise((resolve, reject) => {
    const loader = new GLTFLoader();
    const bodyGroup = new THREE.Group();
    const muscleMeshes = [];
    const skeletonGroup = new THREE.Group();
    skeletonGroup.visible = true;
    bodyGroup.add(skeletonGroup);

    console.log('Loading anatomy models...');

    // Use Vite's BASE_URL so paths work on GitHub Pages (base: '/BodyExplorer/')
    const base = import.meta.env.BASE_URL;

    // Load mesh mapping to identify Z-Anatomy meshes
    const mappingPromise = fetch(`${base}mesh_mapping.json`)
      .then((res) => res.json())
      .catch(() => []);

    // Load both GLBs in parallel
    const anatomyPromise = loadGLB(loader, `${base}anatomy.glb`, (pct) => {
      // Anatomy is 0-70% of total progress
      if (onProgress) onProgress(Math.round(pct * 0.7));
    });

    const skeletonPromise = loadGLB(loader, `${base}skeleton.glb`, (pct) => {
      // Skeleton is 70-100% of total progress
      if (onProgress) onProgress(Math.round(70 + pct * 0.3));
    });

    Promise.all([anatomyPromise, skeletonPromise, mappingPromise])
      .then(([anatomyGLTF, skeletonGLTF, meshMapping]) => {
        // Build a set of Z-Anatomy mesh names for tagging
        // GLTFLoader replaces spaces with underscores in node names,
        // so normalize mapping names the same way for lookup.
        const zaMeshNames = new Set();
        for (const entry of meshMapping) {
          if (entry.source === 'z-anatomy') {
            zaMeshNames.add(entry.name.replace(/\s+/g, '_'));
          }
        }
        console.log(`Mesh mapping: ${zaMeshNames.size} Z-Anatomy meshes identified`);

        // ─── Process Anatomy (muscles/tendons) ───
        const anatomyRoot = anatomyGLTF.scene;
        const anatomyBox = new THREE.Box3().setFromObject(anatomyRoot);
        const anatomyCenter = anatomyBox.getCenter(new THREE.Vector3());
        const anatomySize = anatomyBox.getSize(new THREE.Vector3());

        // BP3D Z is height; target ~30 scene units tall
        const targetHeight = 30;
        const scaleFactor = targetHeight / anatomySize.z;

        let muscleCount = 0;
        anatomyRoot.traverse((child) => {
          if (!child.isMesh) return;

          const name = child.name || `mesh_${muscleCount}`;
          const nameLower = name.toLowerCase();

          const isTendon = nameLower.includes('tendon') ||
            nameLower.includes('ligament') ||
            nameLower.includes('retinaculum') ||
            nameLower.includes('membrane') ||
            nameLower.includes('plantar ligament');

          const group = classifyMuscleGroup(name);
          const info = getMuscleInfo(name);

          // Clone + transform geometry
          const geometry = child.geometry.clone();
          transformGeometry(geometry, anatomyCenter, scaleFactor);

          // Pick shared material (no cloning!)
          let material;
          if (isTendon) {
            material = tendonMaterial;
          } else if (group && groupMaterials[group]) {
            material = groupMaterials[group];
          } else {
            material = defaultMuscleMaterial;
          }

          const mesh = new THREE.Mesh(geometry, material);
          mesh.castShadow = true;
          mesh.receiveShadow = true;
          mesh.renderOrder = 1; // render muscles on top of bones

          // Store metadata for raycasting/info panel
          mesh.userData.displayName = formatMuscleName(name);
          mesh.userData.originalMaterial = material; // for highlight restore
          mesh.userData.muscleData = {
            name: formatMuscleName(name),
            rawName: name,
            group: group || 'OTHER',
            type: isTendon ? 'tendon' : 'muscle',
            info: info,
          };
          mesh.userData.side = determineSide(name);
          mesh.userData.isZAnatomy = zaMeshNames.has(name);

          muscleMeshes.push(mesh);
          bodyGroup.add(mesh);
          muscleCount++;
        });

        console.log(`Loaded ${muscleCount} anatomical meshes (${muscleMeshes.filter(m => m.userData.muscleData.type === 'tendon').length} tendons)`);

        // ─── Process Skeleton (bones) ───
        const skeletonRoot = skeletonGLTF.scene;
        // Use the SAME center and scale as anatomy so they align
        let boneCount = 0;
        skeletonRoot.traverse((child) => {
          if (!child.isMesh) return;

          const geometry = child.geometry.clone();
          transformGeometry(geometry, anatomyCenter, scaleFactor);

          const boneMesh = new THREE.Mesh(geometry, boneMaterial);
          boneMesh.castShadow = false;
          boneMesh.receiveShadow = false;
          boneMesh.renderOrder = 0; // render bones before muscles

          boneMesh.userData.displayName = formatMuscleName(child.name || `bone_${boneCount}`);
          boneMesh.userData.isBone = true;

          skeletonGroup.add(boneMesh);
          boneCount++;
        });

        console.log(`Loaded ${boneCount} bone meshes`);

        // Store scale factor for debug offset slider (mm -> scene units conversion)
        bodyGroup.userData.scaleFactor = scaleFactor;

        resolve({ bodyGroup, muscleMeshes, skeletonGroup });
      })
      .catch((error) => {
        console.error('Failed to load anatomy models:', error);
        reject(error);
      });
  });
}

/**
 * Load a GLB file and return a promise of the GLTF object.
 */
function loadGLB(loader, url, onProgress) {
  return new Promise((resolve, reject) => {
    loader.load(
      url,
      (gltf) => resolve(gltf),
      (progress) => {
        if (progress.total > 0 && onProgress) {
          onProgress(Math.round((progress.loaded / progress.total) * 100));
        }
      },
      (error) => reject(error)
    );
  });
}

// ───────────── Helpers ─────────────

/**
 * Format raw BP3D mesh name into readable display name.
 * e.g. "abdominal part of left pectoralis major" -> "Left Pectoralis Major (Abdominal Part)"
 * e.g. "left gluteus maximus" -> "Left Gluteus Maximus"
 */
function formatMuscleName(name) {
  // Remove duplicate numbering like " (2)"
  let clean = name.replace(/\s*\(\d+\)\s*$/, '');

  // Replace underscores with spaces
  clean = clean.replace(/_/g, ' ');

  // Trim extra whitespace
  clean = clean.replace(/\s+/g, ' ').trim();

  // Reorganize "X part/head/belly of [left/right] Y" -> "[Left/Right] Y (X Part/Head/Belly)"
  const partMatch = clean.match(/^(.+?)\s+(part|head|belly)\s+of\s+(?:(left|right)\s+)?(.+)$/i);
  if (partMatch) {
    const qualifier = partMatch[1];
    const keyword = partMatch[2];
    const side = partMatch[3] || '';
    const muscle = partMatch[4];
    const sideStr = side ? titleWord(side) + ' ' : '';
    clean = `${sideStr}${muscle} (${qualifier} ${keyword})`;
  }

  // Title case, but keep small words lowercase in the middle
  const smallWords = new Set(['of', 'the', 'and', 'in', 'at', 'to', 'for', 'on', 'by', 'or']);
  const words = clean.split(' ');
  const titled = words.map((w, i) => {
    if (i > 0 && smallWords.has(w.toLowerCase())) {
      return w.toLowerCase();
    }
    return titleWord(w);
  });
  return titled.join(' ');
}

function titleWord(w) {
  if (!w) return w;
  return w.charAt(0).toUpperCase() + w.slice(1).toLowerCase();
}

/**
 * Determine which side of the body a muscle is on.
 */
function determineSide(name) {
  const lower = name.toLowerCase();
  if (lower.includes('left')) return 'Left';
  if (lower.includes('right')) return 'Right';
  return 'Center';
}
