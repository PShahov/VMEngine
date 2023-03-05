using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace VMEngine.Voxel
{
	public static class ChunkController
	{
		public static VoxelOctree[,] Chunks { get; private set; }

		public static int SizeX = 1;
		public static int SizeY = 1;
		public static int SizeZ = 1;

		public static float ChunkSize = 16;

		public static void GenerateArea(Vector3 center)
		{
			center -= new Vector3(SizeX * 0.5f, SizeY * 0.5f, SizeZ * 0.5f) * ChunkSize;
			Chunks = new VoxelOctree[SizeX, SizeZ];
			for(int x = 0; x < SizeX; x++)
			{
				for(int z = 0; z < SizeZ; z++)
				{
					Chunks[x, z] = new VoxelOctree(center, ChunkSize, new VoxelColor(155, 100, 20));
				}
			}
		}

		public static void GenerateTexture()
		{

		}
	}
}
