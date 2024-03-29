﻿using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using VMEngine.Physics;

using OpenTK.Graphics.OpenGL;
using System.Reflection.Metadata;

namespace VMEngine.Engine.SparseVoxel
{
    public static class ChunkController
    {
        public static VoxelOctree[,,] Chunks { get; private set; }

        public static int SizeX = 1;
        public static int SizeY = 1;
        public static int SizeZ = 1;

        public static float ChunkSize = 12.8f;

        public static int TexBufHandle = 1;

        public static void Startup()
        {

        }

        public static void GenerateArea(Vector3 center)
        {
            center -= new Vector3((SizeX - 1) * 0.5f, (SizeY - 1) * 0.5f, (SizeZ - 1) * 0.5f) * ChunkSize;
            Chunks = new VoxelOctree[SizeX, SizeY, SizeZ];
            for (int x = 0; x < SizeX; x++)
            {
                for (int z = 0; z < SizeZ; z++)
                {
                    for (int y = 0; y < SizeY; y++)
                    {
                        Chunks[x, y, z] = new VoxelOctree(center, VoxelOctree.DEFAULT_EDGE_SIZE, new VoxelColor(155, 100, 20));
                        Chunks[x, y, z].Divide();
                        Chunks[x, z, y].CalcArround();
                    }
                }
            }
        }

        public static Bitmap GenerateTexture()
        {
            float[] floats = AllChunksFloats();
            byte[] bytes = FloatsToBytes(AllChunksFloats());
            //float[] floats2 = BytesToFloats(bytes);
            //Bitmap bmp;
            //using (MemoryStream ms = new MemoryStream(bytes))
            //{
            //	bmp = new Bitmap(ms);
            //}
            Bitmap bmp = new Bitmap(1, floats.Length);
            for (int i = 0; i < floats.Length; i++)
            {
                bmp.SetPixel(0, i, VoxelColor.FloatToColor(floats[i]));

            }
            for (int i = 0; i < bytes.Length; i++)
            {
                bytes[i] = 255;
            }

            GL.ActiveTexture(TextureUnit.Texture0);
            GL.BindTexture(TextureTarget.TextureBuffer, TexBufHandle);

            //GL.TexImage2D(TextureTarget.TextureBuffer, 0, PixelInternalFormat.Rgba, bmp.Width, bmp.Height, 0, PixelFormat.Rgba, PixelType.UnsignedByte, bytes);
            GL.TexBuffer(TextureBufferTarget.TextureBuffer, SizedInternalFormat.Rgba32f, Assets.Textures["testTex"].Handle);

            return bmp;
        }

        private static byte[] FloatsToBytes(float[] floats)
        {
            byte[] bytes = new byte[floats.Length * 4];
            byte[] temp = new byte[4];
            int j = 0;
            for (int i = 0; i < bytes.Length; i += 4)
            {
                temp = BitConverter.GetBytes(floats[j]);
                j++;
                bytes[i + 0] = temp[0];
                bytes[i + 1] = temp[1];
                bytes[i + 2] = temp[2];
                bytes[i + 3] = temp[3];
            }

            return bytes;
        }
        private static float[] BytesToFloats(byte[] bytes)
        {
            float[] floats = new float[bytes.Length / 4];
            for (int i = 0; i < floats.Length; i++)
            {
                floats[i] = new VoxelColor(bytes[i * 4 + 3], bytes[i * 4 + 2], bytes[i * 4 + 1], bytes[i * 4 + 0]).ToFloat();
            }

            return floats;
        }

        public static float[] test()
        {
            Bitmap bmp = GenerateTexture();

            float[] floats = new float[bmp.Height];

            for (int i = 0; i < floats.Length; i++)
            {
                floats[i] = VoxelColor.ColorToFloat(bmp.GetPixel(0, i));
            }

            floats = AllChunksFloats();

            //floats[7] = new VoxelColor(255, 0, 0, 255).ToFloat();

            return floats;
        }

        public static float[] AllChunksFloats()
        {
            int texelsCount = 0;
            float[][] texels = new float[SizeX * SizeY * SizeZ][];

            int i = 0;
            for (int x = 0; x < SizeX; x++)
            {
                for (int z = 0; z < SizeZ; z++)
                {
                    for (int y = 0; y < SizeY; y++)
                    {
                        texels[i] = ChunkFloats(x, y, z);
                        texelsCount = texels[i].Length;
                        i++;
                    }
                }
            }

            List<float> floats = new List<float>(texelsCount);
            for (i = 0; i < SizeX * SizeY * SizeZ; i++)
            {
                floats.AddRange(texels[i]);
            }
            return floats.ToArray();
        }

