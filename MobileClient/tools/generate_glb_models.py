#!/usr/bin/env python3
"""Procedural glTF 2.0 (GLB) model generator for the Silkroad Mobile client.

Generates deterministic, mobile-friendly skeletal-rigged GLB models with baked
idle / walk / attack animations using only the Python standard library:

  * assets/models/humanoid_wizard.glb   (skinned humanoid rig, staff mounted at runtime)
  * assets/models/humanoid_spear.glb    (skinned humanoid rig, spear mounted at runtime)
  * assets/models/monster_mangyang.glb  (skinned four-legged celestial guardian)
  * assets/models/weapon_staff.glb      (ornate magical staff, static)
  * assets/models/weapon_spear.glb      (polearm / spear, static)

The output is imported by Godot 4 (glTF module), which builds a
Skeleton3D / MeshInstance3D / AnimationPlayer tree from these files.
"""

import json
import math
import os
import struct

PI = math.pi
TAU = 2.0 * math.pi


def norm3(x, y, z):
    length = math.sqrt(x * x + y * y + z * z) or 1.0
    return (x / length, y / length, z / length)


def quat_from_euler(x, y, z):
    """Rotation = Rx(x) * Ry(y) * Rz(z), returns unit quaternion (x, y, z, w)."""
    cx, sx = math.cos(x * 0.5), math.sin(x * 0.5)
    cy, sy = math.cos(y * 0.5), math.sin(y * 0.5)
    cz, sz = math.cos(z * 0.5), math.sin(z * 0.5)
    w = cx * cy * cz + sx * sy * sz
    i = sx * cy * cz - cx * sy * sz
    j = cx * sy * cz + sx * cy * sz
    k = cx * cy * sz - sx * sy * cz
    length = math.sqrt(w * w + i * i + j * j + k * k) or 1.0
    return (i / length, j / length, k / length, w / length)


class Geometry:
    """Vertex/triangle soup with smooth, centroid-oriented normals."""

    def __init__(self):
        self.verts = []
        self.tris = []

    def add(self, verts, tris):
        base = len(self.verts)
        self.verts.extend(verts)
        self.tris.extend((a + base, b + base, c + base) for a, b, c in tris)

    def compute_normals(self):
        if not self.tris:
            return []
        # part centroid -> used to orient faces outward for convex parts
        centroid = (0.0, 0.0, 0.0)
        for v in self.verts:
            centroid = (centroid[0] + v[0], centroid[1] + v[1], centroid[2] + v[2])
        n = len(self.verts) or 1
        centroid = (centroid[0] / n, centroid[1] / n, centroid[2] / n)

        face_normals = []
        for a, b, c in self.tris:
            ax, ay, az = self.verts[a]
            bx, by, bz = self.verts[b]
            cx, cy, cz = self.verts[c]
            ux, uy, uz = bx - ax, by - ay, bz - az
            vx, vy, vz = cx - ax, cy - ay, cz - az
            nx, ny, nz = (uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx)
            length = math.sqrt(nx * nx + ny * ny + nz * nz)
            if length < 1e-9:
                face_normals.append((0.0, 1.0, 0.0))
                continue
            nx, ny, nz = nx / length, ny / length, nz / length
            # orient outward relative to the part centroid
            fc = ((ax + bx + cx) / 3.0, (ay + by + cy) / 3.0, (az + bz + cz) / 3.0)
            out = (fc[0] - centroid[0], fc[1] - centroid[1], fc[2] - centroid[2])
            if nx * out[0] + ny * out[1] + nz * out[2] < 0.0:
                nx, ny, nz = -nx, -ny, -nz
            face_normals.append((nx, ny, nz))

        normals = [[0.0, 0.0, 0.0] for _ in self.verts]
        for (a, b, c), fn in zip(self.tris, face_normals):
            for idx in (a, b, c):
                normals[idx][0] += fn[0]
                normals[idx][1] += fn[1]
                normals[idx][2] += fn[2]
        result = []
        for nx, ny, nz in normals:
            result.append(norm3(nx, ny, nz))
        return result


# ---------------------------------------------------------------- primitives

def box(center, size):
    cx, cy, cz = center
    sx, sy, sz = size
    hx, hy, hz = sx * 0.5, sy * 0.5, sz * 0.5
    verts = [
        (cx - hx, cy - hy, cz - hz), (cx + hx, cy - hy, cz - hz),
        (cx + hx, cy + hy, cz - hz), (cx - hx, cy + hy, cz - hz),
        (cx - hx, cy - hy, cz + hz), (cx + hx, cy - hy, cz + hz),
        (cx + hx, cy + hy, cz + hz), (cx - hx, cy + hy, cz + hz),
    ]
    tris = [
        (0, 2, 1), (0, 3, 2),
        (4, 5, 6), (4, 6, 7),
        (0, 1, 5), (0, 5, 4),
        (1, 2, 6), (1, 6, 5),
        (2, 3, 7), (2, 7, 6),
        (3, 0, 4), (3, 4, 7),
    ]
    return verts, tris


