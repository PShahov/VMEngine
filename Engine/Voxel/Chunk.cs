using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace VMEngine.Engine.Voxel
{
	public class Chunk
	{
		public static int CHUNK_SIZE_X = 16;
		public static int CHUNK_SIZE_Y = 128;
		public static int CHUNK_SIZE_Z = 16;

		public Block[,,] blocks;
		public Vector3 position = Vector3.zero;

		public Chunk()
		{
			blocks = new Block[CHUNK_SIZE_X, CHUNK_SIZE_Y, CHUNK_SIZE_Z];
			for (int x = 0; x < CHUNK_SIZE_X; x++)
			{
				for (int y = 0; y <CHUNK_SIZE_Y; y++)
				{
					for (int z = 0; z < CHUNK_SIZE_Z; z++)
					{
						blocks[x, y, z] = new Block();
					}
				}
			}
		}
	}

	public class Block
	{
		//public byte[,,][] VoxelArray = new byte[10, 10, 10][];
		public byte[,] data;

		public Block()
		{
			data = new byte[1000,2];
			for(int x = 0;x < 1000;x++)
			{
				for(int i = 0;i < 2; i++)
				{
					data[x,i] = 255;
				}
			}
		}
	}
}
