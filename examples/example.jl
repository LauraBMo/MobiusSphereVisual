# File: examples/example.jl
using MobiusSphereVisual

# Example 1: Simple rotation
println("Creating rotation animation...")
MobiusSphereVisual.example_rotation_animation()

# Example 2: Loxodromic transformation
println("Creating loxodromic animation...")
MobiusSphereVisual.example_loxodromic_animation()

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
