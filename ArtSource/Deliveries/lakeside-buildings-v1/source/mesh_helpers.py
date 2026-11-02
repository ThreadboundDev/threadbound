import bpy, math, random
from mathutils import Vector
B={}
COLS={}
MATS={}

class Batch:

    def __init__(self, group, mat):
        self.group = group
        self.mat = mat
        self.v = []
        self.f = []
        self.uv = []

    def face(self, verts, uv=None):
        start = len(self.v)
        self.v.extend(verts)
        self.f.append(tuple(range(start, start + len(verts))))
        if uv is None:
            v0 = Vector(verts[0])
            a = Vector(verts[1]) - v0
            length = a.length
            if length < 1e-08:
                uv = [(0, 0)] * len(verts)
            else:
                a.normalize()
                normal = a.cross(Vector(verts[-1]) - v0)
                if normal.length > 1e-08:
                    normal.normalize()
                b = normal.cross(a)
                uv = [((Vector(v) - v0).dot(a) / 2.5, (Vector(v) - v0).dot(b) / 2.5) for v in verts]
        self.uv.append(uv)

    def build(self):
        me = bpy.data.meshes.new(self.group + '_' + self.mat)
        me.from_pydata(self.v, [], self.f)
        me.update()
        ob = bpy.data.objects.new(self.group + '__' + self.mat, me)
        COLS[self.group][0].objects.link(ob)
        ob.parent = COLS[self.group][1]
        me.materials.append(MATS[self.mat])
        uv = me.uv_layers.new(name='UVMap')
        for poly, coords in zip(me.polygons, self.uv):
            for li, co in zip(poly.loop_indices, coords):
                uv.data[li].uv = co
        if self.mat in ['walnut', 'plaster', 'slate']:
            mod = ob.modifiers.new('Small silhouette and edge highlights', 'BEVEL')
            mod.width = 0.018 if self.mat != 'slate' else 0.025
            mod.segments = 1
            mod.limit_method = 'ANGLE'
            mod = ob.modifiers.new('Weighted normals', 'WEIGHTED_NORMAL')
            mod.keep_sharp = True
        for p in me.polygons:
            p.use_smooth = self.mat in ['blue_tiles', 'rope']
        return ob

def batch(g, m):
    if (g, m) not in B:
        B[g, m] = Batch(g, m)
    return B[g, m]

def face(g, m, vs, uv=None):
    batch(g, m).face(vs, uv)

def box(g, m, loc, size):
    x, y, z = loc
    a, b, c = [s / 2 for s in size]
    vs = [(x - a, y - b, z - c), (x + a, y - b, z - c), (x + a, y + b, z - c), (x - a, y + b, z - c), (x - a, y - b, z + c), (x + a, y - b, z + c), (x + a, y + b, z + c), (x - a, y + b, z + c)]
    for inds in [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]:
        pts = [vs[j] for j in inds]
        if m == 'walnut':
            p0, p1, p3 = map(Vector, [pts[0], pts[1], pts[-1]])
            aa = (p1 - p0).length
            bb = (p3 - p0).length
            off = random.random() * 0.8
            if aa > bb:
                uv = [(off + (Vector(p) - p0).dot((p3 - p0).normalized()) * 1.4, (Vector(p) - p0).dot((p1 - p0).normalized()) / 2.3) for p in pts]
            else:
                uv = [(off + (Vector(p) - p0).dot((p1 - p0).normalized()) * 1.4, (Vector(p) - p0).dot((p3 - p0).normalized()) / 2.3) for p in pts]
            face(g, m, pts, uv)
        elif m == 'slate':
            u0 = random.choice([0.04, 0.22, 0.38])
            v0 = random.choice([0.05, 0.28, 0.55, 0.76])
            face(g, m, pts, [(u0, v0), (u0 + 0.1, v0), (u0 + 0.1, v0 + 0.16), (u0, v0 + 0.16)])
        else:
            face(g, m, pts)

def beam(g, m, p1, p2, width, depth=None):
    a = Vector(p1)
    b = Vector(p2)
    d = b - a
    helper = Vector((0, 1, 0)) if abs(d.normalized().y) < 0.8 else Vector((1, 0, 0))
    u = d.normalized().cross(helper).normalized() * width / 2
    v = d.normalized().cross(u).normalized() * (depth or width) / 2
    vs = [tuple(p + u * su + v * sv) for p in [a, b] for su, sv in [(-1, -1), (1, -1), (1, 1), (-1, 1)]]
    for inds in [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]:
        face(g, m, [vs[j] for j in inds])

def tube(g, m, points, r=0.025, sides=6):
    rings = []
    for j, p in enumerate(points):
        p = Vector(p)
        t = Vector(points[min(j + 1, len(points) - 1)]) - Vector(points[max(j - 1, 0)])
        t.normalize()
        u = t.cross(Vector((0, 0, 1)))
        if u.length < 0.01:
            u = t.cross(Vector((0, 1, 0)))
        u.normalize()
        v = t.cross(u).normalized()
        rings.append([tuple(p + r * (u * math.cos(k * math.tau / sides) + v * math.sin(k * math.tau / sides))) for k in range(sides)])
    for j in range(len(rings) - 1):
        for k in range(sides):
            face(g, m, [rings[j][k], rings[j][(k + 1) % sides], rings[j + 1][(k + 1) % sides], rings[j + 1][k]], [(k / sides, j * 0.2), ((k + 1) / sides, j * 0.2), ((k + 1) / sides, (j + 1) * 0.2), (k / sides, (j + 1) * 0.2)])

def peg(g, x, y, z):
    tube(g, 'iron', [(x, y + 0.02, z), (x, y - 0.04, z)], 0.037, 8)

def stone_run(g, x0, x1, y0, y1, z0, z1, along='x', course=0.38):
    rows = max(1, round((z1 - z0) / course))
    rh = (z1 - z0) / rows
    for row in range(rows):
        lo, hi = (x0, x1) if along == 'x' else (y0, y1)
        span = hi - lo
        n = max(1, round(span / 0.76))
        step = span / n
        cuts = [lo] + [lo + i * step + (0.24 * step if row % 2 else 0) for i in range(1, n)] + [hi]
        for a, b in zip(cuts, cuts[1:]):
            if along == 'x':
                loc = ((a + b) / 2, (y0 + y1) / 2, z0 + (row + 0.5) * rh)
                sz = (b - a - 0.022, y1 - y0 - 0.012, rh - 0.02)
            else:
                loc = ((x0 + x1) / 2, (a + b) / 2, z0 + (row + 0.5) * rh)
                sz = (x1 - x0 - 0.012, b - a - 0.022, rh - 0.02)
            box(g, 'slate', loc, sz)

def window(g, cx, y, z, width=1.55, height=1.65, side=False):

    def part(xoff, zoff, w, h, mat, dep=0.12):
        if not side:
            box(g, mat, (cx + xoff, y, z + zoff), (w, dep, h))
        else:
            box(g, mat, (y, cx + xoff, z + zoff), (dep, w, h))
    part(0, 0, width, height, 'recess', 0.07)
    for x in [-width / 2, width / 2]:
        part(x, 0, 0.15, height + 0.3, 'walnut', 0.19)
    for zz in [-height / 2, height / 2]:
        part(0, zz, width + 0.3, 0.16, 'walnut', 0.21)
    for k in range(7):
        part(-width * 0.42 + k * width * 0.14, 0, 0.055, height, 'walnut', 0.22)
    for zz in [-height * 0.23, height * 0.23]:
        part(0, zz, width, 0.06, 'walnut', 0.23)
