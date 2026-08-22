#!/usr/bin/env python3
"""Procedural glTF 2.0 (GLB) model generator for the Silkroad Mobile client.

Generates deterministic, mobile-friendly skeletal-rigged GLB models with baked
idle / walk / attack animations plus procedurally-generated CC0-style PNG
textures, using only the Python standard library:

  * assets/models/humanoid_wizard.glb  (skinned Asian-fantasy mage, robe + hat)
  * assets/models/humanoid_spear.glb   (skinned Asian-fantasy soldier, lamellar)
  * assets/models/monster_mangyang.glb (skinned four-legged creature + horns)
  * assets/models/weapon_staff.glb     (ornate wooden staff, static)
  * assets/models/weapon_spear.glb     (wooden polearm, static)
  * assets/textures/*.png              (procedural albedo maps for world reuse)

The output is imported by Godot 4 (glTF module), which builds a
Skeleton3D / MeshInstance3D / AnimationPlayer tree from these files.
"""

import base64
import json
import math
import os
import struct
import zlib

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


# ================================================================ PNG WRITER

def _png_chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def make_png(width, height, pixel_fn):
    """pixel_fn(x, y) -> (r, g, b) each 0..255. RGBA8, no filter."""
    rows = bytearray()
    for y in range(height):
        rows.append(0)
        for x in range(width):
            r, g, b = pixel_fn(x, y)
            rows.append(int(max(0, min(255, r))))
            rows.append(int(max(0, min(255, g))))
            rows.append(int(max(0, min(255, b))))
            rows.append(255)
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    return (b"\x89PNG\r\n\x1a\n" + _png_chunk(b"IHDR", ihdr)
            + _png_chunk(b"IDAT", zlib.compress(bytes(rows), 9))
            + _png_chunk(b"IEND", b""))


def _hash2(x, y, seed=0):
    n = (x * 374761393 + y * 668265263 + seed * 1274126177) & 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((n ^ (n >> 16)) & 0xFFFF) / 65535.0


def _smooth(t):
    return t * t * (3.0 - 2.0 * t)


def value_noise(x, y, scale, seed=0):
    gx = x * scale
    gy = y * scale
    x0, y0 = math.floor(gx), math.floor(gy)
    fx, fy = _smooth(gx - x0), _smooth(gy - y0)
    a = _hash2(x0, y0, seed)
    b = _hash2(x0 + 1, y0, seed)
    c = _hash2(x0, y0 + 1, seed)
    d = _hash2(x0 + 1, y0 + 1, seed)
    return a + (b - a) * fx + (c - a) * fy + (a - b - c + d) * fx * fy


def tex_cloth_wizard():
    """Deep indigo robe with faint weave + gold cloud swirl accents."""
    def px(x, y):
        base = (18, 30, 62)
        weave = 0.88 + 0.12 * math.sin(x * 0.55) * math.sin(y * 0.5)
        r, g, b = base[0] * weave, base[1] * weave, base[2] * weave
        n = value_noise(x, y, 0.06, 3)
        r += n * 6
        g += n * 6
        b += n * 9
        cloud = math.sin(x * 0.045 + math.sin(y * 0.09) * 2.0)
        band = math.sin(y * 0.35)
        if abs(cloud) < 0.12 and band > 0.3:
            r, g, b = 224, 186, 110
        return (r, g, b)
    return make_png(128, 128, px)


def tex_cloth_spear():
    """Jade-green war cloth with gold diamond lattice."""
    def px(x, y):
        base = (22, 60, 52)
        n = value_noise(x, y, 0.08, 7)
        r, g, b = base[0] + n * 8, base[1] + n * 10, base[2] + n * 8
        lattice = math.sin(x * 0.16) * math.sin(y * 0.16)
        if lattice > 0.55:
            r, g, b = 228, 186, 108
        edge = math.sin(x * 0.33) * math.sin(y * 0.33)
        if edge > 0.92:
            r, g, b = 246, 220, 150
        return (r, g, b)
    return make_png(128, 128, px)


def tex_skin():
    """Warm tan skin with subtle pores/mottling."""
    def px(x, y):
        base = (216, 152, 112)
        n = value_noise(x, y, 0.12, 11)
        return (base[0] + n * 10, base[1] + n * 10, base[2] + n * 6)
    return make_png(128, 128, px)


