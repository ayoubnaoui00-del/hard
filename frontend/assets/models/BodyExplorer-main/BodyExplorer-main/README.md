# Body Explorer

An interactive 3D human muscular system explorer built with [Three.js](https://threejs.org/). Browse, search, and study 467 anatomical structures — muscles, tendons, and connective tissue — rendered as a photorealistic écorché (body without skin) with a full 201-bone skeleton overlay.

**[Live Demo](https://johanbellander.github.io/BodyExplorer/)**

## Features

- **Photorealistic 3D anatomy** — MRI-based mesh data from BodyParts3D, supplemented by Z-Anatomy meshes for additional muscles
- **Full skeleton overlay** — 201 bone meshes with adjustable transparency
- **Click to identify** — click any muscle to see its name, muscle group, type, and links to Wikipedia and Kenhub
- **Search** — find muscles by name with live search results
- **Filter by muscle group** — toggle visibility of 14 muscle groups (head/neck, shoulder, chest, back, upper arm, forearm, abdomen, hip, upper leg, lower leg, hand, foot, trunk)
- **Hide and restore parts** — hide individual muscles to reveal deeper layers; restore them from the hidden parts panel
- **Custom color highlighting** — apply color swatches to any muscle for study or presentation
- **Dual transparency sliders** — independently control muscle and skeleton opacity
- **Preset camera views** — front, back, and side views with smooth transitions
- **Cursor-directed zoom** — scroll zooms toward where your cursor points
- **Dark theme UI** — clean, non-intrusive controls that stay out of the way

## Controls

| Input | Action |
|---|---|
| Left-click + drag | Rotate |
| Scroll wheel | Zoom (toward cursor) |
| Right-click + drag | Pan |
| Click a muscle | Show info panel |

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) (v18+)

### Install and Run

```bash
git clone https://github.com/JohanBellander/BodyExplorer.git
cd BodyExplorer
npm install
npx vite --host --port 4000
```

Open [http://localhost:4000](http://localhost:4000) in your browser.

### Build for Production

```bash
npm run build
```

The output is written to `dist/`.

## Tech Stack

- **Three.js** — 3D rendering, GLTFLoader, OrbitControls
- **Vite** — dev server and build tool
- **GitHub Actions** — automated deployment to GitHub Pages

## Data Sources

The 3D mesh data comes from two open anatomical datasets:

| Dataset | Meshes | Description |
|---|---|---|
| [BodyParts3D](https://lifesciencedb.jp/bp3d/) | 401 | MRI-based anatomical meshes from The Database Center for Life Science |
| [Z-Anatomy](https://www.z-anatomy.com/) | 66 | Community-built anatomical meshes by Gauthier Kervyn |

All meshes are decimated to ~4000 faces each for real-time performance. The two datasets are spatially aligned using calibrated Y and Z offsets.

## Project Structure

```
├── index.html              # App layout and UI
├── src/
│   ├── main.js             # Scene, camera, interaction, UI controls
│   ├── bodyBuilder.js      # GLB loading, coordinate transforms, materials
│   ├── muscleData.js       # Muscle groups, classification, anatomy database
│   └── styles.css          # Dark theme styling
├── public/
│   ├── anatomy.glb         # 467 muscle/tendon meshes (24 MB)
│   ├── skeleton.glb        # 201 bone meshes (9.4 MB)
│   └── mesh_mapping.json   # Mesh metadata and data source mapping
├── raw_models/             # Processing scripts (data not included in repo)
│   ├── find_muscles.py     # Discovers muscle OBJ files from BodyParts3D
│   ├── filter_muscles.py   # Filters to relevant anatomical structures
│   ├── decimate_anatomy.py # Decimates and merges BP3D + Z-Anatomy into anatomy.glb
│   ├── find_bones.py       # Discovers bone OBJ files
│   └── export_z_anatomy.py # Blender script to export Z-Anatomy meshes
└── .github/workflows/
    └── deploy.yml          # GitHub Pages deployment workflow
```

## Attribution

- **BodyParts3D**, &copy; The Database Center for Life Science, licensed under [CC Attribution-Share Alike 2.1 Japan](https://creativecommons.org/licenses/by-sa/2.1/jp/deed.en)
- **Z-Anatomy** by Gauthier Kervyn, licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)

## License

This project's source code is available under the [MIT License](https://opensource.org/licenses/MIT). The anatomical mesh data included in the `public/` directory is subject to the licenses of its respective data sources (see Attribution above).