def cylinder(center, r_top, r_bottom, height, segments, caps=True):
    cx, cy, cz = center
    y_top = cy + height * 0.5
    y_bot = cy - height * 0.5
    verts = []
    for i in range(segments):
        ang = TAU * i / segments
        ca, sa = math.cos(ang), math.sin(ang)
        verts.append((cx + r_bottom * ca, y_bot, cz + r_bottom * sa))
        verts.append((cx + r_top * ca, y_top, cz + r_top * sa))
    tris = []
    for i in range(segments):
        a = i * 2
        b = (i * 2 + 2) % (segments * 2)
        tris.append((a, b + 1, b))
        tris.append((a, a + 1, b + 1))
    if caps:
        bottom = len(verts)
        top = bottom + 1
        verts.append((cx, y_bot, cz))
        verts.append((cx, y_top, cz))
        for i in range(segments):
            a = i * 2
            b = (i * 2 + 2) % (segments * 2)
            tris.append((a, b, bottom))
            tris.append((a + 1, top, b + 1))
    return verts, tris


def sphere(center, radius, scale=(1.0, 1.0, 1.0), rings=10, segments=14):
    cx, cy, cz = center
    sx, sy, sz = scale
    verts = []
    # top pole
    verts.append((cx, cy + radius * sy, cz))
    for i in range(1, rings):
        phi = PI * i / rings
        y = math.cos(phi) * radius * sy
        r = math.sin(phi) * radius
        for j in range(segments):
            ang = TAU * j / segments
            verts.append((cx + r * math.cos(ang) * sx, cy + y, cz + r * math.sin(ang) * sz))
    # bottom pole
    bottom_pole = len(verts)
    verts.append((cx, cy - radius * sy, cz))

    tris = []
    for j in range(segments):
        j2 = (j + 1) % segments
        # top fan: pole(0), ring1[j], ring1[j2]
        a = 1 + j
        b = 1 + j2
        tris.append((0, b, a))
    for i in range(0, rings - 2):
        for j in range(segments):
            j2 = (j + 1) % segments
            a = 1 + i * segments + j
            b = 1 + (i + 1) * segments + j
            tris.append((a, b, b + (j2 - j)))
            tris.append((a, b + (j2 - j), a + (j2 - j)))
    for j in range(segments):
        j2 = (j + 1) % segments
        a = 1 + (rings - 2) * segments + j
        b = 1 + (rings - 2) * segments + j2
        tris.append((a, bottom_pole, b))
    return verts, tris


def cone(center, r_bottom, height, segments=12):
    return cylinder(center, 0.0, r_bottom, height, segments, caps=True)


def torus(center, radius, tube, segments=16, ring_segments=10):
    cx, cy, cz = center
    verts = []
    for i in range(ring_segments):
        phi = TAU * i / ring_segments
        for j in range(segments):
            theta = TAU * j / segments
            x = (radius + tube * math.cos(theta)) * math.cos(phi)
            y = tube * math.sin(theta)
            z = (radius + tube * math.cos(theta)) * math.sin(phi)
            verts.append((cx + x, cy + y, cz + z))
    tris = []
    for i in range(ring_segments):
        i2 = (i + 1) % ring_segments
        for j in range(segments):
            j2 = (j + 1) % segments
            a = i * segments + j
            b = i2 * segments + j
            tris.append((a, b, i2 * segments + j2))
            tris.append((a, i2 * segments + j2, i * segments + j2))
    return verts, tris


# ---------------------------------------------------------------- builder