def tex_fur():
    """Mangyang fur: deep teal with darker stripes and olive patches."""
    def px(x, y):
        base = (30, 66, 70)
        n = value_noise(x, y, 0.10, 21)
        stripe = 0.5 + 0.5 * math.sin(y * 0.35 + math.sin(x * 0.09) * 3.0)
        r = base[0] * (1.0 + n * 0.3 - stripe * 0.28)
        g = base[1] * (1.0 + n * 0.3 - stripe * 0.28)
        b = base[2] * (1.0 + n * 0.3 - stripe * 0.28)
        patch = value_noise(x, y, 0.03, 33)
        if patch > 0.55:
            r, g, b = 56, 84, 66
        return (r, g, b)
    return make_png(128, 128, px)


def tex_belly():
    """Lighter belly fur."""
    def px(x, y):
        base = (108, 158, 152)
        n = value_noise(x, y, 0.10, 41)
        return (base[0] + n * 12, base[1] + n * 12, base[2] + n * 10)
    return make_png(128, 128, px)


def tex_horn():
    """Ivory horn with brown striations."""
    def px(x, y):
        base = (216, 198, 156)
        n = value_noise(x, y, 0.10, 55)
        stripe = 0.5 + 0.5 * math.sin(y * 0.5 + x * 0.1)
        shade = 1.0 - stripe * 0.22 * n
        return (base[0] * shade, base[1] * shade, base[2] * shade * 0.92)
    return make_png(128, 128, px)


def tex_gold():
    """Brushed gold metal."""
    def px(x, y):
        base = (236, 196, 116)
        n = value_noise(x, y, 0.14, 67)
        grain = 0.92 + 0.08 * math.sin(y * 0.6 + x * 0.05)
        return (base[0] * grain + n * 14, base[1] * grain + n * 12, base[2] * grain * (0.9 + n * 0.2))
    return make_png(128, 128, px)


def tex_wood():
    """Wood grain planks."""
    def px(x, y):
        base = (122, 76, 46)
        n = value_noise(x, y, 0.09, 79)
        ring = 0.5 + 0.5 * math.sin(y * 0.4 + math.sin(x * 0.3) * 2.0 + n * 1.2)
        shade = 0.82 + ring * 0.26
        return (base[0] * shade, base[1] * shade, base[2] * shade * 0.94)
    return make_png(128, 128, px)


def tex_roof():
    """Dark glazed roof tile with ridges."""
    def px(x, y):
        base = (72, 34, 40)
        n = value_noise(x, y, 0.10, 91)
        tile = math.sin(x * 0.32)
        shade = 0.85 + tile * 0.18 + n * 0.1
        r, g, b = base[0] * shade, base[1] * shade, base[2] * shade
        ridge = abs(math.sin(x * 0.16)) < 0.03
        if ridge:
            r, g, b = 120, 66, 66
        return (r, g, b)
    return make_png(128, 128, px)


def tex_stone():
    """Stone cobble path tiles."""
    def px(x, y):
        base = (104, 98, 104)
        n = value_noise(x, y, 0.10, 103)
        grout = (math.sin(x * 0.12) > 0.985) or (math.sin(y * 0.12) > 0.985)
        shade = 0.82 + n * 0.32
        if grout:
            shade = 0.45
        return (base[0] * shade, base[1] * shade, base[2] * shade * 0.98)
    return make_png(128, 128, px)


def tex_lantern():
    """Red paper lantern with gold bands and ribs."""
    def px(x, y):
        base = (186, 56, 52)
        n = value_noise(x, y, 0.12, 127)
        glow = math.exp(-((x - 64) ** 2 + (y - 64) ** 2) / 3600.0)
        rib = math.sin(x * 0.5) < -0.97
        band = abs(y - 24) < 5 or abs(y - 104) < 5
        r, g, b = base[0] + glow * 40 + n * 16, base[1] + glow * 10 + n * 16, base[2] + glow * 6 + n * 14
        if band:
            r, g, b = 232, 192, 110
        if rib:
            r, g, b = 140, 34, 34
        return (r, g, b)
    return make_png(128, 128, px)


TEXTURE_BUILDERS = {
    "cloth_wizard": tex_cloth_wizard,
    "cloth_spear": tex_cloth_spear,
    "skin": tex_skin,
    "fur": tex_fur,
    "belly": tex_belly,
    "horn": tex_horn,
    "gold": tex_gold,
    "wood": tex_wood,
    "roof": tex_roof,
    "stone": tex_stone,
    "lantern": tex_lantern,
}


