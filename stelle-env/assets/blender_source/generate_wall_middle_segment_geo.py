from __future__ import annotations

from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[3]
ENV_ROOT = ROOT / "stelle-env"
BLENDER_SOURCE_DIR = ENV_ROOT / "assets" / "blender_source"
MESH_DIR = ENV_ROOT / "assets" / "mesh"
MATERIAL_DIR = ENV_ROOT / "assets" / "material"

BLEND_PATH = BLENDER_SOURCE_DIR / "wall_middle_segment_geo.blend"
GLB_PATH = MESH_DIR / "wall_middle_segment_geo.glb"
PREVIEW_PATH = BLENDER_SOURCE_DIR / "wall_middle_segment_geo_preview.png"


DEFAULTS = {
    "length": 6.0,
    "height": 3.0,
    "thickness": 0.45,
    "panel_columns": 3,
    "panel_rows": 3,
    "top_cap_height": 0.34,
    "top_cap_overhang": 0.16,
    "base_height": 0.55,
    "base_overhang": 0.18,
    "groove_depth": 0.025,
    "groove_width": 0.035,
    "block_bevel": 0.035,
    "blue_trim_height": 0.14,
}


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    for datablock in (
        bpy.data.meshes,
        bpy.data.materials,
        bpy.data.images,
        bpy.data.node_groups,
    ):
        for item in list(datablock):
            if item.users == 0:
                datablock.remove(item)


def make_preview_material(name: str, folder: str, texture_stem: str) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.diffuse_color = (0.55, 0.55, 0.52, 1.0)
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    if bsdf is None:
        return mat

    texcoord = nodes.new("ShaderNodeTexCoord")
    texcoord.location = (-900, 220)
    mapping = nodes.new("ShaderNodeMapping")
    mapping.location = (-700, 220)
    links.new(texcoord.outputs["Object"], mapping.inputs["Vector"])

    diff_path = MATERIAL_DIR / folder / f"{texture_stem}_diff_2k.png"
    normal_path = MATERIAL_DIR / folder / f"{texture_stem}_nor_gl_2k.png"
    arm_path = MATERIAL_DIR / folder / f"{texture_stem}_arm_2k.png"

    if diff_path.exists():
        tex = nodes.new("ShaderNodeTexImage")
        tex.name = f"{name}_albedo"
        tex.location = (-470, 220)
        tex.image = bpy.data.images.load(str(diff_path))
        links.new(mapping.outputs["Vector"], tex.inputs["Vector"])
        links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])

    if normal_path.exists():
        tex = nodes.new("ShaderNodeTexImage")
        tex.name = f"{name}_normal"
        tex.location = (-470, -20)
        tex.image = bpy.data.images.load(str(normal_path))
        tex.image.colorspace_settings.name = "Non-Color"
        normal = nodes.new("ShaderNodeNormalMap")
        normal.location = (-220, -20)
        normal.inputs["Strength"].default_value = 0.45
        links.new(mapping.outputs["Vector"], tex.inputs["Vector"])
        links.new(tex.outputs["Color"], normal.inputs["Color"])
        links.new(normal.outputs["Normal"], bsdf.inputs["Normal"])

    if arm_path.exists():
        arm = nodes.new("ShaderNodeTexImage")
        arm.name = f"{name}_arm_preview"
        arm.location = (-470, -240)
        arm.image = bpy.data.images.load(str(arm_path))
        arm.image.colorspace_settings.name = "Non-Color"
        sep = nodes.new("ShaderNodeSeparateColor")
        sep.location = (-220, -240)
        links.new(mapping.outputs["Vector"], arm.inputs["Vector"])
        links.new(arm.outputs["Color"], sep.inputs["Color"])
        links.new(sep.outputs["Green"], bsdf.inputs["Roughness"])

    return mat


