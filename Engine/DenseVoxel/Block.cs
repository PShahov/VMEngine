using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace VMEngine.Engine.DenseVoxel
{
	public class Block
	{
		//public byte[,,][] VoxelArray = new byte[10, 10, 10][];
		public byte[,] data;

		public Block()
		{
			data = new byte[1000, 2];
			for (int x = 0; x < 1000; x++)
			{
				data[x, 0] = 0b00000001;
				data[x, 1] = 0b00000001;
			}
		}

		public float[] ToFloatArray()
		{
			float[] ret = new float[1000];
			for (int i = 0; i < 1000; i++)
			{
				ret[i] = System.BitConverter.ToSingle(new byte[] { data[i, 0], data[i, 1] });
			}

			return ret;
		}
	}
}
