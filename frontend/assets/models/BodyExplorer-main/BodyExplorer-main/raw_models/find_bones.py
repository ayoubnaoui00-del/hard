"""
Find and convert skeleton bone OBJ files from BodyParts3D into skeleton.glb.
Also decimates existing anatomy.glb meshes for performance.

Pipeline:
1. Parse parts_list.txt for bone-related entries
2. Scan OBJ headers to match files to bone entries  
3. Filter to core skeletal bones (exclude cartilage, discs, etc.)
4. Convert to skeleton.glb with named meshes
"""
import json
import os
import re
import struct
import numpy as np

OBJ_DIR = '/home/johanbellander/projects/BodyExplorer/raw_models/bp3d/isa_BP3D_4.0_obj_99'
PARTS_LIST = '/home/johanbellander/projects/BodyExplorer/raw_models/parts_list.txt'
OUTPUT_GLB = '/home/johanbellander/projects/BodyExplorer/public/skeleton.glb'

# ─── Step 1: Parse parts list ───

fma_to_info = {}
bp_to_info = {}
with open(PARTS_LIST, 'r') as f:
    next(f)  # skip header
    for line in f:
        parts = line.strip().split('\t')
        if len(parts) >= 3:
            fma_id = parts[0]
            bp_id = parts[1]
            name = parts[2]
            fma_to_info[fma_id] = (bp_id, name)
            bp_to_info[bp_id] = (fma_id, name)

# ─── Step 2: Scan all OBJ file headers ───

print("Scanning OBJ file headers...")
obj_files = {}
for fname in sorted(os.listdir(OBJ_DIR)):
    if not fname.endswith('.obj'):
        continue
    filepath = os.path.join(OBJ_DIR, fname)
    bp_id = None
    fma_id = None
    with open(filepath, 'r') as f:
        for line in f:
            if not line.startswith('#'):
                break
            m = re.search(r'Representation ID\s*:\s*(\S+)', line)
            if m:
                bp_id = m.group(1)
            m = re.search(r'Concept ID\s*:\s*(\S+)', line)
            if m:
                fma_id = m.group(1)
    obj_files[fname] = {'bp_id': bp_id, 'fma_id': fma_id}

print(f"Scanned {len(obj_files)} OBJ files")

# ─── Step 3: Find bone-related files ───

BONE_KEYWORDS = [
    'bone', 'femur', 'tibia', 'fibula', 'humerus', 'radius', 'ulna',
    'patella', 'clavicle', 'scapula', 'sternum', 'manubrium', 'xiphoid',
    'sacrum', 'coccyx', 'vertebra', 'atlas', 'axis',
    'rib', 'costal',
    'skull', 'cranium', 'mandible', 'maxilla', 'frontal bone', 'parietal',
    'temporal bone', 'occipital', 'sphenoid', 'ethmoid', 'vomer', 'hyoid',
    'nasal bone', 'zygomatic', 'lacrimal',
    'phalanx', 'phalanges',
    'metacarpal', 'metatarsal',
    'carpal', 'tarsal',
    'scaphoid', 'lunate', 'triquetrum', 'pisiform', 'trapezium', 'trapezoid',
    'capitate', 'hamate',
    'talus', 'calcaneus', 'navicular', 'cuboid', 'cuneiform',
    'hip bone', 'ilium', 'ischium', 'pubis',
    'pelvis',
]

# Patterns to EXCLUDE (not actual bones)
EXCLUDE_PATTERNS = [
    'artery', 'arterial', 'arteries',
    'vein', 'venous',
    'nerve', 'ligament', 'tendon',
    'fascia', 'membrane', 'periosteum',
    'cartilage',
    'marrow', 'endosteum',
    'joint', 'articul',
    'branch of', 'trunk of',
    'set of', 'zone of',
    'organ component',
    'intervertebral',
    'disk', 'disc',
    'foramen', 'canal',
    'cavity', 'space',
    'fossa', 'notch', 'process of',
    'surface of', 'border of', 'angle of',
    'condyle', 'epicondyle', 'tuberosity',
    'tubercle', 'trochanter',
    'head of femur', 'head of humerus', 'head of radius', 'head of fibula',
    'neck of', 'shaft of', 'body of femur', 'body of tibia',
    'epiphysis', 'diaphysis', 'metaphysis',
    'peritoneum', 'perichondrium',
    'plexus', 'ganglion',
    # False positives from keyword matching
    'muscle',
    'gland',
    'lake',
    'sac',
    'duct',
    'lobe',
    'lobule',
    'biliary',
    'hepatic',
    'tributary',
    'tarsal plate',
    'iliotibial tract',
    'iliocostalis',
    'sternocostal part',
    'humeral head of',
    'ulnar head of',
    'geniohyoid',
    'mylohyoid',
    'omohyoid',
    'sternohyoid',
    'stylohyoid',
    'thyrohyoid',
    'subscapularis',
    'levator scapulae',
    'fibularis',
    'tibialis',
    'extensor carpi',
    'intercostal',
]

# Force include these specific entries
INCLUDE_PATTERNS = [
    'body of sternum',
    'xiphoid process',
    'manubrium',
]