        public static float[] ChunkFloats(int x, int y, int z)
        {
            VoxelOctree oct = Chunks[x, y, z];

            float[] voxs = oct.ToArray();



            List<float> floats = new List<float>(voxs.Length + 4);


            floats.AddRange(oct.Position.ToArray());
            floats.Add(voxs.Length);
            //floats.AddRange(voxs);
            VoxelSortStruct[] vss = new VoxelSortStruct[voxs.Length / 5];
            for (int i = 0; i < vss.Length; i++)
            {
                vss[i] = new VoxelSortStruct(new float[]
                {
                    voxs[i * 5],
                    voxs[i * 5 + 1],
                    voxs[i * 5 + 2],
                    voxs[i * 5 + 3],
                    voxs[i * 5 + 4],
                });
            }
            MergeSort(vss, 0, vss.Length - 1, oct.Position);

            int voxCount = vss.Length;
            //vss[0].data[4] = new VoxelColor(255, 0, 0, 255).ToFloat();

            for(int i = 0;i < voxCount; i++)
            {
                byte c = (byte)(255 / (i + 1));
                vss[i].data[4] = new VoxelColor(c,c,c, 255).ToFloat();
			}

            for (int i = 0; i < vss.Length; i++)
            {
                floats.AddRange(vss[i].data);
            }

            return floats.ToArray();
        }

        //метод для слияния массивов
        static void Merge(VoxelSortStruct[] array, int lowIndex, int middleIndex, int highIndex, Vector3 offset)
        {
            var left = lowIndex;
            var right = middleIndex + 1;
            var tempArray = new VoxelSortStruct[highIndex - lowIndex + 1];
            var index = 0;

            while (left <= middleIndex && right <= highIndex)
            {
                if (array[left].distance(offset) < array[right].distance(offset))
                {
                    tempArray[index] = array[left];
                    left++;
                }
                else
                {
                    tempArray[index] = array[right];
                    right++;
                }

                index++;
            }

            for (var i = left; i <= middleIndex; i++)
            {
                tempArray[index] = array[i];
                index++;
            }

            for (var i = right; i <= highIndex; i++)
            {
                tempArray[index] = array[i];
                index++;
            }

            for (var i = 0; i < tempArray.Length; i++)
            {
                array[lowIndex + i] = tempArray[i];
            }
        }

        //сортировка слиянием
        static VoxelSortStruct[] MergeSort(VoxelSortStruct[] array, int lowIndex, int highIndex, Vector3 offset)
        {
            if (lowIndex < highIndex)
            {
                var middleIndex = (lowIndex + highIndex) / 2;
                MergeSort(array, lowIndex, middleIndex, offset);
                MergeSort(array, middleIndex + 1, highIndex, offset);
                Merge(array, lowIndex, middleIndex, highIndex, offset);
            }

            return array;
        }

        public static Hit CastRay(Vector3 origin, Vector3 direction, int mask, float distance = 0, bool filledOnly = true)
        {
            Hit hit = null;

            for (int x = 0; x < SizeX; x++)
            {
                for (int z = 0; z < SizeZ; z++)
                {
                    for (int y = 0; y < SizeY; y++)
                    {
                        VoxelOctree vox = Chunks[x, y, z];
                        float hitDistance = 0;
                        if (vox.GetState(0) == false) continue;
                        if (!_RayAABBIntersection(origin, direction, vox.Position - Vector3.one * vox.EdgeSize / 2, vox.Position + Vector3.one * vox.EdgeSize / 2, out hitDistance)) continue;

                        VoxelOctree[] subVoxs = vox.GetAllSubvoxels();

                        for (int i = 0; i < subVoxs.Length; i++)
                        {
                            vox = subVoxs[i];
                            if (vox.GetState(0) == false) continue;
                            if (!_RayAABBIntersection(origin, direction, vox.Position - Vector3.one * vox.EdgeSize / 2, vox.Position + Vector3.one * vox.EdgeSize / 2, out hitDistance)) continue;


                            if (hit == null)
                                hit = new Hit(origin + direction * hitDistance, vox, hitDistance);
                            else if (hitDistance < hit.Distance)
                                hit = new Hit(origin + direction * hitDistance, vox, hitDistance);
                            else
                                continue;
                        }
                    }
                }
            }

            return hit;
        }

        public static bool _RayAABBIntersection(Vector3 ro, Vector3 rd, Vector3 boxMin, Vector3 boxMax, out float distance)
        {
            Vector3 dirfrac = Vector3.zero;
            // rd is unit direction vector of ray
            dirfrac.x = 1.0f / rd.x;
            dirfrac.y = 1.0f / rd.y;
            dirfrac.z = 1.0f / rd.z;
            // boxMin is the corner of AABB with minimal coordinates - left bottom, boxMax is maximal corner
            // ro is origin of ray
            float t1 = (boxMin.x - ro.x) * dirfrac.x;
            float t2 = (boxMax.x - ro.x) * dirfrac.x;
            float t3 = (boxMin.y - ro.y) * dirfrac.y;
            float t4 = (boxMax.y - ro.y) * dirfrac.y;
            float t5 = (boxMin.z - ro.z) * dirfrac.z;
            float t6 = (boxMax.z - ro.z) * dirfrac.z;

            float tmin = MathF.Max(MathF.Max(MathF.Min(t1, t2), MathF.Min(t3, t4)), MathF.Min(t5, t6));
            float tmax = MathF.Min(MathF.Min(MathF.Max(t1, t2), MathF.Max(t3, t4)), MathF.Max(t5, t6));

            // if tmax < 0, ray (line) is intersecting AABB, but the whole AABB is behind us
            if (tmax < 0)
            {
                distance = tmax;
                return false;
            }

            // if tmin > tmax, ray doesn't intersect AABB
            if (tmin > tmax)
            {
                distance = tmax;
                return false;
            }

            distance = tmin;
            return true;
        }
    }
}
