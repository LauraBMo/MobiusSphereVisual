# Möbius Sphere POV-Ray Scene

This project contains a refactored POV-Ray scene featuring a "Möbius-ball" - a blurry unit sphere with a light at the North Pole and a rainbow-colored grid covering the bottom half up to 0.8 in height, representing the image of the unit circle by stereographic projection.

## File Structure

- `mobius_template.pov` - Main scene file that includes all components
- `mobius_macros.inc` - Contains all macro definitions for the scene
- `mobius_textures.inc` - Contains texture declarations
- `mobius_scene.inc` - Contains scene configuration (camera, lights, etc.)
- `render.ini` - Rendering configuration template

## Scene Description

The scene consists of:

1. **Floor**: A gray checker pattern
2. **Möbius Ball**: A translucent unit sphere with:
   - A light source at the North Pole
   - A rainbow-colored grid covering the bottom half up to y = 0.8
   - A glass-like appearance for the "blurry" effect
3. **Camera**: Positioned to view the scene optimally
4. **Lighting**: Background lighting with a dynamic light at the sphere's North Pole

## Key Features

- The Möbius ball represents the stereographic projection of the unit circle
- The rainbow coloring represents argument (phase) values
- The sphere has a translucent, glass-like appearance
- The scene is animated with transformations based on the clock variable