bone_files = []
for fname, info in obj_files.items():
    fma_id = info['fma_id']
    bp_id = info['bp_id']
    name = None

    if fma_id and fma_id in fma_to_info:
        name = fma_to_info[fma_id][1]
    elif bp_id and bp_id in bp_to_info:
        name = bp_to_info[bp_id][1]

    if not name:
        continue

    name_lower = name.lower()

    # Check force include
    force_include = any(pat in name_lower for pat in INCLUDE_PATTERNS)

    # Check if it matches bone keywords
    is_bone = any(kw in name_lower for kw in BONE_KEYWORDS)

    if not is_bone and not force_include:
        continue

    # Check exclusions
    should_exclude = any(pat in name_lower for pat in EXCLUDE_PATTERNS)

    if force_include or not should_exclude:
        bone_files.append({
            'file': fname,
            'fma_id': fma_id,
            'bp_id': bp_id,
            'name': name,
        })

bone_files.sort(key=lambda x: x['name'])

print(f"\nFound {len(bone_files)} bone OBJ files")

# Estimate total size
total_size = sum(
    os.path.getsize(os.path.join(OBJ_DIR, m['file']))
    for m in bone_files
)
print(f"Total OBJ size: {total_size / 1024 / 1024:.1f} MB")

# Print unique names
seen = set()
for bf in bone_files:
    if bf['name'] not in seen:
        seen.add(bf['name'])
        fsize = os.path.getsize(os.path.join(OBJ_DIR, bf['file']))
        print(f"  {bf['file']:15s}  {fsize:>8d} bytes  {bf['name']}")

# Save bone files list
bone_list_path = '/home/johanbellander/projects/BodyExplorer/raw_models/bone_files.json'
with open(bone_list_path, 'w') as f:
    json.dump(bone_files, f, indent=2)
print(f"\nWrote {len(bone_files)} entries to {bone_list_path}")

# ─── Step 4: Convert to GLB ───

print(f"\nConverting {len(bone_files)} bone OBJ files to GLB...")

import trimesh

meshes_data = []
seen_names = {}

for i, m in enumerate(bone_files):
    obj_path = os.path.join(OBJ_DIR, m['file'])
    if not os.path.exists(obj_path):
        print(f"  SKIP (not found): {m['file']}")
        continue

    try:
        mesh = trimesh.load(obj_path, file_type='obj', process=True)
    except Exception as e:
        print(f"  SKIP (error): {m['file']} - {e}")
        continue

    # Handle Scene vs Trimesh
    if isinstance(mesh, trimesh.Scene):
        meshes_in_scene = []
        for geom in mesh.geometry.values():
            if hasattr(geom, 'vertices') and hasattr(geom, 'faces'):
                meshes_in_scene.append(geom)
        if meshes_in_scene:
            mesh = trimesh.util.concatenate(meshes_in_scene)
        else:
            print(f"  SKIP (empty scene): {m['file']}")
            continue

    if not hasattr(mesh, 'vertices') or not hasattr(mesh, 'faces'):
        print(f"  SKIP (no geometry): {m['file']}")
        continue

    if len(mesh.vertices) == 0 or len(mesh.faces) == 0:
        print(f"  SKIP (empty): {m['file']}")
        continue

    # Decimate large meshes for performance
    target_faces = 3000
    if len(mesh.faces) > target_faces:
        try:
            mesh = mesh.simplify_quadric_decimation(target_faces)
        except Exception:
            # Fallback: keep original if decimation fails
            pass

    # Sanitize name
    name = m['name']
    if name in seen_names:
        seen_names[name] += 1
        name = f"{name} ({seen_names[name]})"
    else:
        seen_names[name] = 1

    meshes_data.append({
        'name': name,
        'vertices': np.array(mesh.vertices, dtype=np.float32),
        'faces': np.array(mesh.faces, dtype=np.uint32),
        'normals': np.array(mesh.vertex_normals, dtype=np.float32) if mesh.vertex_normals is not None and len(mesh.vertex_normals) > 0 else None,
        'fma_id': m['fma_id'],
        'bp_id': m['bp_id'],
        'original_name': m['name'],
    })

    if (i + 1) % 50 == 0:
        print(f"  Loaded {i + 1}/{len(bone_files)}...")

print(f"Loaded {len(meshes_data)} bone meshes successfully")

# ─── Step 5: Build GLB ───

buffer_views = []
accessors = []
meshes_json = []
nodes = []
bin_data = bytearray()

# Single bone material (off-white)
materials = [
    {
        "name": "bone",
        "pbrMetallicRoughness": {
            "baseColorFactor": [0.9, 0.88, 0.82, 1.0],
            "metallicFactor": 0.0,
            "roughnessFactor": 0.6
        },
        "doubleSided": True
    }
]

