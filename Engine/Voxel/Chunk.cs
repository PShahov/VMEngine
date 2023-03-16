using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace VMEngine.Engine.Voxel
{
	public class Chunk
	{
		//public static int CHUNK_SIZE_X = 16;
		//public static int CHUNK_SIZE_Y = 64;
		//public static int CHUNK_SIZE_Z = 16;
		public static int CHUNK_SIZE_X = 1;
		public static int CHUNK_SIZE_Y = 1;
		public static int CHUNK_SIZE_Z = 1;

		public static int CHUNK_TOTAL_BLOCK { get { return CHUNK_SIZE_X * CHUNK_SIZE_Y * CHUNK_SIZE_Z; } }

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

		public float[] ToFloatArray()
		{
			float[] ret = new float[CHUNK_SIZE_X * CHUNK_SIZE_Y * CHUNK_SIZE_Z * 1000];
			return ret;
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
				data[x, 0] = 0b00000001;
				data[x, 1] = 0b00000001;
			}
		}

		public float[] ToFloatArray()
		{
			float[] ret = new float[1000];
			for(int i = 0;i < 1000; i++)
			{
				ret[i] = System.BitConverter.ToSingle(new byte[] { data[i,0], data[i,1] });
			}

			return ret;
		}
	}
}