class GltfBuilder:
    def __init__(self, root_name):
        self.root_name = root_name
        self.nodes = []
        self.meshes = []
        self.materials = []
        self.bones = []          # (name, parent_idx, local_pos)
        self.parts = []          # (bone_idx, material_idx, Geometry)
        self.skins = []
        self.animations = []     # (name, {bone_name: [(t, euler_xyz)], ...})
        self._bin = bytearray()
        self.accessors = []
        self.buffer_views = []
        self._node_indices = {}

    # ---- materials ----
    def add_material(self, name, color, metallic=0.0, roughness=0.6, emissive=None, emissive_strength=1.0):
        material = {
            "name": name,
            "pbrMetallicRoughness": {
                "baseColorFactor": [color[0], color[1], color[2], color[3] if len(color) > 3 else 1.0],
                "metallicFactor": metallic,
                "roughnessFactor": roughness,
            },
            "doubleSided": True,
        }
        if emissive is not None:
            material["emissiveFactor"] = [emissive[0], emissive[1], emissive[2]]
            material["emissiveStrength"] = emissive_strength
        self.materials.append(material)
        return len(self.materials) - 1

    # ---- skeleton ----
    def add_bone(self, name, parent, local_pos):
        self.bones.append((name, parent, local_pos))
        return len(self.bones) - 1

    def bone_world_pos(self, index):
        x, y, z = 0.0, 0.0, 0.0
        while index >= 0:
            _, _, pos = self.bones[index]
            x += pos[0]
            y += pos[1]
            z += pos[2]
            index = self.bones[index][1]
        return (x, y, z)

    # ---- parts ----
    def add_part(self, bone_idx, material_idx, geometry):
        self.parts.append((bone_idx, material_idx, geometry))

    # ---- animations ----
    def add_animation(self, name, keyframes):
        """keyframes: {bone_name: [(time, (rx, ry, rz) euler radians), ...]}"""
        self.animations.append((name, keyframes))

    # ---- assembly ----
    def build(self):
        self._node_indices = {}
        nodes = [{"name": self.root_name}]

        if self.bones:
            armature = {"name": "Armature", "children": []}
            nodes.append(armature)
            nodes[0]["children"] = [len(nodes) - 1]
            root_bones = [i for i, b in enumerate(self.bones) if b[1] < 0]
            for bone_idx in root_bones:
                armature["children"].append(self._build_bone_tree(bone_idx, nodes))
            if self.parts:
                mesh_id = self._build_mesh(skinned=True)
                skin_id = self._build_skin()
                nodes.append({
                    "name": self.root_name + "Mesh",
                    "mesh": mesh_id,
                    "skin": skin_id,
                })
                armature["children"].append(len(nodes) - 1)
        else:
            if self.parts:
                mesh_id = self._build_mesh(skinned=False)
                nodes.append({"name": self.root_name + "Mesh", "mesh": mesh_id})
                nodes[0]["children"] = [len(nodes) - 1]

        gltf = {
            "asset": {
                "version": "2.0",
                "generator": "SilkroadMobileGLBGenerator/1.0",
            },
            "scene": 0,
            "scenes": [{"nodes": [0]}],
            "nodes": nodes,
            "meshes": self.meshes,
            "materials": self.materials,
            "animations": self._build_animations(),
        }
        if self.skins:
            gltf["skins"] = self.skins
        return gltf

    def _build_bone_tree(self, bone_idx, nodes):
        name, parent, pos = self.bones[bone_idx]
        node = {"name": name, "translation": [pos[0], pos[1], pos[2]]}
        nodes.append(node)
        self._node_indices[name] = len(nodes) - 1
        children = [i for i, b in enumerate(self.bones) if b[1] == bone_idx]
        if children:
            node["children"] = []
            for child in children:
                node["children"].append(self._build_bone_tree(child, nodes))
        return self._node_indices[name]

    def _build_mesh(self, skinned):
        primitives = []
        by_material = {}
        for bone_idx, material_idx, geometry in self.parts:
            by_material.setdefault(material_idx, []).append((bone_idx, geometry))
        for material_idx in sorted(by_material.keys()):
            primitives.append(self._build_primitive(by_material[material_idx], material_idx, skinned))
        self.meshes.append({"name": self.root_name + "Mesh", "primitives": primitives})
        return len(self.meshes) - 1

    def _build_primitive(self, part_list, material_idx, skinned):
        positions = []
        normals = []
        joints = []
        weights = []
        indices = []
        cursor = 0
        for bone_idx, geometry in part_list:
            nrm = geometry.compute_normals()
            for v in geometry.verts:
                positions.append(v)
            for n in nrm:
                normals.append(n)
            if skinned:
                for _ in geometry.verts:
                    joints.extend([bone_idx, 0, 0, 0])
                    weights.extend([1.0, 0.0, 0.0, 0.0])
            for tri in geometry.tris:
                indices.append(tri[0] + cursor)
                indices.append(tri[1] + cursor)
                indices.append(tri[2] + cursor)
            cursor += len(geometry.verts)

        attributes = {
            "POSITION": self._accessor(positions, 5126, "VEC3", count=len(positions)),
            "NORMAL": self._accessor(normals, 5126, "VEC3", count=len(normals)),
        }
        if skinned:
            attributes["JOINTS_0"] = self._accessor(joints, 5121, "VEC4", count=len(positions))
            attributes["WEIGHTS_0"] = self._accessor(weights, 5126, "VEC4", count=len(positions))
        return {
            "attributes": attributes,
            "indices": self._accessor(indices, 5123, "SCALAR", count=len(indices)),
            "material": material_idx,
            "mode": 4,
        }

    def _build_skin(self):
        ibm = []
        for i in range(len(self.bones)):
            px, py, pz = self.bone_world_pos(i)
            ibm.extend([
                1.0, 0.0, 0.0, 0.0,
                0.0, 1.0, 0.0, 0.0,
                0.0, 0.0, 1.0, 0.0,
                -px, -py, -pz, 1.0,
            ])
        joints = [self._node_indices[b[0]] for b in self.bones]
        skin = {
            "name": self.root_name + "Skin",
            "joints": joints,
            "inverseBindMatrices": self._accessor(ibm, 5126, "MAT4", count=len(self.bones)),
        }
        self.skins.append(skin)
        return len(self.skins) - 1

    def _build_animations(self):
        result = []
        for name, keyframes in self.animations:
            channels = []
            samplers = []
            for bone_name, keys in keyframes.items():
                node = self._node_indices.get(bone_name)
                if node is None or len(keys) < 2:
                    continue
                keys = sorted(keys, key=lambda k: k[0])
                times = [k[0] for k in keys]
                quats = []
                for _, euler in keys:
                    quats.extend(quat_from_euler(*euler))
                sampler_idx = len(samplers)
                samplers.append({
                    "input": self._accessor(times, 5126, "SCALAR", count=len(times)),
                    "output": self._accessor(quats, 5126, "VEC4", count=len(quats)),
                    "interpolation": "LINEAR",
                })
                channels.append({
                    "sampler": sampler_idx,
                    "target": {"node": node, "path": "rotation"},
                })
            result.append({"name": name, "channels": channels, "samplers": samplers})
        return result

    # ------------------------------------------------------------ accessors
    def _accessor(self, data, component_type, type_name, count):
        fmt = {5126: "f", 5121: "B", 5123: "H"}[component_type]
        size = {5126: 4, 5121: 1, 5123: 2}[component_type]
        components = {"SCALAR": 1, "VEC3": 3, "VEC4": 4, "MAT4": 16}[type_name]
        payload = bytearray()
        for value in data:
            if isinstance(value, (int, float)):
                values = [value]
            else:
                values = list(value)
            payload.extend(struct.pack("<" + fmt * len(values), *values))
        offset = (len(self._bin) + 15) & ~15
        pad = offset - len(self._bin)
        if pad:
            self._bin.extend(b"\x00" * pad)
        self._bin.extend(payload)
        view = {
            "buffer": 0,
            "byteOffset": offset,
            "byteLength": len(payload),
        }
        self.buffer_views.append(view)
        accessor = {
            "bufferView": len(self.buffer_views) - 1,
            "byteOffset": 0,
            "componentType": component_type,
            "count": count,
            "type": type_name,
        }
        if component_type == 5126 and type_name == "VEC3":
            accessor["min"] = [min(v[i] for v in data) for i in range(3)]
            accessor["max"] = [max(v[i] for v in data) for i in range(3)]
        self.accessors.append(accessor)
        return len(self.accessors) - 1

    # ------------------------------------------------------------ serialization
    def serialize(self):
        gltf = self.build()
        gltf["accessors"] = self.accessors
        gltf["bufferViews"] = self.buffer_views
        while len(self._bin) % 4:
            self._bin.append(0)
        gltf["buffers"] = [{"byteLength": len(self._bin)}]

        json_bytes = json.dumps(gltf, separators=(",", ":")).encode("utf-8")
        json_bytes += b" " * ((4 - len(json_bytes) % 4) % 4)
        json_len = len(json_bytes)
        bin_len = len(self._bin)
        total = 12 + 8 + json_len + 8 + bin_len

        header = struct.pack("<4sII", b"glTF", 2, total)
        json_chunk = struct.pack("<I4s", json_len, b"JSON")
        bin_chunk = struct.pack("<I4s", bin_len, b"BIN\x00")
        return header + json_chunk + json_bytes + bin_chunk + bytes(self._bin)