for idx, md in enumerate(meshes_data):
    verts = md['vertices']
    faces = md['faces']
    normals = md['normals']

    max_index = faces.max()
    if max_index <= 65535:
        index_data = faces.astype(np.uint16).tobytes()
        index_component_type = 5123
    else:
        index_data = faces.astype(np.uint32).tobytes()
        index_component_type = 5125

    vert_data = verts.tobytes()

    while len(bin_data) % 4 != 0:
        bin_data.append(0)

    index_bv_offset = len(bin_data)
    bin_data.extend(index_data)
    index_bv_idx = len(buffer_views)
    buffer_views.append({
        "buffer": 0,
        "byteOffset": index_bv_offset,
        "byteLength": len(index_data),
        "target": 34963
    })

    while len(bin_data) % 4 != 0:
        bin_data.append(0)

    vert_bv_offset = len(bin_data)
    bin_data.extend(vert_data)
    vert_bv_idx = len(buffer_views)
    buffer_views.append({
        "buffer": 0,
        "byteOffset": vert_bv_offset,
        "byteLength": len(vert_data),
        "byteStride": 12,
        "target": 34962
    })

    index_acc_idx = len(accessors)
    accessors.append({
        "bufferView": index_bv_idx,
        "byteOffset": 0,
        "componentType": index_component_type,
        "count": faces.size,
        "type": "SCALAR",
        "max": [int(max_index)],
        "min": [0]
    })

    pos_acc_idx = len(accessors)
    vmin = verts.min(axis=0).tolist()
    vmax = verts.max(axis=0).tolist()
    accessors.append({
        "bufferView": vert_bv_idx,
        "byteOffset": 0,
        "componentType": 5126,
        "count": len(verts),
        "type": "VEC3",
        "max": vmax,
        "min": vmin
    })

    attributes = {"POSITION": pos_acc_idx}
    if normals is not None and len(normals) == len(verts):
        while len(bin_data) % 4 != 0:
            bin_data.append(0)

        norm_data = normals.tobytes()
        norm_bv_offset = len(bin_data)
        bin_data.extend(norm_data)
        norm_bv_idx = len(buffer_views)
        buffer_views.append({
            "buffer": 0,
            "byteOffset": norm_bv_offset,
            "byteLength": len(norm_data),
            "byteStride": 12,
            "target": 34962
        })

        norm_acc_idx = len(accessors)
        accessors.append({
            "bufferView": norm_bv_idx,
            "byteOffset": 0,
            "componentType": 5126,
            "count": len(normals),
            "type": "VEC3"
        })
        attributes["NORMAL"] = norm_acc_idx

    mesh_json = {
        "name": md['name'],
        "primitives": [{
            "attributes": attributes,
            "indices": index_acc_idx,
            "material": 0
        }]
    }
    mesh_idx = len(meshes_json)
    meshes_json.append(mesh_json)

    nodes.append({
        "name": md['name'],
        "mesh": mesh_idx
    })

# Root node
root_children = list(range(len(nodes)))
nodes.append({
    "name": "Skeleton",
    "children": root_children
})

gltf_json = {
    "asset": {
        "version": "2.0",
        "generator": "BodyExplorer bone OBJ-to-GLB converter",
        "copyright": "BodyParts3D, (c) The Database Center for Life Science licensed under CC Attribution-Share Alike 2.1 Japan"
    },
    "scene": 0,
    "scenes": [{
        "name": "skeleton",
        "nodes": [len(nodes) - 1]
    }],
    "nodes": nodes,
    "meshes": meshes_json,
    "accessors": accessors,
    "bufferViews": buffer_views,
    "materials": materials,
    "buffers": [{
        "byteLength": len(bin_data)
    }]
}

json_str = json.dumps(gltf_json, separators=(',', ':'))
json_bytes = json_str.encode('utf-8')

while len(json_bytes) % 4 != 0:
    json_bytes += b' '

while len(bin_data) % 4 != 0:
    bin_data.append(0)

total_length = 12 + 8 + len(json_bytes) + 8 + len(bin_data)

header = struct.pack('<III', 0x46546C67, 2, total_length)
json_chunk_header = struct.pack('<II', len(json_bytes), 0x4E4F534A)
bin_chunk_header = struct.pack('<II', len(bin_data), 0x004E4942)

os.makedirs(os.path.dirname(OUTPUT_GLB), exist_ok=True)
with open(OUTPUT_GLB, 'wb') as f:
    f.write(header)
    f.write(json_chunk_header)
    f.write(json_bytes)
    f.write(bin_chunk_header)
    f.write(bin_data)

file_size = os.path.getsize(OUTPUT_GLB)
print(f"\nWrote {OUTPUT_GLB}")
print(f"File size: {file_size / 1024 / 1024:.1f} MB")
print(f"Meshes: {len(meshes_json)}")

# Write bone mapping
bone_mapping = []
for md in meshes_data:
    bone_mapping.append({
        'name': md['name'],
        'originalName': md['original_name'],
        'fmaId': md['fma_id'],
        'bpId': md['bp_id'],
    })

mapping_path = '/home/johanbellander/projects/BodyExplorer/raw_models/bone_mapping.json'
with open(mapping_path, 'w') as f:
    json.dump(bone_mapping, f, indent=2)
print(f"Wrote bone mapping to {mapping_path}")
