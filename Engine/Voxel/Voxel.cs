using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace VMEngine.Engine.Voxel
{
	public struct Voxel
	{
		//VoxelColor Color;
		byte[] Data;

		public Voxel(byte[] color, short blockId)
		{
			Data = color;
			//this.Color = color;
			//this.BlockId = blockId;
		}
	}
}
