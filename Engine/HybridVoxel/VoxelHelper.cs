using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Threading.Tasks;

namespace VMEngine.Engine.HybridVoxel
{
	public struct VoxelHit
	{
		public Octree Leaf;
		public Chunk Chunk;
		public Vector3 HitPosition;
		public Vector3 HitNormal;
		public float Distance;
		public VoxelHit(Octree leaf, Chunk chunk, Vector3 pos, Vector3 normal, float distance) {
			Leaf= leaf;
			Chunk= chunk;
			HitPosition= pos;
			HitNormal= normal;
			Distance= distance;
		}
	}
}