# ================================================================ PRIMITIVES

def box(center, size):
    """Axis-aligned box; returns (verts, uvs, tris) with per-face UVs."""
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
    uvs = []
    for v in verts:
        x, y, z = v
        u = (x - (cx - hx)) / sx
        vv = (y - (cy - hy)) / sy
        uvs.append((u, vv))
    return verts, uvs, tris


def cylinder(center, r_top, r_bottom, height, segments, caps=True):
    cx, cy, cz = center
    y_top = cy + height * 0.5
    y_bot = cy - height * 0.5
    verts = []
    uvs = []
    for i in range(segments):
        ang = TAU * i / segments
        ca, sa = math.cos(ang), math.sin(ang)
        verts.append((cx + r_bottom * ca, y_bot, cz + r_bottom * sa))
        verts.append((cx + r_top * ca, y_top, cz + r_top * sa))
        u = i / segments
        uvs.append((u, 0.0))
        uvs.append((u, 1.0))
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
        uvs.append((0.5, 0.5))
        uvs.append((0.5, 0.5))
        for i in range(segments):
            a = i * 2
            b = (i * 2 + 2) % (segments * 2)
            tris.append((a, b, bottom))
            tris.append((a + 1, top, b + 1))
    return verts, uvs, tris


def sphere(center, radius, scale=(1.0, 1.0, 1.0), rings=10, segments=14):
    cx, cy, cz = center
    sx, sy, sz = scale
    verts = []
    uvs = []
    verts.append((cx, cy + radius * sy, cz))
    uvs.append((0.5, 0.0))
    for i in range(1, rings):
        phi = PI * i / rings
        y = math.cos(phi) * radius * sy
        r = math.sin(phi) * radius
        for j in range(segments):
            ang = TAU * j / segments
            verts.append((cx + r * math.cos(ang) * sx, cy + y, cz + r * math.sin(ang) * sz))
            uvs.append((j / segments, i / rings))
    bottom_pole = len(verts)
    verts.append((cx, cy - radius * sy, cz))
    uvs.append((0.5, 1.0))

    tris = []
    for j in range(segments):
        j2 = (j + 1) % segments
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
    return verts, uvs, tris


def cone(center, r_bottom, height, segments=12):
    return cylinder(center, 0.0, r_bottom, height, segments, caps=True)


def torus(center, radius, tube, segments=16, ring_segments=10):
    cx, cy, cz = center
    verts = []
    uvs = []
    for i in range(ring_segments):
        phi = TAU * i / ring_segments
        for j in range(segments):
            theta = TAU * j / segments
            x = (radius + tube * math.cos(theta)) * math.cos(phi)
            y = tube * math.sin(theta)
            z = (radius + tube * math.cos(theta)) * math.sin(phi)
            verts.append((cx + x, cy + y, cz + z))
            uvs.append((j / segments, i / ring_segments))
    tris = []
    for i in range(ring_segments):
        i2 = (i + 1) % ring_segments
        for j in range(segments):
            j2 = (j + 1) % segments
            a = i * segments + j
            b = i2 * segments + j
            tris.append((a, b, i2 * segments + j2))
            tris.append((a, i2 * segments + j2, i * segments + j2))
    return verts, uvs, tris


def curved_horn(center, length, base_radius, tip_radius, bend, segments=8, rings=6):
    """Tapered horn curving along +Y with a backward + lateral bend."""
    cx, cy, cz = center
    verts = []
    uvs = []
    for i in range(rings + 1):
        t = i / rings
        y = t * length
        x = bend * t * t * 0.6
        z = -bend * t * t * 0.5
        r = base_radius + (tip_radius - base_radius) * t
        for j in range(segments):
            ang = TAU * j / segments
            verts.append((cx + x + r * math.cos(ang), cy + y, cz + z + r * math.sin(ang)))
            uvs.append((j / segments, t))
    tris = []
    for i in range(rings):
        for j in range(segments):
            j2 = (j + 1) % segments
            a = i * segments + j
            b = (i + 1) * segments + j
            tris.append((a, b, b + (j2 - j)))
            tris.append((a, b + (j2 - j), a + (j2 - j)))
    return verts, uvs, tris


# ================================================================ BUILDER

