"""
Regenerate anatomy.glb with decimated meshes for better performance.
Reduces face count per muscle mesh to improve rendering speed.
Combines meshes from BodyParts3D and Z-Anatomy sources.
"""
import json
import os
import struct
import numpy as np
import trimesh

BASE_DIR = '/home/johanbellander/projects/BodyExplorer/raw_models'
OBJ_DIR = os.path.join(BASE_DIR, 'bp3d/isa_BP3D_4.0_obj_99')
FILTERED_LIST = os.path.join(BASE_DIR, 'filtered_muscles.json')
ZA_EXPORTS_DIR = os.path.join(BASE_DIR, 'z_anatomy_exports')
ZA_MANIFEST = os.path.join(ZA_EXPORTS_DIR, 'manifest.json')
OUTPUT_GLB = '/home/johanbellander/projects/BodyExplorer/public/anatomy.glb'

# Z-Anatomy meshes are in meters; BP3D meshes are in millimeters.
# Scale Z-Anatomy by 1000 to convert to mm.
ZA_SCALE = 1000.0

# Z-Anatomy and BP3D use different coordinate origins.
# Both share X=0 center, but differ in Y (front-back) and Z (vertical) axes.
# BP3D body center Y ≈ -101mm (MRI scanner origin), ZA body center Y ≈ -1mm.
# Y offset determined by comparing posterior midline muscles at Z=900-1250mm.
# Z offset determined by comparing layered abdominal muscles (internal oblique,
# transversus abdominis, rectus abdominis vs external oblique): median +50mm too high.
ZA_Y_OFFSET = -96.0  # mm — front-back alignment
ZA_Z_OFFSET = -75.0  # mm — vertical alignment (calibrated via debug slider)

with open(FILTERED_LIST) as f:
    muscles = json.load(f)

print(f"Loading {len(muscles)} BP3D muscle/tendon OBJ files with decimation...")

meshes_data = []
seen_names = {}
total_original_faces = 0
total_decimated_faces = 0

def load_and_process_mesh(obj_path):
    """Load an OBJ, handle Scene vs Trimesh, validate geometry."""
    mesh = trimesh.load(obj_path, file_type='obj', process=True)
    if isinstance(mesh, trimesh.Scene):
        meshes_in_scene = []
        for geom in mesh.geometry.values():
            if hasattr(geom, 'vertices') and hasattr(geom, 'faces'):
                meshes_in_scene.append(geom)
        if meshes_in_scene:
            mesh = trimesh.util.concatenate(meshes_in_scene)
        else:
            return None
    if not hasattr(mesh, 'vertices') or not hasattr(mesh, 'faces'):
        return None
    if len(mesh.vertices) == 0 or len(mesh.faces) == 0:
        return None
    return mesh

def add_mesh(name, mesh, fma_id, bp_id, original_name, source='bp3d', scale=1.0, y_offset=0.0, z_offset=0.0):
    """Add a processed mesh to meshes_data with decimation."""
    global total_original_faces, total_decimated_faces

    if scale != 1.0:
        mesh.vertices = mesh.vertices * scale

    if y_offset != 0.0:
        mesh.vertices[:, 1] += y_offset

    if z_offset != 0.0:
        mesh.vertices[:, 2] += z_offset

    original_faces = len(mesh.faces)
    total_original_faces += original_faces

    target_faces = 4000
    if original_faces > target_faces:
        try:
            mesh = mesh.simplify_quadric_decimation(face_count=target_faces)
            print(f"  Decimated {name}: {original_faces} -> {len(mesh.faces)} faces")
        except Exception as e:
            print(f"  Decimation failed for {name}: {e}")

    total_decimated_faces += len(mesh.faces)

    final_name = name
    if name in seen_names:
        seen_names[name] += 1
        final_name = f"{name} ({seen_names[name]})"
    else:
        seen_names[name] = 1

    name_lower = original_name.lower()
    is_tendon = any(kw in name_lower for kw in [
        'tendon', 'ligament', 'retinaculum', 'membrane', 'plantar ligament',
        'fascia', 'tract', 'aponeurosis'
    ])

    meshes_data.append({
        'name': final_name,
        'vertices': np.array(mesh.vertices, dtype=np.float32),
        'faces': np.array(mesh.faces, dtype=np.uint32),
        'normals': np.array(mesh.vertex_normals, dtype=np.float32) if mesh.vertex_normals is not None and len(mesh.vertex_normals) > 0 else None,
        'is_tendon': is_tendon,
        'fma_id': fma_id,
        'bp_id': bp_id,
        'original_name': original_name,
        'source': source,
    })

