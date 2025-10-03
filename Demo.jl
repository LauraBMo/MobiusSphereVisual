using MobiusSphereVisual

# Define transformation parameters
axis = [0.0, 0.0, 1.0]
angle = pi / 2
trans = [0.2, 0.0, 0.0]

# Render the animation directly with the high level helper
render_mobius_animation(axis, angle, trans;
                        output="examples/demo.mp4",
                        fps=3,
                        resolution=(840, 420),
                        nframes=21,
                        quality=:draft,
                        keep_temp=false,
                        )