# ================================================================ HUMANOID

def build_humanoid(style):
    builder = GltfBuilder("Humanoid" + style.title())

    mat_skin = builder.add_material("skin", (0.83, 0.61, 0.47, 1.0), 0.0, 0.72)
    mat_cloth = builder.add_material(
        "cloth",
        (0.09, 0.17, 0.34, 1.0) if style == "wizard" else (0.08, 0.25, 0.24, 1.0),
        0.02, 0.62)
    mat_robe = builder.add_material(
        "robe",
        (0.06, 0.12, 0.26, 1.0) if style == "wizard" else (0.06, 0.18, 0.18, 1.0),
        0.02, 0.68)
    mat_gold = builder.add_material("gold", (0.91, 0.76, 0.42, 1.0), 0.62, 0.20, (0.20, 0.14, 0.04), 0.4)
    mat_dark = builder.add_material("dark", (0.15, 0.11, 0.15, 1.0), 0.05, 0.78)
    mat_metal = builder.add_material("metal", (0.62, 0.66, 0.72, 1.0), 0.85, 0.24)
    mat_hair = builder.add_material("hair", (0.10, 0.08, 0.13, 1.0), 0.0, 0.85)
    mat_eye = builder.add_material("eye", (0.35, 0.85, 1.0, 1.0), 0.05, 0.15, (0.25, 0.75, 1.0), 2.0)

    b_root = builder.add_bone("root", -1, (0, 0, 0))
    b_hips = builder.add_bone("hips", b_root, (0, 0.92, 0))
    b_spine = builder.add_bone("spine", b_hips, (0, 0.20, 0))
    b_chest = builder.add_bone("chest", b_spine, (0, 0.24, 0))
    b_neck = builder.add_bone("neck", b_chest, (0, 0.24, 0))
    b_head = builder.add_bone("head", b_neck, (0, 0.13, 0))
    b_shl = builder.add_bone("shoulder_l", b_chest, (-0.24, 0.13, 0))
    b_ual = builder.add_bone("upper_arm_l", b_shl, (-0.17, 0, 0))
    b_lal = builder.add_bone("lower_arm_l", b_ual, (0, -0.32, 0))
    b_hal = builder.add_bone("hand_l", b_lal, (0, -0.27, 0))
    b_shr = builder.add_bone("shoulder_r", b_chest, (0.24, 0.13, 0))
    b_uar = builder.add_bone("upper_arm_r", b_shr, (0.17, 0, 0))
    b_lar = builder.add_bone("lower_arm_r", b_uar, (0, -0.32, 0))
    b_har = builder.add_bone("hand_r", b_lar, (0, -0.27, 0))
    b_tl = builder.add_bone("thigh_l", b_hips, (-0.14, -0.05, 0))
    b_sl = builder.add_bone("shin_l", b_tl, (0, -0.42, 0))
    b_fl = builder.add_bone("foot_l", b_sl, (0, -0.42, 0.05))
    b_tr = builder.add_bone("thigh_r", b_hips, (0.14, -0.05, 0))
    b_sr = builder.add_bone("shin_r", b_tr, (0, -0.42, 0))
    b_fr = builder.add_bone("foot_r", b_sr, (0, -0.42, 0.05))

    def attach(bone_idx, mat_idx, geometry):
        builder.add_part(bone_idx, mat_idx, geometry)

    # torso
    g = Geometry()
    g.add(*box((0, 0.95, 0), (0.38, 0.26, 0.26)))
    attach(b_hips, mat_cloth, g)
    g = Geometry()
    g.add(*box((0, 1.16, 0), (0.46, 0.18, 0.28)))
    attach(b_spine, mat_cloth, g)
    g = Geometry()
    g.add(*box((0, 1.38, 0), (0.52, 0.26, 0.30)))
    attach(b_chest, mat_cloth, g)
    g = Geometry()
    g.add(*box((0, 1.62, 0), (0.18, 0.15, 0.18)))
    attach(b_neck, mat_skin, g)
    g = Geometry()
    g.add(*box((0, 1.77, 0), (0.30, 0.28, 0.30)))
    attach(b_head, mat_skin, g)
    # hair
    g = Geometry()
    g.add(*box((0, 1.93, 0), (0.32, 0.12, 0.32)))
    g.add(*box((0, 1.85, 0.02), (0.32, 0.06, 0.20)))
    attach(b_head, mat_hair, g)
    # eyes
    for ex in (-0.06, 0.06):
        g = Geometry()
        g.add(*box((ex, 1.80, -0.156), (0.055, 0.035, 0.02)))
        attach(b_head, mat_eye, g)

    # arms
    for side in ("l", "r"):
        b_upper = b_ual if side == "l" else b_uar
        b_lower = b_lal if side == "l" else b_lar
        b_hand = b_hal if side == "l" else b_har
        sign = -1.0 if side == "l" else 1.0
        g = Geometry()
        g.add(*box((sign * 0.41, 1.42, 0), (0.15, 0.30, 0.15)))
        attach(b_upper, mat_cloth, g)
        g = Geometry()
        g.add(*box((sign * 0.41, 1.05, 0), (0.12, 0.30, 0.13)))
        attach(b_lower, mat_skin, g)
        g = Geometry()
        g.add(*box((sign * 0.41, 0.84, 0), (0.11, 0.15, 0.13)))
        attach(b_hand, mat_skin, g)

    # legs
    for side in ("l", "r"):
        b_thigh = b_tl if side == "l" else b_tr
        b_shin = b_sl if side == "l" else b_sr
        b_foot = b_fl if side == "l" else b_fr
        sign = -1.0 if side == "l" else 1.0
        g = Geometry()
        g.add(*box((sign * 0.14, 0.72, 0), (0.17, 0.34, 0.19)))
        attach(b_thigh, mat_dark, g)
        g = Geometry()
        g.add(*box((sign * 0.14, 0.30, 0), (0.13, 0.32, 0.15)))
        attach(b_shin, mat_dark, g)
        g = Geometry()
        g.add(*box((sign * 0.14, 0.02, 0.07), (0.13, 0.07, 0.24)))
        attach(b_foot, mat_dark, g)

    # class-specific details
    if style == "wizard":
        g = Geometry()
        g.add(*cylinder((0, 0.70, 0), 0.24, 0.40, 0.62, 14))
        attach(b_hips, mat_robe, g)
        g = Geometry()
        g.add(*torus((0, 0.42, 0), 0.34, 0.045, 16, 8))
        attach(b_hips, mat_gold, g)
        g = Geometry()
        g.add(*torus((0, 1.03, 0), 0.20, 0.035, 16, 8))
        attach(b_hips, mat_gold, g)
        g = Geometry()
        g.add(*torus((0, 1.52, 0), 0.22, 0.035, 16, 8))
        attach(b_chest, mat_gold, g)
        for b_sh, sign in ((b_shl, -1.0), (b_shr, 1.0)):
            g = Geometry()
            g.add(*sphere((sign * 0.28, 1.53, 0), 0.11, (1.0, 0.85, 1.0), 8, 10))
            attach(b_sh, mat_gold, g)
        g = Geometry()
        g.add(*cone((0, 1.99, 0), 0.17, 0.30, 12))
        g.add(*torus((0, 1.86, 0), 0.18, 0.03, 16, 8))
        attach(b_head, mat_robe, g)
    else:
        g = Geometry()
        g.add(*box((0, 1.38, -0.16), (0.48, 0.22, 0.05)))
        attach(b_chest, mat_metal, g)
        for b_sh, sign in ((b_shl, -1.0), (b_shr, 1.0)):
            g = Geometry()
            g.add(*box((sign * 0.30, 1.53, 0), (0.24, 0.12, 0.26)))
            attach(b_sh, mat_metal, g)
        g = Geometry()
        g.add(*torus((0, 1.03, 0), 0.21, 0.035, 16, 8))
        attach(b_hips, mat_gold, g)
        g = Geometry()
        g.add(*box((0, 1.12, -0.16), (0.34, 0.06, 0.03)))
        attach(b_hips, mat_gold, g)
        g = Geometry()
        g.add(*box((0, 1.94, 0), (0.28, 0.05, 0.30)))
        attach(b_head, mat_metal, g)

    # ---- animations ----
    idle = {}
    walk = {}
    attack = {}

    def idle_chest(t):
        return (0.03 * math.sin(TAU * 0.5 * t), 0.0, 0.05 * math.sin(TAU * 0.5 * t))

    def idle_head(t):
        return (0.02 * math.sin(TAU * 0.25 * t), 0.06 * math.sin(TAU * 0.5 * t + 1.0), 0.0)

    def idle_arm(t, sign):
        return (0.06 * math.sin(TAU * 0.5 * t + 0.5), 0.0, sign * 0.08)

    idle["chest"] = [(t, idle_chest(t)) for t in (0.0, 0.5, 1.0, 1.5, 2.0)]
    idle["head"] = [(t, idle_head(t)) for t in (0.0, 0.5, 1.0, 1.5, 2.0)]
    idle["upper_arm_l"] = [(t, idle_arm(t, -1.0)) for t in (0.0, 0.5, 1.0, 1.5, 2.0)]
    idle["upper_arm_r"] = [(t, idle_arm(t, 1.0)) for t in (0.0, 0.5, 1.0, 1.5, 2.0)]

    def walk_thigh(t, phase):
        return (0.55 * math.sin(TAU * t + phase), 0.0, 0.0)

    def walk_shin(t, phase):
        return (0.35 * math.sin(TAU * t + phase), 0.0, 0.0)

    def walk_arm(t, phase):
        return (-0.45 * math.sin(TAU * t + phase), 0.0, 0.0)

    walk["thigh_l"] = [(t, walk_thigh(t, 0.0)) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]
    walk["thigh_r"] = [(t, walk_thigh(t, math.pi)) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]
    walk["shin_l"] = [(t, walk_shin(t, 0.0)) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]
    walk["shin_r"] = [(t, walk_shin(t, math.pi)) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]
    walk["upper_arm_l"] = [(t, walk_arm(t, math.pi)) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]
    walk["upper_arm_r"] = [(t, walk_arm(t, 0.0)) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]
    walk["lower_arm_l"] = [(t, walk_shin(t, math.pi)) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]
    walk["lower_arm_r"] = [(t, walk_shin(t, 0.0)) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]
    walk["chest"] = [(t, (0.04 * math.sin(TAU * t), 0.0, 0.0)) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]

    if style == "wizard":
        arm_peak = -1.9
        lower_peak = -0.55
    else:
        arm_peak = -1.35
        lower_peak = -0.25
    arm_r_curve = [(0.0, 0.0), (0.08, -0.35), (0.22, arm_peak), (0.38, arm_peak - 0.1), (0.55, -0.4), (0.8, 0.0)]
    lower_r_curve = [(0.0, 0.0), (0.08, -0.15), (0.22, lower_peak), (0.38, lower_peak), (0.55, -0.1), (0.8, 0.0)]
    arm_l_curve = [(0.0, 0.0), (0.22, 0.35), (0.38, 0.3), (0.8, 0.0)]
    chest_curve = [(0.0, 0.0), (0.22, 0.10), (0.38, 0.08), (0.8, 0.0)]
    spine_curve = [(0.0, 0.0), (0.22, 0.05), (0.38, 0.04), (0.8, 0.0)]
    attack["upper_arm_r"] = [(t, (x, 0.0, 0.08)) for t, x in arm_r_curve]
    attack["lower_arm_r"] = [(t, (x, 0.0, 0.0)) for t, x in lower_r_curve]
    attack["upper_arm_l"] = [(t, (x, 0.0, -0.05)) for t, x in arm_l_curve]
    attack["chest"] = [(t, (x, 0.0, 0.0)) for t, x in chest_curve]
    attack["spine"] = [(t, (x, 0.0, 0.0)) for t, x in spine_curve]

    builder.add_animation("idle", idle)
    builder.add_animation("walk", walk)
    builder.add_animation("attack", attack)
    return builder


