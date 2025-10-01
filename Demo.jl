using MobiusSphereVisual

# Define transformation
axis = [0.0, 0.0, 1.0]
angle = pi/2
trans = [0.2, 0.0, 0.0]

# Write motion
write_motion("pov/Motion.inc", axis, angle, trans)

# Run POV-Ray + ffmpeg
run_animation("pov/scene.pov", output="examples/demo.mp4", frames=120)
