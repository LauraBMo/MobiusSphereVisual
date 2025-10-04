# File: examples/example.jl
using MobiusSphereVisual

# Example 1: Simple rotation
println("Creating rotation animation...")
rotation_axis = [0.0, 0.0, 1.0]
rotation_angle = π / 2
rotation_translation = [0.0, 0.0, 0.0]
MobiusSphereVisual.render_mobius_animation(
    rotation_axis,
    rotation_angle,
    rotation_translation;
    output="rotation.mp4",
    fps=30,
    resolution=(1280, 720),
    nframes=120,
    quality=:high,
)

# Example 2: Loxodromic transformation
println("Creating loxodromic animation...")
loxodromic_axis = [0.0, 0.0, 1.0]
loxodromic_angle = π / 3
loxodromic_translation = [0.25, 0.0, 0.15]
MobiusSphereVisual.render_mobius_animation(
    loxodromic_axis,
    loxodromic_angle,
    loxodromic_translation;
    output="loxodromic.mp4",
    fps=30,
    resolution=(1280, 720),
    nframes=150,
    quality=:high,
)

# Example 3: Custom transformation
println("Creating custom transformation...")
v = normalize([1.0, 1.0, 0.0])  # diagonal axis
theta = π/3
# Angles are still provided in radians; the library converts them to degrees for POV-Ray.
t = [0.5, 0.0, 0.5]  # diagonal translation

MobiusSphereVisual.render_mobius_animation(
    v, theta, t;
    output="custom_mobius.mp4",
    fps=24,
    resolution=(1920, 1080),
    nframes=120,
)

println("Custom animation created successfully!")