# ================================================================ MONSTER

def build_monster():
    builder = GltfBuilder("Mangyang")

    mat_fur = builder.add_material("fur", (0.13, 0.30, 0.33, 1.0), 0.0, 0.86)
    mat_belly = builder.add_material("belly", (0.42, 0.65, 0.64, 1.0), 0.0, 0.82)
    mat_accent = builder.add_material("accent", (0.91, 0.76, 0.42, 1.0), 0.55, 0.22, (0.18, 0.12, 0.03), 0.4)
    mat_eye = builder.add_material("eye", (0.40, 0.90, 1.0, 1.0), 0.05, 0.15, (0.30, 0.85, 1.0), 2.5)
    mat_horn = builder.add_material("horn", (0.86, 0.78, 0.55, 1.0), 0.1, 0.5)
    mat_hoof = builder.add_material("hoof", (0.10, 0.12, 0.14, 1.0), 0.2, 0.6)

    b_root = builder.add_bone("root", -1, (0, 0, 0))
    b_spine = builder.add_bone("spine", b_root, (0, 0.55, 0))
    b_chest = builder.add_bone("chest", b_spine, (0, 0.40, 0.10))
    b_neck = builder.add_bone("neck", b_chest, (0, 0.20, 0.18))
    b_head = builder.add_bone("head", b_neck, (0, 0.12, 0.20))

    b_shl = builder.add_bone("shoulder_l", b_chest, (-0.22, 0.0, -0.16))
    b_ual = builder.add_bone("upper_arm_l", b_shl, (0, -0.28, 0))
    b_lal = builder.add_bone("lower_arm_l", b_ual, (0, -0.30, 0))
    b_hal = builder.add_bone("hand_l", b_lal, (0, -0.28, 0.02))
    b_shr = builder.add_bone("shoulder_r", b_chest, (0.22, 0.0, -0.16))
    b_uar = builder.add_bone("upper_arm_r", b_shr, (0, -0.28, 0))
    b_lar = builder.add_bone("lower_arm_r", b_uar, (0, -0.30, 0))
    b_har = builder.add_bone("hand_r", b_lar, (0, -0.28, 0.02))

    b_tl = builder.add_bone("thigh_l", b_spine, (-0.22, 0.0, -0.35))
    b_sl = builder.add_bone("shin_l", b_tl, (0, -0.32, 0))
    b_fl = builder.add_bone("foot_l", b_sl, (0, -0.32, 0.03))
    b_tr = builder.add_bone("thigh_r", b_spine, (0.22, 0.0, -0.35))
    b_sr = builder.add_bone("shin_r", b_tr, (0, -0.32, 0))
    b_fr = builder.add_bone("foot_r", b_sr, (0, -0.32, 0.03))

    b_t1 = builder.add_bone("tail_1", b_spine, (0, 0.10, -0.30))
    b_t2 = builder.add_bone("tail_2", b_t1, (0, 0.08, -0.22))
    b_t3 = builder.add_bone("tail_3", b_t2, (0, 0.06, -0.20))

    def attach(bone_idx, mat_idx, geometry):
        builder.add_part(bone_idx, mat_idx, geometry)

    # body
    g = Geometry()
    g.add(*sphere((0, 0.88, 0), 0.40, (1.15, 1.0, 1.7), 10, 14))
    attach(b_spine, mat_fur, g)
    g = Geometry()
    g.add(*sphere((0, 0.74, -0.08), 0.30, (1.1, 0.85, 1.6), 8, 12))
    attach(b_spine, mat_belly, g)
    g = Geometry()
    g.add(*sphere((0, 1.08, 0.16), 0.30, (1.0, 0.9, 1.15), 8, 12))
    attach(b_chest, mat_fur, g)
    g = Geometry()
    g.add(*cylinder((0, 1.18, 0.30), 0.13, 0.16, 0.20, 10))
    attach(b_neck, mat_fur, g)
    g = Geometry()
    g.add(*torus((0, 1.20, 0.16), 0.24, 0.045, 16, 8))
    attach(b_chest, mat_accent, g)
    g = Geometry()
    g.add(*sphere((0, 1.28, 0.50), 0.26, (1.0, 0.95, 1.0), 9, 12))
    attach(b_head, mat_fur, g)
    g = Geometry()
    g.add(*sphere((0, 1.22, 0.74), 0.15, (0.95, 0.8, 1.2), 7, 10))
    attach(b_head, mat_belly, g)
    for ex in (-0.09, 0.09):
        g = Geometry()
        g.add(*sphere((ex, 1.31, 0.78), 0.035, (1.0, 0.8, 1.0), 5, 8))
        attach(b_head, mat_eye, g)
    for ex in (-0.14, 0.14):
        g = Geometry()
        g.add(*cone((ex * 0.9, 1.52, 0.44), 0.06, 0.30, 8))
        attach(b_head, mat_horn, g)
    for ex in (-0.20, 0.20):
        g = Geometry()
        g.add(*cone((ex, 1.40, 0.36), 0.05, 0.20, 8))
        attach(b_head, mat_fur, g)

    # front legs
    for side in ("l", "r"):
        sign = -1.0 if side == "l" else 1.0
        b_up = b_ual if side == "l" else b_uar
        b_lo = b_lal if side == "l" else b_lar
        b_ha = b_hal if side == "l" else b_har
        g = Geometry()
        g.add(*cylinder((sign * 0.22, 0.55, -0.06), 0.075, 0.10, 0.36, 9))
        attach(b_up, mat_fur, g)
        g = Geometry()
        g.add(*cylinder((sign * 0.22, 0.24, -0.06), 0.06, 0.075, 0.36, 9))
        attach(b_lo, mat_fur, g)
        g = Geometry()
        g.add(*box((sign * 0.22, 0.055, -0.05), (0.09, 0.10, 0.20)))
        attach(b_ha, mat_hoof, g)

    # rear legs
    for side in ("l", "r"):
        sign = -1.0 if side == "l" else 1.0
        b_th = b_tl if side == "l" else b_tr
        b_sh = b_sl if side == "l" else b_sr
        b_fo = b_fl if side == "l" else b_fr
        g = Geometry()
        g.add(*cylinder((sign * 0.22, 0.40, -0.35), 0.085, 0.11, 0.38, 9))
        attach(b_th, mat_fur, g)
        g = Geometry()
        g.add(*cylinder((sign * 0.22, 0.16, -0.35), 0.06, 0.075, 0.36, 9))
        attach(b_sh, mat_fur, g)
        g = Geometry()
        g.add(*box((sign * 0.22, 0.05, -0.33), (0.09, 0.10, 0.22)))
        attach(b_fo, mat_hoof, g)

    # tail
    for b_t, size in ((b_t1, 0.12), (b_t2, 0.10), (b_t3, 0.08)):
        g = Geometry()
        g.add(*sphere((0, 0, 0), size, (1.0, 1.0, 1.4), 7, 9))
        attach(b_t, mat_fur, g)

    # ---- animations ----
    idle = {}
    walk = {}
    attack = {}

    def idle_chest(t):
        return (0.0, 0.0, 0.05 * math.sin(TAU * 0.4 * t))

    def idle_head(t):
        return (0.0, 0.10 * math.sin(TAU * 0.5 * t + 0.6), 0.0)

    def idle_tail(t, phase, amp):
        return (0.0, amp * math.sin(TAU * 0.6 * t + phase), 0.0)

    idle["chest"] = [(t, idle_chest(t)) for t in (0.0, 0.5, 1.0, 1.5, 2.0)]
    idle["head"] = [(t, idle_head(t)) for t in (0.0, 0.5, 1.0, 1.5, 2.0)]
    idle["tail_1"] = [(t, idle_tail(t, 0.0, 0.12)) for t in (0.0, 0.5, 1.0, 1.5, 2.0)]
    idle["tail_2"] = [(t, idle_tail(t, 0.4, 0.18)) for t in (0.0, 0.5, 1.0, 1.5, 2.0)]
    idle["tail_3"] = [(t, idle_tail(t, 0.8, 0.24)) for t in (0.0, 0.5, 1.0, 1.5, 2.0)]

    def leg_cycle(t, phase):
        return (0.5 * math.sin(TAU * t + phase), 0.0, 0.0)

    def shin_cycle(t, phase):
        return (0.25 * math.sin(TAU * t + phase), 0.0, 0.0)

    walk["upper_arm_l"] = [(t, leg_cycle(t, math.pi)) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]
    walk["upper_arm_r"] = [(t, leg_cycle(t, 0.0)) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]
    walk["lower_arm_l"] = [(t, shin_cycle(t, math.pi)) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]
    walk["lower_arm_r"] = [(t, shin_cycle(t, 0.0)) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]
    walk["thigh_l"] = [(t, leg_cycle(t, 0.0)) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]
    walk["thigh_r"] = [(t, leg_cycle(t, math.pi)) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]
    walk["shin_l"] = [(t, shin_cycle(t, 0.0)) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]
    walk["shin_r"] = [(t, shin_cycle(t, math.pi)) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]
    walk["spine"] = [(t, (0.0, 0.0, 0.05 * math.sin(TAU * t))) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]

    neck_curve = [(0.0, 0.0), (0.15, -0.35), (0.3, 0.15), (0.5, -0.5), (0.7, 0.0)]
    head_curve = [(0.0, 0.0), (0.15, -0.3), (0.3, 0.1), (0.5, -0.4), (0.7, 0.0)]
    chest_curve = [(0.0, 0.0), (0.15, -0.15), (0.3, -0.1), (0.5, -0.2), (0.7, 0.0)]
    attack["neck"] = [(t, (x, 0.0, 0.0)) for t, x in neck_curve]
    attack["head"] = [(t, (x, 0.0, 0.0)) for t, x in head_curve]
    attack["chest"] = [(t, (x, 0.0, 0.0)) for t, x in chest_curve]

    builder.add_animation("idle", idle)
    builder.add_animation("walk", walk)
    builder.add_animation("attack", attack)
    return builder