class Geometry:
    """Vertex/UV/triangle soup with smooth, centroid-oriented normals."""

    def __init__(self):
        self.verts = []
        self.uvs = []
        self.tris = []

    def add(self, verts, uvs, tris):
        base = len(self.verts)
        self.verts.extend(verts)
        self.uvs.extend(uvs)
        self.tris.extend((a + base, b + base, c + base) for a, b, c in tris)

    def compute_normals(self):
        if not self.tris:
            return []
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


class GltfBuilder:
    def __init__(self, root_name):
        self.root_name = root_name
        self.nodes = []
        self.meshes = []
        self.materials = []
        self.images = []       # {name, uri(data URI)}
        self.textures = []     # {source, sampler}
        self.samplers = [{"magFilter": 9729, "minFilter": 9987, "wrapS": 10497, "wrapT": 10497}]
        self.bones = []        # (name, parent_idx, local_pos)
        self.parts = []        # (bone_idx, material_idx, Geometry)
        self.skins = []
        self.animations = []   # (name, {bone_name: [(t, euler_xyz), ...]})
        self._bin = bytearray()
        self.accessors = []
        self.buffer_views = []
        self._node_indices = {}
        self._image_indices = {}

    # ---- materials ----
    def add_material(self, name, color, metallic=0.0, roughness=0.6, emissive=None,
                     emissive_strength=1.0, texture=None, texture_tint=None):
        material = {
            "name": name,
            "pbrMetallicRoughness": {
                "baseColorFactor": [color[0], color[1], color[2], color[3] if len(color) > 3 else 1.0],
                "metallicFactor": metallic,
                "roughnessFactor": roughness,
            },
            "doubleSided": True,
        }
        if texture is not None:
            material["pbrMetallicRoughness"]["baseColorTexture"] = {"index": texture, "texCoord": 0}
            if texture_tint is not None:
                material["pbrMetallicRoughness"]["baseColorFactor"] = [
                    texture_tint[0], texture_tint[1], texture_tint[2], 1.0]
        if emissive is not None:
            material["emissiveFactor"] = [emissive[0], emissive[1], emissive[2]]
            material["emissiveStrength"] = emissive_strength
        self.materials.append(material)
        return len(self.materials) - 1

    def add_image(self, name, png_bytes):
        if name in self._image_indices:
            return self._image_indices[name]
        data_uri = "data:image/png;base64," + base64.b64encode(png_bytes).decode("ascii")
        self.images.append({"name": name, "uri": data_uri})
        self.textures.append({"source": len(self.images) - 1, "sampler": 0})
        self._image_indices[name] = len(self.textures) - 1
        return len(self.textures) - 1

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
                "generator": "SilkroadMobileGLBGenerator/2.0",
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
        if self.images:
            gltf["images"] = self.images
            gltf["textures"] = self.textures
            gltf["samplers"] = self.samplers
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
        uvs = []
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
            for u in geometry.uvs:
                uvs.append(u)
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
            "TEXCOORD_0": self._accessor(uvs, 5126, "VEC2", count=len(uvs)),
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
        components = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}[type_name]
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