def make_dark_material() -> bpy.types.Material:
    mat = bpy.data.materials.new("wall_dark_groove_concrete")
    mat.use_nodes = True
    mat.diffuse_color = (0.12, 0.12, 0.11, 1.0)
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (0.10, 0.10, 0.095, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.92
    return mat


def make_materials() -> dict[str, bpy.types.Material]:
    return {
        "concrete": make_preview_material(
            "wall_concrete_panel_3x3",
            "wall_concrete_panel_3x3",
            "wall_concrete_panel_3x3",
        ),
        "blue": make_preview_material(
            "wall_blue_painted_concrete",
            "wall_blue_painted_concrete",
            "wall_blue_painted_concrete",
        ),
        "dark": make_dark_material(),
    }


def new_value(group: bpy.types.GeometryNodeTree, value: float, x: float, y: float):
    node = group.nodes.new("ShaderNodeValue")
    node.location = (x, y)
    node.outputs["Value"].default_value = value
    return node.outputs["Value"]


def new_math(
    group: bpy.types.GeometryNodeTree,
    operation: str,
    a,
    b,
    x: float,
    y: float,
):
    node = group.nodes.new("ShaderNodeMath")
    node.operation = operation
    node.location = (x, y)
    group.links.new(a, node.inputs[0])
    group.links.new(b, node.inputs[1])
    return node.outputs["Value"]


def new_combine_xyz(group: bpy.types.GeometryNodeTree, x_value, y_value, z_value, x: float, y: float):
    node = group.nodes.new("ShaderNodeCombineXYZ")
    node.location = (x, y)
    group.links.new(x_value, node.inputs["X"])
    group.links.new(y_value, node.inputs["Y"])
    group.links.new(z_value, node.inputs["Z"])
    return node.outputs["Vector"]


def add_box(
    group: bpy.types.GeometryNodeTree,
    join_node: bpy.types.Node,
    material: bpy.types.Material,
    size_xyz,
    location_xyz,
    x: float,
    y: float,
) -> None:
    cube = group.nodes.new("GeometryNodeMeshCube")
    cube.location = (x, y)
    cube.inputs["Vertices X"].default_value = 2
    cube.inputs["Vertices Y"].default_value = 2
    cube.inputs["Vertices Z"].default_value = 2
    group.links.new(size_xyz, cube.inputs["Size"])

    transform = group.nodes.new("GeometryNodeTransform")
    transform.location = (x + 210, y)
    group.links.new(cube.outputs["Mesh"], transform.inputs["Geometry"])
    group.links.new(location_xyz, transform.inputs["Translation"])

    set_material = group.nodes.new("GeometryNodeSetMaterial")
    set_material.location = (x + 430, y)
    set_material.inputs["Material"].default_value = material
    group.links.new(transform.outputs["Geometry"], set_material.inputs["Geometry"])
    group.links.new(set_material.outputs["Geometry"], join_node.inputs["Geometry"])


def add_float_socket(group: bpy.types.GeometryNodeTree, name: str, default: float, minimum: float = 0.0):
    socket = group.interface.new_socket(name=name, in_out="INPUT", socket_type="NodeSocketFloat")
    socket.default_value = default
    socket.min_value = minimum
    return socket


def add_int_socket(group: bpy.types.GeometryNodeTree, name: str, default: int, minimum: int = 1):
    socket = group.interface.new_socket(name=name, in_out="INPUT", socket_type="NodeSocketInt")
    socket.default_value = default
    socket.min_value = minimum
    return socket


def make_geometry_node_group(materials: dict[str, bpy.types.Material]) -> bpy.types.GeometryNodeTree:
    group = bpy.data.node_groups.new("wall_middle_segment_geo_nodes", "GeometryNodeTree")
    add_float_socket(group, "length", DEFAULTS["length"], 0.5)
    add_float_socket(group, "height", DEFAULTS["height"], 0.8)
    add_float_socket(group, "thickness", DEFAULTS["thickness"], 0.05)
    add_int_socket(group, "panel_columns", DEFAULTS["panel_columns"], 1)
    add_int_socket(group, "panel_rows", DEFAULTS["panel_rows"], 1)
    add_float_socket(group, "top_cap_height", DEFAULTS["top_cap_height"], 0.05)
    add_float_socket(group, "top_cap_overhang", DEFAULTS["top_cap_overhang"], 0.0)
    add_float_socket(group, "base_height", DEFAULTS["base_height"], 0.05)
    add_float_socket(group, "base_overhang", DEFAULTS["base_overhang"], 0.0)
    add_float_socket(group, "groove_depth", DEFAULTS["groove_depth"], 0.0)
    add_float_socket(group, "groove_width", DEFAULTS["groove_width"], 0.005)
    add_float_socket(group, "block_bevel", DEFAULTS["block_bevel"], 0.0)
    add_float_socket(group, "blue_trim_height", DEFAULTS["blue_trim_height"], 0.02)
    group.interface.new_socket(name="Geometry", in_out="OUTPUT", socket_type="NodeSocketGeometry")

    group_input = group.nodes.new("NodeGroupInput")
    group_input.location = (-1500, 0)
    group_output = group.nodes.new("NodeGroupOutput")
    group_output.location = (1900, 0)

    join = group.nodes.new("GeometryNodeJoinGeometry")
    join.location = (1500, 0)
    group.links.new(join.outputs["Geometry"], group_output.inputs["Geometry"])

    sockets = {output.name: output for output in group_input.outputs}
    length = sockets["length"]
    height = sockets["height"]
    thickness = sockets["thickness"]
    top_h = sockets["top_cap_height"]
    top_o = sockets["top_cap_overhang"]
    base_h = sockets["base_height"]
    base_o = sockets["base_overhang"]
    groove_w = sockets["groove_width"]
    blue_h = sockets["blue_trim_height"]

    zero = new_value(group, 0.0, -1450, -760)
    one = new_value(group, 1.0, -1450, -820)
    two = new_value(group, 2.0, -1450, -880)
    minus_one = new_value(group, -1.0, -1450, -940)
    eps = new_value(group, 0.012, -1450, -1000)
    small = new_value(group, 0.018, -1450, -1060)

    half_thickness = new_math(group, "DIVIDE", thickness, two, -1230, -40)
    half_top_h = new_math(group, "DIVIDE", top_h, two, -1230, -100)
    half_base_h = new_math(group, "DIVIDE", base_h, two, -1230, -160)
    half_blue_h = new_math(group, "DIVIDE", blue_h, two, -1230, -220)
    top_o2 = new_math(group, "MULTIPLY", top_o, two, -1230, -280)
    base_o2 = new_math(group, "MULTIPLY", base_o, two, -1230, -340)

    body_h_tmp = new_math(group, "SUBTRACT", height, base_h, -1010, 40)
    body_h = new_math(group, "SUBTRACT", body_h_tmp, top_h, -790, 40)
    half_body_h = new_math(group, "DIVIDE", body_h, two, -570, 40)
    body_z = new_math(group, "ADD", base_h, half_body_h, -350, 40)
    cap_z = new_math(group, "SUBTRACT", height, half_top_h, -350, -80)
    base_z = half_base_h

    top_len = new_math(group, "ADD", length, top_o2, -1010, -260)
    base_len = new_math(group, "ADD", length, base_o2, -1010, -320)
    top_depth_tmp = new_math(group, "ADD", thickness, top_o2, -1010, -380)
    base_depth_tmp = new_math(group, "ADD", thickness, base_o2, -1010, -440)

    front_body_y = new_math(group, "MULTIPLY", half_thickness, minus_one, -790, -500)
    front_top_tmp = new_math(group, "ADD", half_thickness, top_o, -790, -560)
    front_top_y = new_math(group, "MULTIPLY", new_math(group, "ADD", front_top_tmp, eps, -570, -560), minus_one, -350, -560)
    front_base_tmp = new_math(group, "ADD", half_thickness, base_o, -790, -620)
    front_base_y = new_math(group, "MULTIPLY", new_math(group, "ADD", front_base_tmp, eps, -570, -620), minus_one, -350, -620)

    body_size = new_combine_xyz(group, length, thickness, body_h, -120, 260)
    body_loc = new_combine_xyz(group, zero, zero, body_z, -120, 200)
    add_box(group, join, materials["concrete"], body_size, body_loc, 120, 280)

    cap_size = new_combine_xyz(group, top_len, top_depth_tmp, top_h, -120, 80)
    cap_loc = new_combine_xyz(group, zero, zero, cap_z, -120, 20)
    add_box(group, join, materials["concrete"], cap_size, cap_loc, 120, 80)

    base_size = new_combine_xyz(group, base_len, base_depth_tmp, base_h, -120, -120)
    base_loc = new_combine_xyz(group, zero, zero, base_z, -120, -180)
    add_box(group, join, materials["concrete"], base_size, base_loc, 120, -120)

    top_strip_size = new_combine_xyz(group, top_len, small, blue_h, -120, -340)
    top_strip_loc = new_combine_xyz(group, zero, front_top_y, cap_z, -120, -400)
    add_box(group, join, materials["blue"], top_strip_size, top_strip_loc, 120, -340)

    body_strip_z = new_math(group, "ADD", base_h, half_blue_h, -350, -700)
    body_strip_size = new_combine_xyz(group, length, small, blue_h, -120, -520)
    body_strip_loc = new_combine_xyz(group, zero, front_body_y, body_strip_z, -120, -580)
    add_box(group, join, materials["blue"], body_strip_size, body_strip_loc, 120, -520)

    base_strip_z = new_math(group, "ADD", half_blue_h, small, -350, -760)
    base_strip_size = new_combine_xyz(group, base_len, small, blue_h, -120, -700)
    base_strip_loc = new_combine_xyz(group, zero, front_base_y, base_strip_z, -120, -760)
    add_box(group, join, materials["blue"], base_strip_size, base_strip_loc, 120, -700)

    # Fixed 3x3 panel grooves match the current texture. The row/column sockets are
    # kept as exposed design parameters for the next version of the node graph.
    for idx, ratio in enumerate((-1.0 / 6.0, 1.0 / 6.0)):
        x_pos = new_math(group, "MULTIPLY", length, new_value(group, ratio, -1240, -1160 - idx * 40), -790, -1040 - idx * 80)
        groove_size = new_combine_xyz(group, groove_w, small, body_h, -120, -900 - idx * 80)
        groove_loc = new_combine_xyz(group, x_pos, front_body_y, body_z, -120, -960 - idx * 80)
        add_box(group, join, materials["dark"], groove_size, groove_loc, 120, -920 - idx * 90)

    for idx, ratio in enumerate((1.0 / 3.0, 2.0 / 3.0)):
        part = new_math(group, "MULTIPLY", body_h, new_value(group, ratio, -1240, -1260 - idx * 40), -790, -1220 - idx * 80)
        z_pos = new_math(group, "ADD", base_h, part, -570, -1220 - idx * 80)
        groove_size = new_combine_xyz(group, length, small, groove_w, -120, -1120 - idx * 80)
        groove_loc = new_combine_xyz(group, zero, front_body_y, z_pos, -120, -1180 - idx * 80)
        add_box(group, join, materials["dark"], groove_size, groove_loc, 120, -1120 - idx * 90)

    # Cap and base block separators: six modules across the length.
    for i, ratio in enumerate((-2.0 / 6.0, -1.0 / 6.0, 0.0, 1.0 / 6.0, 2.0 / 6.0)):
        cap_x = new_math(group, "MULTIPLY", length, new_value(group, ratio, -1240, -1450 - i * 35), -790, -1450 - i * 55)
        cap_groove_size = new_combine_xyz(group, groove_w, small, top_h, -120, -1370 - i * 60)
        cap_groove_loc = new_combine_xyz(group, cap_x, front_top_y, cap_z, -120, -1420 - i * 60)
        add_box(group, join, materials["dark"], cap_groove_size, cap_groove_loc, 120, -1370 - i * 70)

        base_x = new_math(group, "MULTIPLY", length, new_value(group, ratio, -1240, -1740 - i * 35), -790, -1740 - i * 55)
        base_groove_size = new_combine_xyz(group, groove_w, small, base_h, -120, -1710 - i * 60)
        base_groove_loc = new_combine_xyz(group, base_x, front_base_y, base_z, -120, -1760 - i * 60)
        add_box(group, join, materials["dark"], base_groove_size, base_groove_loc, 120, -1710 - i * 70)

    group.name = "wall_middle_segment_geo_nodes"
    return group


def make_wall_object(materials: dict[str, bpy.types.Material]) -> bpy.types.Object:
    mesh = bpy.data.meshes.new("wall_middle_segment_geo_seed_mesh")
    obj = bpy.data.objects.new("wall_middle_segment_geo", mesh)
    bpy.context.collection.objects.link(obj)
    for material in (materials["concrete"], materials["blue"], materials["dark"]):
        obj.data.materials.append(material)

    node_group = make_geometry_node_group(materials)
    geo = obj.modifiers.new("wall_middle_segment_geo_nodes", "NODES")
    geo.node_group = node_group

    bevel = obj.modifiers.new("wall_middle_segment_bevel", "BEVEL")
    bevel.width = DEFAULTS["block_bevel"]
    bevel.segments = 2
    bevel.affect = "EDGES"

    normal = obj.modifiers.new("wall_middle_segment_weighted_normals", "WEIGHTED_NORMAL")
    normal.keep_sharp = True

    obj["asset_note"] = (
        "Geometry Nodes wall middle segment. Use this .blend as the parametric source; "
        "the exported GLB is the realized Godot runtime mesh."
    )
    for key, value in DEFAULTS.items():
        obj[key] = value

    return obj


def add_reference_grid() -> None:
    bpy.ops.mesh.primitive_plane_add(size=8.0, location=(0, 0.72, -0.006))
    floor = bpy.context.object
    floor.name = "preview_floor"
    mat = bpy.data.materials.new("preview_matte_floor")
    mat.diffuse_color = (0.28, 0.28, 0.27, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (0.28, 0.28, 0.27, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.9
    floor.data.materials.append(mat)
    floor.hide_select = True


def setup_camera_and_lights() -> None:
    bpy.ops.object.light_add(type="AREA", location=(-2.6, -4.2, 5.2))
    key = bpy.context.object
    key.name = "preview_key_area"
    key.data.energy = 900
    key.data.size = 5.5

    bpy.ops.object.light_add(type="POINT", location=(3.2, -2.8, 2.4))
    fill = bpy.context.object
    fill.name = "preview_fill_point"
    fill.data.energy = 120

    bpy.ops.object.camera_add(location=(4.8, -6.4, 2.45), rotation=(1.22, 0.0, 0.64))
    camera = bpy.context.object
    direction = bpy.mathutils.Vector((0.0, 0.0, 1.42)) - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    camera.data.lens = 42
    bpy.context.scene.camera = camera

    bpy.context.scene.render.engine = "CYCLES"
    bpy.context.scene.cycles.samples = 64
    bpy.context.scene.render.resolution_x = 1600
    bpy.context.scene.render.resolution_y = 1000
    bpy.context.scene.view_settings.view_transform = "AgX"
    bpy.context.scene.view_settings.look = "Medium High Contrast"
    bpy.context.scene.view_settings.exposure = 0.45
    bpy.context.scene.world.color = (0.065, 0.065, 0.065)


def export_glb(obj: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(
        filepath=str(GLB_PATH),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_materials="EXPORT",
    )


def render_preview() -> None:
    bpy.context.scene.render.filepath = str(PREVIEW_PATH)
    bpy.ops.render.render(write_still=True)


def main() -> None:
    BLENDER_SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    MESH_DIR.mkdir(parents=True, exist_ok=True)

    clear_scene()
    materials = make_materials()
    obj = make_wall_object(materials)
    add_reference_grid()
    setup_camera_and_lights()

    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))
    export_glb(obj)
    render_preview()

    print(f"Saved Blender source: {BLEND_PATH}")
    print(f"Saved GLB: {GLB_PATH}")
    print(f"Saved preview: {PREVIEW_PATH}")


if __name__ == "__main__":
    main()
