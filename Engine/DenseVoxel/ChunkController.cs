﻿using StbImageSharp;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using VMEngine.Physics;

namespace VMEngine.Engine.DenseVoxel
{
    public static class ChunkController
    {
        public static Chunk[,,] Chunks { get; private set; }

        public static int SizeX = 1;
        public static int SizeY = 1;
        public static int SizeZ = 1;

        public static int TotalChunksCount { get { return SizeX * SizeY * SizeZ; } }

        public static float ChunkSize = 1f;

        public static void GenerateArea(Vector3 center)
        {
            center -= new Vector3((SizeX - 1) * 0.5f, (SizeY - 1) * 0.5f, (SizeZ - 1) * 0.5f) * ChunkSize;
            Chunks = new Chunk[SizeX, SizeY, SizeZ];
            for (int x = 0; x < SizeX; x++)
            {
                for (int z = 0; z < SizeZ; z++)
                {
                    for (int y = 0; y < SizeY; y++)
                    {
                        Chunks[x, y, z] = new Chunk(center + new Vector3(x * ChunkSize, y * ChunkSize, z * ChunkSize));
                    }
                }
            }
		}


        public static void Tick()
        {
			for (int x = 0; x < SizeX; x++)
			{
				for (int z = 0; z < SizeZ; z++)
				{
					for (int y = 0; y < SizeY; y++)
					{
						Chunks[x, y, z].Tick();
					}
				}
			}
		}

		public static void Draw()
		{
			for (int x = 0; x < SizeX; x++)
			{
				for (int z = 0; z < SizeZ; z++)
				{
					for (int y = 0; y < SizeY; y++)
					{
                        Chunks[x, y, z].Draw();
					}
				}
			}
		}

        public static void UnbindAll()
		{
			for (int x = 0; x < SizeX; x++)
			{
				for (int z = 0; z < SizeZ; z++)
				{
					for (int y = 0; y < SizeY; y++)
					{
						Chunks[x, y, z].Unbind();
					}
				}
			}
		}

		//public static float[] GetFloats()
  //      {
  //          Program.vm.voxelCount = 0;

  //          Chunk c = Chunks[0, 0, 0];
  //          Block b = c.blocks[0,0,0];
  //          float[] ret = new float[1003];
		//	ret[0] = 0;
		//	ret[1] = 0;
		//	ret[2] = 0;

  //          for(int i = 0;i < 100; i++)
  //          {
  //              ret[i + 3] = new VoxelColor(b.data[i, 0], b.data[i, 1], 0, 0).ToFloat();
		//		Program.vm.voxelCount++;
		//	}

  //          return ret;
		//}

  //      public static void GenerateTexture()
  //      {
  //          int texWidth = TotalChunksCount;
  //          int texHeight = Chunk.CHUNK_TOTAL_BLOCK * 1000;

  //          Bitmap bmp = new Bitmap(texWidth, texHeight, System.Drawing.Imaging.PixelFormat.Format4bppIndexed);
  //          Graphics g = Graphics.FromImage(bmp);
  //          int i = 0;
		//	for (int x = 0; x < SizeX; x++)
		//	{
		//		for (int z = 0; z < SizeZ; z++)
		//		{
		//			for (int y = 0; y < SizeY; y++)
		//			{

  //                      g.DrawImage(ChunkTexture(Chunks[x,y,z]), new Point(i, 0));
  //                          i++;
		//			}
		//		}
		//	}
		//}


		//private static Bitmap ChunkTexture(Chunk chunk)
  //      {
  //          Bitmap bmp = new Bitmap(1, (Chunk.CHUNK_TOTAL_BLOCK * 1000) + 3, System.Drawing.Imaging.PixelFormat.Format4bppIndexed);

		//	for (int x = 0; x < Chunk.CHUNK_SIZE_X; x++)
		//	{
		//		for (int z = 0; z < Chunk.CHUNK_SIZE_Z; z++)
		//		{
		//			for (int y = 0; y < Chunk.CHUNK_SIZE_Y; y++)
		//			{
		//				Block b = chunk.blocks[x, y, z];
		//				for (int i = 0;i < 1000; i++)
  //                      {
  //                          //bmp.SetPixel(Color.)
  //                      }
		//			}
		//		}
		//	}

		//	return bmp;
  //      }


        public static Hit CastRay(Vector3 origin, Vector3 direction, int mask, float distance = 0, bool filledOnly = true)
        {
            Hit hit = null;

            //for (int x = 0; x < SizeX; x++)
            //{
            //    for (int z = 0; z < SizeZ; z++)
            //    {
            //        for (int y = 0; y < SizeY; y++)
            //        {
            //            VoxelOctree vox = Chunks[x, y, z];
            //            float hitDistance = 0;
            //            if (vox.GetState(0) == false) continue;
            //            if (!_RayAABBIntersection(origin, direction, vox.Position - Vector3.one * vox.EdgeSize / 2, vox.Position + Vector3.one * vox.EdgeSize / 2, out hitDistance)) continue;

            //            VoxelOctree[] subVoxs = vox.GetAllSubvoxels();

            //            for (int i = 0; i < subVoxs.Length; i++)
            //            {
            //                vox = subVoxs[i];
            //                if (vox.GetState(0) == false) continue;
            //                if (!_RayAABBIntersection(origin, direction, vox.Position - Vector3.one * vox.EdgeSize / 2, vox.Position + Vector3.one * vox.EdgeSize / 2, out hitDistance)) continue;


            //                if (hit == null)
            //                    hit = new Hit(origin + direction * hitDistance, vox, hitDistance);
            //                else if (hitDistance < hit.Distance)
            //                    hit = new Hit(origin + direction * hitDistance, vox, hitDistance);
            //                else
            //                    continue;
            //            }
            //        }
            //    }
            //}

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