using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace VMEngine.Engine.HybridVoxel
{
	public class Chunk
	{
		
		public static int CHUNK_EDGE = 32;
		//public static int TOTAL_BLOCKS { get { return CHUNK_EDGE * CHUNK_EDGE * CHUNK_EDGE; } }
		//public static int BYTES_PER_BLOCK = 5;
		//public static int BYTES_PER_CHUNK { get { return TOTAL_BLOCKS * BYTES_PER_BLOCK + (4 * 3); } }

		public Octree Octree;

		public Vector3 Position;
		public int DataOffset;

		public float[] Data = null;

		public bool flag_dataUpdateNeeded = false;
		public bool flag_dataPushNeeded = false;

		public Chunk(Vector3 position)
		{
			Position = position;
			Octree = new Octree(0, position, new VoxelColor(255,255,0), hvState.GenerateState(VoxelStateIndex.Fullfilled, VoxelStateIndex.FillState));

		}

		public void RegenChunk()
		{
			Octree = new Octree(0, Position, new VoxelColor(255, 255, 0), hvState.GenerateState(VoxelStateIndex.Fullfilled, VoxelStateIndex.FillState));
		}

		public void UpdateData()
		{
			float[] data = Octree.GetLowestOctreeDataRecursively();
			data[0] = new VoxelColor(this.Octree.LeafsCount).ToFloat(true);
			data[1] = this.Position.x;
			data[2] = this.Position.y;
			data[3] = this.Position.z;

			this.Data = data;

			flag_dataUpdateNeeded = false;
			flag_dataPushNeeded = true;
		}

		public float[] GetData()
		{

			if(Data != null) return Data;

			UpdateData();

			return Data;
		}

		//public byte[] GetData() { return Data; }
		//public byte[] GetSubData() { return SubData.ToArray(); }
	}
}