def build_humanoid(style, textures):
    builder = GltfBuilder("Humanoid" + style.title())

    tex_cloth = builder.add_image("cloth", textures["cloth_wizard"] if style == "wizard" else textures["cloth_spear"])
    tex_skin_tex = builder.add_image("skin", textures["skin"])
    tex_gold_tex = builder.add_image("gold", textures["gold"])

    mat_skin = builder.add_material("skin", (1.0, 1.0, 1.0, 1.0), 0.0, 0.72, texture=tex_skin_tex)
    mat_cloth = builder.add_material("cloth", (1.0, 1.0, 1.0, 1.0), 0.05, 0.60, texture=tex_cloth)
    mat_gold = builder.add_material("gold", (1.0, 1.0, 1.0, 1.0), 0.65, 0.22, texture=tex_gold_tex)
    mat_dark = builder.add_material("dark", (0.14, 0.10, 0.14, 1.0), 0.05, 0.78)
    mat_hair = builder.add_material("hair", (0.09, 0.07, 0.12, 1.0), 0.0, 0.85)
    mat_eye = builder.add_material("eye", (0.20, 0.62, 0.92, 1.0), 0.05, 0.18, (0.12, 0.40, 0.70), 0.8)

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
    g.add(*box((0, 0.95, 0), (0.40, 0.28, 0.28)))
    attach(b_hips, mat_cloth, g)
    g = Geometry()
    g.add(*box((0, 1.16, 0), (0.48, 0.18, 0.30)))
    attach(b_spine, mat_cloth, g)
    g = Geometry()
    g.add(*box((0, 1.38, 0), (0.54, 0.28, 0.32)))
    attach(b_chest, mat_cloth, g)
    g = Geometry()
    g.add(*box((0, 1.62, 0), (0.18, 0.15, 0.18)))
    attach(b_neck, mat_skin, g)
    g = Geometry()
    g.add(*box((0, 1.77, 0), (0.30, 0.28, 0.30)))
    attach(b_head, mat_skin, g)

    # hair bun
    g = Geometry()
    g.add(*sphere((0, 1.99, -0.02), 0.10, (1.0, 0.8, 1.0), 7, 9))
    attach(b_head, mat_hair, g)
    # eyes
    for ex in (-0.06, 0.06):
        g = Geometry()
        g.add(*box((ex, 1.80, -0.156), (0.05, 0.03, 0.015)))
        attach(b_head, mat_eye, g)
    # brows
    for ex in (-0.06, 0.06):
        g = Geometry()
        g.add(*box((ex, 1.84, -0.158), (0.07, 0.02, 0.015)))
        attach(b_head, mat_hair, g)

    # arms
    for side in ("l", "r"):
        b_upper = b_ual if side == "l" else b_uar
        b_lower = b_lal if side == "l" else b_lar
        b_hand = b_hal if side == "l" else b_har
        sign = -1.0 if side == "l" else 1.0
        g = Geometry()
        g.add(*box((sign * 0.42, 1.42, 0), (0.16, 0.30, 0.16)))
        attach(b_upper, mat_cloth, g)
        g = Geometry()
        g.add(*box((sign * 0.42, 1.05, 0), (0.13, 0.30, 0.14)))
        attach(b_lower, mat_skin, g)
        g = Geometry()
        g.add(*box((sign * 0.42, 0.84, 0), (0.12, 0.15, 0.14)))
        attach(b_hand, mat_skin, g)
        # sleeve cuffs
        g = Geometry()
        g.add(*torus((sign * 0.42, 1.20, 0), 0.10, 0.022, 10, 6))
        attach(b_lower, mat_gold, g)

    # legs
    for side in ("l", "r"):
        b_thigh = b_tl if side == "l" else b_tr
        b_shin = b_sl if side == "l" else b_sr
        b_foot = b_fl if side == "l" else b_fr
        sign = -1.0 if side == "l" else 1.0
        g = Geometry()
        g.add(*box((sign * 0.15, 0.72, 0), (0.18, 0.34, 0.20)))
        attach(b_thigh, mat_cloth, g)
        g = Geometry()
        g.add(*box((sign * 0.15, 0.30, 0), (0.14, 0.32, 0.16)))
        attach(b_shin, mat_cloth, g)
        g = Geometry()
        g.add(*box((sign * 0.15, 0.02, 0.07), (0.14, 0.07, 0.26)))
        attach(b_foot, mat_dark, g)

    if style == "wizard":
        # flowing robe (bell shape)
        g = Geometry()
        g.add(*cylinder((0, 0.62, 0), 0.30, 0.52, 0.86, 14))
        attach(b_hips, mat_cloth, g)
        # gold sash + trim
        g = Geometry()
        g.add(*torus((0, 0.42, 0), 0.30, 0.035, 16, 8))
        attach(b_hips, mat_gold, g)
        g = Geometry()
        g.add(*torus((0, 1.02, 0), 0.24, 0.03, 16, 8))
        attach(b_hips, mat_gold, g)
        # jade pendant
        g = Geometry()
        g.add(*sphere((0, 0.92, -0.28), 0.055, (1.0, 1.0, 0.7), 6, 8))
        attach(b_chest, mat_eye, g)
        # pauldrons
        for b_sh, sign in ((b_shl, -1.0), (b_shr, 1.0)):
            g = Geometry()
            g.add(*sphere((sign * 0.30, 1.53, 0), 0.11, (1.0, 0.85, 1.0), 8, 10))
            attach(b_sh, mat_gold, g)
        # wide sleeves on upper arms
        for b_up, sign in ((b_ual, -1.0), (b_uar, 1.0)):
            g = Geometry()
            g.add(*sphere((sign * 0.44, 1.34, 0), 0.11, (1.0, 0.7, 1.0), 7, 9))
            attach(b_up, mat_cloth, g)
        # conical Asian straw hat
        g = Geometry()
        g.add(*cone((0, 2.06, 0), 0.30, 0.16, 16))
        attach(b_head, mat_cloth, g)
        g = Geometry()
        g.add(*cone((0, 2.20, 0), 0.14, 0.10, 12))
        attach(b_head, mat_cloth, g)
        g = Geometry()
        g.add(*torus((0, 2.02, 0), 0.22, 0.02, 16, 8))
        attach(b_head, mat_gold, g)
    else:
        # lamellar chest armor plates
        for row in range(4):
            for col in range(3):
                g = Geometry()
                g.add(*box((-0.18 + col * 0.18, 1.42 - row * 0.075, -0.14),
                           (0.15, 0.055, 0.02)))
                attach(b_chest, mat_gold if (row + col) % 2 == 0 else mat_cloth, g)
        # shoulder pauldrons
        for b_sh, sign in ((b_shl, -1.0), (b_shr, 1.0)):
            g = Geometry()
            g.add(*box((sign * 0.32, 1.53, 0), (0.26, 0.13, 0.28)))
            attach(b_sh, mat_gold, g)
        # tasset skirt
        g = Geometry()
        g.add(*cylinder((0, 0.90, 0), 0.34, 0.40, 0.30, 12))
        attach(b_hips, mat_cloth, g)
        g = Geometry()
        g.add(*torus((0, 0.88, 0), 0.30, 0.03, 16, 8))
        attach(b_hips, mat_gold, g)
        # helmet with crest
        g = Geometry()
        g.add(*sphere((0, 1.88, 0), 0.17, (1.0, 0.85, 1.05), 8, 10))
        attach(b_head, mat_gold, g)
        g = Geometry()
        g.add(*box((0, 2.00, -0.12), (0.26, 0.05, 0.10)))
        attach(b_head, mat_cloth, g)
        # arm guards
        for b_lo, sign in ((b_lal, -1.0), (b_lar, 1.0)):
            g = Geometry()
            g.add(*box((sign * 0.42, 1.10, 0), (0.15, 0.16, 0.15)))
            attach(b_lo, mat_gold, g)

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

