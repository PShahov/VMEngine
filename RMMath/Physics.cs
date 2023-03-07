using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using VMEngine.Voxel;

namespace VMEngine.Physics
{
	public class Hit
	{
		public Vector3 Position;
		public VoxelOctree Voxel;
		public float Distance;

		public Hit(Vector3 position, VoxelOctree voxel, float distance)
		{
			this.Position = position;
			this.Voxel = voxel;
			this.Distance = distance;
		}
	}

	public static class Physics
	{
		private struct CollisionLayer
		{
			public int Index;
			public string Name;
			public int Mask;

			public CollisionLayer(int index, string name, int mask)
			{
				Index= index;
				Name= name;
				Mask= mask;
			}
		}

		private static CollisionLayer[] collisionLayers = new CollisionLayer[]
		{
			new CollisionLayer(0, "Solid voxel", 1),
			new CollisionLayer(1, "Liquid voxel", 2),
		};

		public static int GetLayer(string layerName)
		{
			for(int i = 0;i < collisionLayers.Length;i++)
			{
				if (collisionLayers[i].Name.ToLower() == layerName.ToLower()) return i;
			}

			return -1;
		}

		public static int CreateMask(int[] indices)
		{
			int mask = 0;
			for(int i = 0;i < indices.Length;i++)
			{
				mask += collisionLayers[indices[i]].Mask;
			}

			return mask;
		}
	}


}