# ── Load BP3D meshes ──
for i, m in enumerate(muscles):
    obj_path = os.path.join(OBJ_DIR, m['file'])
    if not os.path.exists(obj_path):
        continue

    try:
        mesh = load_and_process_mesh(obj_path)
    except Exception as e:
        print(f"  SKIP (error): {m['file']} - {e}")
        continue

    if mesh is None:
        continue

    add_mesh(m['name'], mesh, m['fma_id'], m['bp_id'], m['name'], source='bp3d')

    if (i + 1) % 50 == 0:
        print(f"  Loaded {i + 1}/{len(muscles)} BP3D...")

bp3d_count = len(meshes_data)
print(f"Loaded {bp3d_count} BP3D meshes")

# ── Load Z-Anatomy meshes ──
if os.path.exists(ZA_MANIFEST):
    with open(ZA_MANIFEST) as f:
        za_muscles = json.load(f)

    print(f"\nLoading {len(za_muscles)} Z-Anatomy muscle OBJ files...")

    for i, m in enumerate(za_muscles):
        obj_path = os.path.join(ZA_EXPORTS_DIR, m['file'])
        if not os.path.exists(obj_path):
            print(f"  SKIP (missing): {m['file']}")
            continue

        try:
            mesh = load_and_process_mesh(obj_path)
        except Exception as e:
            print(f"  SKIP (error): {m['file']} - {e}")
            continue

        if mesh is None:
            continue

        add_mesh(m['name'], mesh, '', '', m['name'], source='z-anatomy', scale=ZA_SCALE, y_offset=ZA_Y_OFFSET, z_offset=ZA_Z_OFFSET)

    za_count = len(meshes_data) - bp3d_count
    print(f"Loaded {za_count} Z-Anatomy meshes")
else:
    print(f"\nNo Z-Anatomy manifest found at {ZA_MANIFEST}, skipping.")

print(f"\nTotal meshes: {len(meshes_data)}")
print(f"Total faces: {total_original_faces} -> {total_decimated_faces} ({total_decimated_faces/total_original_faces*100:.0f}%)")

# Build GLB
buffer_views = []
accessors = []
meshes_json = []
nodes = []
bin_data = bytearray()

materials = [
    {
        "name": "muscle",
        "pbrMetallicRoughness": {
            "baseColorFactor": [0.6, 0.15, 0.12, 1.0],
            "metallicFactor": 0.0,
            "roughnessFactor": 0.7
        },
        "doubleSided": True
    },
    {
        "name": "tendon",
        "pbrMetallicRoughness": {
            "baseColorFactor": [0.9, 0.85, 0.75, 1.0],
            "metallicFactor": 0.0,
            "roughnessFactor": 0.5
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
            "material": 1 if md['is_tendon'] else 0
        }]
    }
    mesh_idx = len(meshes_json)
    meshes_json.append(mesh_json)

    nodes.append({
        "name": md['name'],
        "mesh": mesh_idx
    })

root_children = list(range(len(nodes)))
nodes.append({
    "name": "BodyMuscles",
    "children": root_children
})

gltf_json = {
    "asset": {
        "version": "2.0",
        "generator": "BodyExplorer OBJ-to-GLB converter (decimated)",
        "copyright": "BodyParts3D, (c) The Database Center for Life Science licensed under CC Attribution-Share Alike 2.1 Japan. Z-Anatomy by Gauthier Kervyn licensed under CC BY-SA 4.0."
    },
    "scene": 0,
    "scenes": [{
        "name": "anatomy",
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

mapping = []
for md in meshes_data:
    mapping.append({
        'name': md['name'],
        'originalName': md['original_name'],
        'fmaId': md['fma_id'],
        'bpId': md['bp_id'],
        'isTendon': md['is_tendon'],
        'source': md['source'],
    })

mapping_path = '/home/johanbellander/projects/BodyExplorer/raw_models/mesh_mapping.json'
with open(mapping_path, 'w') as f:
    json.dump(mapping, f, indent=2)
print(f"Wrote mesh mapping to {mapping_path}")