def build_monster(textures):
    builder = GltfBuilder("Mangyang")

    tex_fur_tex = builder.add_image("fur", textures["fur"])
    tex_belly_tex = builder.add_image("belly", textures["belly"])
    tex_horn_tex = builder.add_image("horn", textures["horn"])
    tex_gold_tex = builder.add_image("gold", textures["gold"])

    mat_fur = builder.add_material("fur", (1.0, 1.0, 1.0, 1.0), 0.0, 0.88, texture=tex_fur_tex)
    mat_belly = builder.add_material("belly", (1.0, 1.0, 1.0, 1.0), 0.0, 0.84, texture=tex_belly_tex)
    mat_accent = builder.add_material("accent", (1.0, 1.0, 1.0, 1.0), 0.6, 0.22, texture=tex_gold_tex)
    mat_eye = builder.add_material("eye", (0.25, 0.78, 0.95, 1.0), 0.05, 0.15, (0.14, 0.55, 0.80), 0.9)
    mat_horn = builder.add_material("horn", (1.0, 1.0, 1.0, 1.0), 0.08, 0.5, texture=tex_horn_tex)
    mat_hoof = builder.add_material("hoof", (0.09, 0.11, 0.13, 1.0), 0.2, 0.6)
    mat_face = builder.add_material("face", (1.0, 1.0, 1.0, 1.0), 0.0, 0.8, texture=tex_fur_tex)

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
    attach(b_head, mat_face, g)
    # snout / muzzle
    g = Geometry()
    g.add(*box((0, 1.20, 0.82), (0.22, 0.14, 0.30)))
    attach(b_head, mat_face, g)
    # nostrils
    for ex in (-0.05, 0.05):
        g = Geometry()
        g.add(*box((ex, 1.18, 0.97), (0.03, 0.025, 0.02)))
        attach(b_head, mat_hoof, g)
    # jaw / mouth line
    g = Geometry()
    g.add(*box((0, 1.14, 0.80), (0.20, 0.02, 0.28)))
    attach(b_head, mat_hoof, g)
    # ears / tufts
    for ex in (-0.20, 0.20):
        g = Geometry()
        g.add(*cone((ex, 1.42, 0.42), 0.045, 0.16, 8))
        attach(b_head, mat_fur, g)
    # brow ridge
    for ex in (-0.10, 0.10):
        g = Geometry()
        g.add(*box((ex, 1.40, 0.62), (0.12, 0.05, 0.10)))
        attach(b_head, mat_fur, g)
    # eyes
    for ex in (-0.09, 0.09):
        g = Geometry()
        g.add(*sphere((ex, 1.34, 0.86), 0.035, (1.0, 0.8, 1.0), 5, 8))
        attach(b_head, mat_eye, g)
    # curved horns
    for sign in (-1.0, 1.0):
        g = Geometry()
        g.add(*curved_horn((sign * 0.13, 1.52, 0.42), 0.42, 0.06, 0.015, 0.5 * sign, 8, 6))
        attach(b_head, mat_horn, g)
    # cheek fangs
    for sign in (-1.0, 1.0):
        g = Geometry()
        g.add(*cone((sign * 0.09, 1.14, 0.92), 0.025, 0.09, 6))
        attach(b_head, mat_horn, g)
    # mane (hanging fur collar)
    for ang_i in range(10):
        a = TAU * ang_i / 10
        g = Geometry()
        g.add(*sphere((math.cos(a) * 0.24, 1.12, 0.24 + math.sin(a) * 0.18), 0.05, (1.0, 1.5, 1.0), 5, 7))
        attach(b_chest, mat_fur, g)

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

