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

render_mobius_animation(axis, angle, trans;
    output="examples/demo.mp4",
    fps=3,
    resolution=(840, 420),
    nframes=21,
    quality=:ultra,
    # quality=:draft,
    keep_temp=false,
    # sampling=(
    #     antialias="On",
    #     antialias_depth=7,
    #     sampling_method=2,
    #     antialias_threshold=0.015,
    #     flags="+A0.015\n+AM2 +R9\n+Q13\n+UA\nRadiosity=On\nPhotons=On",
    # )
                        )