# ================================================================ WEAPONS

def build_weapon_staff():
    builder = GltfBuilder("Staff")
    mat_wood = builder.add_material("wood", (0.42, 0.26, 0.16, 1.0), 0.0, 0.82)
    mat_gold = builder.add_material("gold", (0.93, 0.79, 0.45, 1.0), 0.7, 0.18, (0.22, 0.15, 0.04), 0.5)
    mat_orb = builder.add_material("orb", (0.35, 0.85, 1.0, 1.0), 0.1, 0.12, (0.35, 0.85, 1.0), 3.0)

    g = Geometry()
    g.add(*cylinder((0, 0.10, 0), 0.028, 0.035, 1.50, 10))
    builder.add_part(0, mat_wood, g)
    g = Geometry()
    g.add(*torus((0, 0.85, 0), 0.07, 0.012, 12, 6))
    builder.add_part(0, mat_gold, g)
    g = Geometry()
    g.add(*torus((0, 0.45, 0), 0.07, 0.012, 12, 6))
    builder.add_part(0, mat_gold, g)
    g = Geometry()
    g.add(*sphere((0, 0.93, 0), 0.16, (1.0, 1.15, 1.0), 10, 12))
    builder.add_part(0, mat_orb, g)
    g = Geometry()
    g.add(*torus((0, 0.93, 0), 0.22, 0.02, 16, 8))
    builder.add_part(0, mat_gold, g)
    g = Geometry()
    g.add(*torus((0, 0.93, 0), 0.27, 0.014, 16, 8))
    builder.add_part(0, mat_gold, g)
    g = Geometry()
    g.add(*sphere((0, -0.72, 0), 0.045, (1.0, 1.4, 1.0), 6, 8))
    builder.add_part(0, mat_gold, g)
    return builder


