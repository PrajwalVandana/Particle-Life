extends Node2D


func load_glsl(path: String, rd: RenderingDevice) -> RID:
	var shader_file = load(path)
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	return rd.shader_create_from_spirv(shader_spirv)


# Called when the node enters the scene tree for the first time.
func _ready():
	# Create a local rendering device.
	var rd = RenderingServer.create_local_rendering_device()

	# Load GLSL shader
	var shader_RID = load_glsl("res://compute_example.glsl", rd)

	# Prepare our data. We use floats in the shader, so we need 32 bit.
	var input = PackedFloat32Array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
	var input_bytes = input.to_byte_array()

	# Create a storage buffer that can hold our float values.
	# Each float has 4 bytes (32 bit) so 10 x 4 = 40 bytes
	var storage_buffer_RID = rd.storage_buffer_create(input_bytes.size(), input_bytes)

	# Create a uniform to assign the buffer to the rendering device
	# uniforms are used to pass readonly, constant data to the GPU
	var uniform = RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = 0  # this needs to match the "binding" in our shader file
	uniform.add_id(storage_buffer_RID)
	var uniform_set = rd.uniform_set_create([uniform], shader_RID, 0)  # the last parameter (the 0) needs to match the "set" in our shader file

	# Create a compute pipeline
	var pipeline_RID = rd.compute_pipeline_create(shader_RID)
	var compute_list_ID = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list_ID, pipeline_RID)
	rd.compute_list_bind_uniform_set(compute_list_ID, uniform_set, 0)
	# 5 workgroups in x direction, 1 in y and z direction (since we have 10 floats and 2 local invocations per workgroup)
	rd.compute_list_dispatch(compute_list_ID, 5, 1, 1)
	rd.compute_list_end()

	# Submit to GPU and wait for sync
	rd.submit()
	rd.sync()

	# Read back the data from the buffer
	var output_bytes = rd.buffer_get_data(storage_buffer_RID)
	var output = output_bytes.to_float32_array()
	print("Input: ", input)
	print("Output: ", output)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
