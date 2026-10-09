"""
Convert filtered BodyParts3D OBJ files into a single GLB file.
Each mesh is named with its sanitized anatomical name for raycasting in Three.js.

Uses trimesh for OBJ loading and glTF export.
"""
import json
import os
import sys
import re
import struct
import numpy as np

OBJ_DIR = '/home/johanbellander/projects/BodyExplorer/raw_models/bp3d/isa_BP3D_4.0_obj_99'
FILTERED_LIST = '/home/johanbellander/projects/BodyExplorer/raw_models/filtered_muscles.json'
OUTPUT_GLB = '/home/johanbellander/projects/BodyExplorer/public/anatomy.glb'

# Load filtered muscle list
with open(FILTERED_LIST) as f:
    muscles = json.load(f)

print(f"Loading {len(muscles)} muscle/tendon OBJ files...")

# We'll build the GLB manually using the binary glTF 2.0 spec
# to avoid trimesh's scene export limitations with mesh naming.
#
# Strategy: use trimesh to parse each OBJ into vertices/faces,
# then write a custom GLB with proper mesh names.

import trimesh

# Collect all mesh data
meshes_data = []
seen_names = {}

for i, m in enumerate(muscles):
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
        # Merge all geometries in the scene
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
    
    # Sanitize name for use as mesh name in glTF
    name = m['name']
    # Handle duplicate names by appending file ID
    if name in seen_names:
        seen_names[name] += 1
        name = f"{name} ({seen_names[name]})"
    else:
        seen_names[name] = 1
    
    # Determine if this is a tendon/ligament vs muscle
    name_lower = m['name'].lower()
    is_tendon = any(kw in name_lower for kw in ['tendon', 'ligament', 'retinaculum', 'membrane', 'plantar ligament'])
    
    meshes_data.append({
        'name': name,
        'vertices': np.array(mesh.vertices, dtype=np.float32),
        'faces': np.array(mesh.faces, dtype=np.uint32),
        'normals': np.array(mesh.vertex_normals, dtype=np.float32) if mesh.vertex_normals is not None and len(mesh.vertex_normals) > 0 else None,
        'is_tendon': is_tendon,
        'fma_id': m['fma_id'],
        'bp_id': m['bp_id'],
        'original_name': m['name'],
    })
    
    if (i + 1) % 50 == 0:
        print(f"  Loaded {i + 1}/{len(muscles)}...")

print(f"Loaded {len(meshes_data)} meshes successfully")

# Now build GLB manually
# glTF 2.0 binary format:
# - 12-byte header
# - JSON chunk (padded to 4-byte boundary)  
# - Binary chunk (padded to 4-byte boundary)

# We need two materials: muscle (red) and tendon (white)
# Build the JSON structure

buffer_views = []
accessors = []
meshes_json = []
nodes = []
bin_data = bytearray()

# Materials
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
    
    # Ensure faces fit in uint16 if possible, otherwise uint32
    max_index = faces.max()
    if max_index <= 65535:
        index_data = faces.astype(np.uint16).tobytes()
        index_component_type = 5123  # UNSIGNED_SHORT
    else:
        index_data = faces.astype(np.uint32).tobytes()
        index_component_type = 5125  # UNSIGNED_INT
    
    vert_data = verts.tobytes()
    
    # Pad binary data to 4-byte boundary
    while len(bin_data) % 4 != 0:
        bin_data.append(0)
    
    # Index buffer view
    index_bv_offset = len(bin_data)
    bin_data.extend(index_data)
    index_bv_idx = len(buffer_views)
    buffer_views.append({
        "buffer": 0,
        "byteOffset": index_bv_offset,
        "byteLength": len(index_data),
        "target": 34963  # ELEMENT_ARRAY_BUFFER
    })
    
    # Pad
    while len(bin_data) % 4 != 0:
        bin_data.append(0)
    
    # Vertex buffer view
    vert_bv_offset = len(bin_data)
    bin_data.extend(vert_data)
    vert_bv_idx = len(buffer_views)
    buffer_views.append({
        "buffer": 0,
        "byteOffset": vert_bv_offset,
        "byteLength": len(vert_data),
        "byteStride": 12,
        "target": 34962  # ARRAY_BUFFER
    })
    
    # Index accessor
    index_acc_idx = len(accessors)
    accessors.append({
        "bufferView": index_bv_idx,
        "byteOffset": 0,
        "componentType": index_component_type,
        "count": faces.size,  # total number of indices
        "type": "SCALAR",
        "max": [int(max_index)],
        "min": [0]
    })
    
    # Position accessor
    pos_acc_idx = len(accessors)
    vmin = verts.min(axis=0).tolist()
    vmax = verts.max(axis=0).tolist()
    accessors.append({
        "bufferView": vert_bv_idx,
        "byteOffset": 0,
        "componentType": 5126,  # FLOAT
        "count": len(verts),
        "type": "VEC3",
        "max": vmax,
        "min": vmin
    })
    
    # Normal accessor (if available)
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
    
    # Mesh
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
    
    # Node
    nodes.append({
        "name": md['name'],
        "mesh": mesh_idx
    })

# Root node (contains all children)
root_children = list(range(len(nodes)))
nodes.append({
    "name": "BodyMuscles",
    "children": root_children
})

# Build the glTF JSON
gltf_json = {
    "asset": {
        "version": "2.0",
        "generator": "BodyExplorer OBJ-to-GLB converter",
        "copyright": "BodyParts3D, (c) The Database Center for Life Science licensed under CC Attribution-Share Alike 2.1 Japan"
    },
    "scene": 0,
    "scenes": [{
        "name": "anatomy",
        "nodes": [len(nodes) - 1]  # root node
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

# Serialize JSON
json_str = json.dumps(gltf_json, separators=(',', ':'))
json_bytes = json_str.encode('utf-8')

# Pad JSON to 4-byte boundary with spaces
while len(json_bytes) % 4 != 0:
    json_bytes += b' '

# Pad binary to 4-byte boundary
while len(bin_data) % 4 != 0:
    bin_data.append(0)

# GLB header
total_length = 12 + 8 + len(json_bytes) + 8 + len(bin_data)

header = struct.pack('<III', 0x46546C67, 2, total_length)  # magic, version, length
json_chunk_header = struct.pack('<II', len(json_bytes), 0x4E4F534A)  # length, type=JSON
bin_chunk_header = struct.pack('<II', len(bin_data), 0x004E4942)  # length, type=BIN

# Write GLB
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
print(f"Nodes: {len(nodes)}")

# Also write mesh name mapping for the frontend
mapping = []
for md in meshes_data:
    mapping.append({
        'name': md['name'],
        'originalName': md['original_name'],
        'fmaId': md['fma_id'],
        'bpId': md['bp_id'],
        'isTendon': md['is_tendon']
    })

mapping_path = '/home/johanbellander/projects/BodyExplorer/raw_models/mesh_mapping.json'
with open(mapping_path, 'w') as f:
    json.dump(mapping, f, indent=2)
print(f"Wrote mesh mapping to {mapping_path}")