def build_weapon_staff(textures):
    builder = GltfBuilder("Staff")
    tex_wood_tex = builder.add_image("wood", textures["wood"])
    tex_gold_tex = builder.add_image("gold", textures["gold"])

    mat_wood = builder.add_material("wood", (1.0, 1.0, 1.0, 1.0), 0.0, 0.82, texture=tex_wood_tex)
    mat_gold = builder.add_material("gold", (1.0, 1.0, 1.0, 1.0), 0.7, 0.18, texture=tex_gold_tex)
    mat_orb = builder.add_material("orb", (0.35, 0.85, 1.0, 1.0), 0.1, 0.12, (0.20, 0.62, 0.90), 1.4)

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


def build_weapon_spear(textures):
    builder = GltfBuilder("Spear")
    tex_wood_tex = builder.add_image("wood", textures["wood"])
    tex_gold_tex = builder.add_image("gold", textures["gold"])

    mat_wood = builder.add_material("wood", (1.0, 1.0, 1.0, 1.0), 0.0, 0.82, texture=tex_wood_tex)
    mat_steel = builder.add_material("steel", (0.68, 0.72, 0.78, 1.0), 0.88, 0.22)
    mat_gold = builder.add_material("gold", (1.0, 1.0, 1.0, 1.0), 0.7, 0.18, texture=tex_gold_tex)
    mat_red = builder.add_material("tassel", (0.72, 0.14, 0.16, 1.0), 0.0, 0.85)

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
    # red tassel under blade
    g = Geometry()
    g.add(*cone((0, 0.74, 0), 0.035, 0.14, 6))
    builder.add_part(0, mat_red, g)
    # butt cap
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


def write_textures(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    for name, fn in TEXTURE_BUILDERS.items():
        path = os.path.join(out_dir, name + ".png")
        with open(path, "wb") as fh:
            fh.write(fn())
        print("wrote %s (%d bytes)" % (path, os.path.getsize(path)))


if __name__ == "__main__":
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    model_dir = os.path.join(project_root, "assets", "models")
    texture_dir = os.path.join(project_root, "assets", "textures")

    write_textures(texture_dir)
    textures = {name: fn() for name, fn in TEXTURE_BUILDERS.items()}

    write_glb(build_humanoid("wizard", textures), os.path.join(model_dir, "humanoid_wizard.glb"))
    write_glb(build_humanoid("spear", textures), os.path.join(model_dir, "humanoid_spear.glb"))
    write_glb(build_monster(textures), os.path.join(model_dir, "monster_mangyang.glb"))
    write_glb(build_weapon_staff(textures), os.path.join(model_dir, "weapon_staff.glb"))
    write_glb(build_weapon_spear(textures), os.path.join(model_dir, "weapon_spear.glb"))
    print("done")
