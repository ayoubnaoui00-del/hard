"""
Export missing muscle meshes from Z-Anatomy Blender file as individual OBJ files.
These are structures not present in BodyParts3D that we want to add.
"""
import bpy
import os
import json

# Open the Z-Anatomy blend file
BLEND_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'z-anatomy', 'extracted', 'Z-Anatomy', 'Startup.blend')
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'z_anatomy_exports')

bpy.ops.wm.open_mainfile(filepath=BLEND_PATH)

os.makedirs(OUTPUT_DIR, exist_ok=True)

# Define the muscles we want to extract
# Format: (search_pattern, canonical_name, side_handling)
# side_handling: 'both' = export .l and .r, 'single' = no side suffix
TARGETS = [
    # Major muscles missing from BP3D
    ('Latissimus dorsi muscle', 'latissimus dorsi', 'both'),
    ('Rectus abdominis muscle', 'rectus abdominis', 'both'),
    ('Internal abdominal oblique muscle', 'internal oblique', 'both'),
    ('Transversus abdominis muscle', 'transversus abdominis', 'both'),
    ('Quadratus lumborum muscle', 'quadratus lumborum', 'both'),

    # Muscles of mastication
    ('Superficial part of masseter', 'superficial part of masseter', 'both'),
    ('Deep part of masseter', 'deep part of masseter', 'both'),
    ('Temporalis muscle', 'temporalis', 'both'),
    ('Medial pterygoid muscle', 'medial pterygoid', 'both'),
    ('Inferior head of lateral pterygoid muscle', 'inferior head of lateral pterygoid', 'both'),
    ('Superior head of lateral pterygoid muscle', 'superior head of lateral pterygoid', 'both'),

    # Facial expression muscles
    ('Frontalis muscle', 'frontalis', 'both'),
    ('Orbital part of orbicularis oculi', 'orbital part of orbicularis oculi', 'both'),
    ('Palpebral part of orbicularis oculi', 'palpebral part of orbicularis oculi', 'both'),
    ('Orbicularis oris muscle', 'orbicularis oris', 'both'),
    ('Buccinator muscle', 'buccinator', 'both'),
    ('Zygomaticus major muscle', 'zygomaticus major', 'both'),
    ('Zygomaticus minor muscle', 'zygomaticus minor', 'both'),
    ('Levator labii superioris', 'levator labii superioris', 'both'),
    ('Depressor labii inferioris', 'depressor labii inferioris', 'both'),
    ('Depressor anguli oris', 'depressor anguli oris', 'both'),
    ('Risorius muscle', 'risorius', 'both'),
    ('Mentalis muscle', 'mentalis', 'both'),
    ('Procerus muscle', 'procerus', 'both'),
    ('Nasalis muscle', 'nasalis', 'both'),
    ('Corrugator supercilii', 'corrugator supercilii', 'both'),

    # Deep back muscles
    ('Multifidus colli muscle', 'multifidus cervicis', 'both'),
    ('Multifidus thoracis muscle', 'multifidus thoracis', 'both'),
    ('Multifidus lumborum muscle', 'multifidus lumborum', 'both'),
    ('Rotatores', 'rotatores', 'both'),

    # IT band
    ('Iliotibial tract', 'iliotibial tract', 'both'),

    # Thoracolumbar fascia
    ('Posterior layer of thoracolumbar fascia', 'posterior layer of thoracolumbar fascia', 'both'),
    ('Anterior layer of thoracolumbar fascia', 'anterior layer of thoracolumbar fascia', 'both'),
    ('Middle layer of thoracolumbar fascia', 'middle layer of thoracolumbar fascia', 'both'),
]

exported = []
skipped = []

for search_name, canonical_name, side_handling in TARGETS:
    if side_handling == 'both':
        sides = [('.l', 'left'), ('.r', 'right')]
    else:
        sides = [('', '')]

    for suffix, side_label in sides:
        obj_name = search_name + suffix
        obj = bpy.data.objects.get(obj_name)

        if obj is None:
            skipped.append(f"{obj_name} (not found)")
            continue

        if obj.type != 'MESH':
            skipped.append(f"{obj_name} (not a mesh, type={obj.type})")
            continue

        mesh = obj.data
        if len(mesh.polygons) < 5:
            skipped.append(f"{obj_name} (too few faces: {len(mesh.polygons)})")
            continue

        # Build the output name
        if side_label:
            out_name = f"{side_label} {canonical_name}"
        else:
            out_name = canonical_name

        # Create a safe filename
        safe_name = out_name.replace(' ', '_').replace('(', '').replace(')', '')
        obj_path = os.path.join(OUTPUT_DIR, f"{safe_name}.obj")

        # Get the evaluated mesh with modifiers applied
        depsgraph = bpy.context.evaluated_depsgraph_get()
        eval_obj = obj.evaluated_get(depsgraph)
        eval_mesh = eval_obj.to_mesh()

        # Get world transform matrix
        matrix = obj.matrix_world

        # Write OBJ manually to apply world transform
        with open(obj_path, 'w') as f:
            f.write(f"# Z-Anatomy export: {out_name}\n")
            f.write(f"# Original object: {obj_name}\n")
            f.write(f"o {out_name}\n")

            # Write vertices with world transform applied
            for v in eval_mesh.vertices:
                co = matrix @ v.co
                f.write(f"v {co.x:.6f} {co.y:.6f} {co.z:.6f}\n")

            # Write normals
            for v in eval_mesh.vertices:
                no = (matrix.to_3x3() @ v.normal).normalized()
                f.write(f"vn {no.x:.6f} {no.y:.6f} {no.z:.6f}\n")

            # Write faces (1-indexed)
            for poly in eval_mesh.polygons:
                indices = ' '.join(f"{vi+1}//{vi+1}" for vi in poly.vertices)
                f.write(f"f {indices}\n")

        faces_count = len(mesh.polygons)
        print(f"  Exported: {out_name} ({faces_count} faces) -> {obj_path}")
        exported.append({
            'name': out_name,
            'file': f"{safe_name}.obj",
            'faces': faces_count,
            'source': 'z-anatomy',
            'original_object': obj_name,
        })

        eval_obj.to_mesh_clear()

# Write manifest
manifest_path = os.path.join(OUTPUT_DIR, 'manifest.json')
with open(manifest_path, 'w') as f:
    json.dump(exported, f, indent=2)

print(f"\n=== SUMMARY ===")
print(f"Exported: {len(exported)} meshes")
print(f"Skipped: {len(skipped)}")
for s in skipped:
    print(f"  SKIP: {s}")
print(f"Manifest: {manifest_path}")
