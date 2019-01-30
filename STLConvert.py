import numpy as np
from numpy.core.multiarray import ndarray
from stl import mesh

# Using an existing stl file:
your_mesh = mesh.Mesh.from_file("/home/glaba/Downloads/134700.stl")
r = 110
g = 255
b = 127
r_str = np.binary_repr(int(r / 256.0 * 2**5), 5)
g_str = np.binary_repr(int(g / 256.0 * 2**6), 6)
b_str = np.binary_repr(int(b / 256.0 * 2**5), 5)
color = r_str + g_str + b_str

# The mesh normals (calculated automatically)
your_mesh.normals
# The mesh vectors
your_mesh.v0, your_mesh.v1, your_mesh.v2
# Accessing individual points (concatenation of v0, v1 and v2 in triplets)
assert (your_mesh.points[0][0:3] == your_mesh.v0[0]).all()
assert (your_mesh.points[0][3:6] == your_mesh.v1[0]).all()
assert (your_mesh.points[0][6:9] == your_mesh.v2[0]).all()
assert (your_mesh.points[1][0:3] == your_mesh.v0[1]).all()


def float_to_fpbinary(mesh, places = 12,prefix=6):
    newmesh = []
    for i in range(len(mesh)):
        newcoord = ""
        for j in range(len(mesh[i])):
            val = mesh[i][j]
            if val > 32 - 2 ** -12:
                newcoord += ( str(np.binary_repr(2 ** 17 - 1, places + prefix)))
            elif val < -32:
                newcoord += (str(np.binary_repr(2 ** 17, places + prefix)))
            else:
                shifted = val * 2 ** 12
                newcoord+=(str(np.binary_repr(int(shifted), places + prefix)))
        newmesh.append(newcoord)
    return newmesh
def float_to_fpbinary_2d(mesh,places = 12, prefix=6):
    newmesh = []
    for i in range(len(mesh)):
        newcoord = ""
        val = mesh[i]
        if val > 32 - 2 ** -12:
            newcoord += (str(np.binary_repr(2 ** 17 - 1, places + prefix)))
        elif val < -32:
            newcoord += (str(np.binary_repr(2 ** 17, places + prefix)))
        else:
            shifted = val * 2 ** 12
            newcoord += (str(np.binary_repr(int(shifted), places + prefix)))
        newmesh.append(newcoord)
    return newmesh
def centering(mesh, offcenter):
    for i in range(len(mesh)):
        for j in range(len(mesh[i])):
            mesh[i][j]=mesh[i][j]-offcenter[j]
    return mesh
def scaling(mesh,scale):
    for i in range(len(mesh)):
        for j in range(len(mesh[i])):
            mesh[i][j]=mesh[i][j]*5/scale
    return mesh
avex=0
avey=0
avez=0
def distance_from_center(vert0,vert1,vert2):
    return np.sqrt(vert0**2 + vert1**2 + vert2**2)
for i in range(len(your_mesh.v0)):
    avex += your_mesh.v0[i][0] + your_mesh.v1[i][0] + your_mesh.v2[i][0]
    avey += your_mesh.v0[i][1] + your_mesh.v1[i][1] + your_mesh.v2[i][1]
    avez += your_mesh.v0[i][2] + your_mesh.v1[i][2] + your_mesh.v2[i][2]
avex=avex/(3*len(your_mesh.v0))
avey=avey/(3*len(your_mesh.v0))
avez=avez/(3*len(your_mesh.v0))
ave_mesh=[avex,avey,avez]
your_mesh.v0=centering(your_mesh.v0 , ave_mesh)
your_mesh.v1=centering(your_mesh.v1 , ave_mesh)
your_mesh.v2=centering(your_mesh.v2 , ave_mesh)
vertfurthest = 0
for i in range(len(your_mesh.v0)):
    v0test=distance_from_center(your_mesh.v0[i][0], your_mesh.v0[i][1], your_mesh.v0[i][2])
    v1test=distance_from_center(your_mesh.v1[i][0], your_mesh.v1[i][1], your_mesh.v1[i][2])
    v2test=distance_from_center(your_mesh.v2[i][0], your_mesh.v2[i][1], your_mesh.v2[i][2])
    if v0test > vertfurthest :
        vertfurthest = v0test
    if v1test > vertfurthest:
        vertfurthest = v1test
    if v2test > vertfurthest:
        vertfurthest = v2test

your_mesh.v0=scaling(your_mesh.v0, vertfurthest)
your_mesh.v1=scaling(your_mesh.v1, vertfurthest)
your_mesh.v2=scaling(your_mesh.v2, vertfurthest)
# print(your_mesh.v0)
your_mesh_v0=(float_to_fpbinary(your_mesh.v0,12,6))
your_mesh_v1=(float_to_fpbinary(your_mesh.v1,12,6))
your_mesh_v2=(float_to_fpbinary(your_mesh.v2,12,6))

# normalize normals
for j in range(len(your_mesh.normals)):
    length = np.sqrt(your_mesh.normals[j][0]**2 + your_mesh.normals[j][1]**2 + your_mesh.normals[j][2]**2)
    for i in range(0, 3):
        your_mesh.normals[j][i] /= -length
print your_mesh.normals

your_mesh_normal=(float_to_fpbinary(your_mesh.normals,12,6))
your_mesh_average=(float_to_fpbinary_2d(ave_mesh,12,6))
# print(your_mesh_average)
f0 = open("v1.mem","w+")
f1 = open("v2.mem","w+")
f2 = open("v3.mem","w+")
fcolor = open("color.mem", "w+")
fnormal = open("normal.mem","w+")
for string in your_mesh_v0:
    f0.write("%s\n" % string)
f0.close()
for string in your_mesh_v1:
    f1.write("%s\n" % string)
f1.close()
for string in your_mesh_v2:
    f2.write("%s\n" % string)
f2.close()
for string in your_mesh_normal:
    fnormal.write("%s\n" % string)
fnormal.close()
for string in your_mesh_normal:
    fcolor.write("%s\n" % color)
fcolor.write("0000000000000000")