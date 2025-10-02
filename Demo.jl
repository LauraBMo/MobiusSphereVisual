using MobiusSphereVisual

# Define transformation parameters
axis = [0.0, 0.0, 1.0]
angle = pi / 2
trans = [0.2, 0.0, 0.0]

# Render the animation directly with the high level helper
render_mobius_animation(axis, angle, trans; output="examples/demo.mp4", nframes=120)

# If you already have Möbius coefficients (for example from the MobiusSphere
# package) you can pass them in as a named tuple or struct with `axis`, `angle`
# and `translation` fields:
coefficients = (axis = axis, angle = angle, translation = trans)
render_mobius_animation(coefficients; output="examples/demo_from_coeffs.mp4", nframes=120)