def build_weapon_spear():
    builder = GltfBuilder("Spear")
    mat_wood = builder.add_material("wood", (0.42, 0.26, 0.16, 1.0), 0.0, 0.82)
    mat_steel = builder.add_material("steel", (0.68, 0.72, 0.78, 1.0), 0.88, 0.22)
    mat_gold = builder.add_material("gold", (0.93, 0.79, 0.45, 1.0), 0.7, 0.18, (0.22, 0.15, 0.04), 0.5)

    g = Geometry()
    g.add(*cylinder((0, 0.0, 0), 0.022, 0.028, 1.90, 10))
    builder.add_part(0, mat_wood, g)
    g = Geometry()
    g.add(*cylinder((0, 1.00, 0), 0.0, 0.085, 0.52, 10))
    builder.add_part(0, mat_steel, g)
    g = Geometry()
    g.add(*torus((0, 0.78, 0), 0.05, 0.012, 12, 6))
    builder.add_part(0, mat_gold, g)
    g = Geometry()
    g.add(*torus((0, -0.20, 0), 0.05, 0.012, 12, 6))
    builder.add_part(0, mat_gold, g)
    g = Geometry()
    g.add(*sphere((0, 1.28, 0), 0.03, (1.0, 1.5, 1.0), 5, 8))
    builder.add_part(0, mat_gold, g)
    g = Geometry()
    g.add(*sphere((0, -0.96, 0), 0.04, (1.0, 1.6, 1.0), 5, 8))
    builder.add_part(0, mat_gold, g)
    return builder


# ================================================================ MAIN

def write_glb(builder, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as fh:
        fh.write(builder.serialize())
    print("wrote %s (%d bytes)" % (path, os.path.getsize(path)))


if __name__ == "__main__":
    out_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "models")
    write_glb(build_humanoid("wizard"), os.path.join(out_dir, "humanoid_wizard.glb"))
    write_glb(build_humanoid("spear"), os.path.join(out_dir, "humanoid_spear.glb"))
    write_glb(build_monster(), os.path.join(out_dir, "monster_mangyang.glb"))
    write_glb(build_weapon_staff(), os.path.join(out_dir, "weapon_staff.glb"))
    write_glb(build_weapon_spear(), os.path.join(out_dir, "weapon_spear.glb"))
    print("done")
