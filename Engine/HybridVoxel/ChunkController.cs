using OpenTK.Graphics.OpenGL;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using VMEngine.Engine.BufferObjects;
using VMEngine.Engine.SparseVoxel;

namespace VMEngine.Engine.HybridVoxel
{
	public static class ChunkController
	{
		public static int AREA_SIZE_X = 1;
		public static int AREA_SIZE_Y = 1;
		public static int AREA_SIZE_Z = 1;
		public static int TOTAL_CHUNKS { get { return AREA_SIZE_Z * AREA_SIZE_Y * AREA_SIZE_X; } }

		public static bool AsyncMode = true;


		public static TextureBufferObject tbo;
		public static TextureBufferObject tbo2;
		public static ShaderStorageBufferObject ssbo;
		public static Chunk[,,] Chunks { get; private set; }
		public static void GenerateArea(Vector3 center)
		{
			center -= new Vector3((AREA_SIZE_X - 1) * 0.5f, (AREA_SIZE_Y - 1) * 0.5f, (AREA_SIZE_Z - 1) * 0.5f) * Chunk.CHUNK_EDGE;
			Chunks = new Chunk[AREA_SIZE_X, AREA_SIZE_Y, AREA_SIZE_Z];

			for (int x = 0; x < AREA_SIZE_X; x++)
			{
				for (int z = 0; z < AREA_SIZE_Z; z++)
				{
					for (int y = 0; y < AREA_SIZE_Y; y++)
					{
						Vector3 pos = center + new Vector3(x * Chunk.CHUNK_EDGE, y * Chunk.CHUNK_EDGE, z * Chunk.CHUNK_EDGE);
						Chunks[x, y, z] = new Chunk(pos);
					}
				}
			}
		}

		public static void Startup()
		{
			//ssbo = new ShaderStorageBufferObject(256*256*256);
		}

		public static void AsyncTick()
		{
			while (true)
			{
				for (int x = 0; x < AREA_SIZE_X; x++)
				{
					for (int z = 0; z < AREA_SIZE_Z; z++)
					{
						for (int y = 0; y < AREA_SIZE_Y; y++)
						{
							if (Chunks[x, y, z].flag_dataUpdateNeeded)
							{
								Chunks[x, y, z].UpdateData();
							}
						}
					}
				}
			}
		}

		public static void Tick()
		{
			bool pushNeeded = false;
			for (int x = 0; x < AREA_SIZE_X; x++)
			{
				for (int z = 0; z < AREA_SIZE_Z; z++)
				{
					for (int y = 0; y < AREA_SIZE_Y; y++)
					{
						if (Chunks[x, y, z].flag_dataPushNeeded)
						{
							pushNeeded = true;
							Chunks[x, y, z].flag_dataPushNeeded = false;
						}
					}
				}
			}

			if (pushNeeded)
			{
				ForceChunksToGpu();
			}
		}

		internal static void ForceChunksToGpu()
		{
			try
			{
				if (tbo == null)
				{
					tbo = new TextureBufferObject(1);
					tbo2 = new TextureBufferObject(2);
					ssbo = new ShaderStorageBufferObject(256 * 256 * 256 * 1);
				}

				GL.Uniform1(Assets.Shaders["raymarch"].GetParam("u_object_size"), TOTAL_CHUNKS);

				float[] arr = GetFloats();
				////test cube
				tbo.SetData(arr);

				tbo2.SetData(new float[] {2});

				tbo.Use(Assets.Shaders["raymarch"]);


			}
			catch (Exception ex)
			{
				Console.WriteLine(ex.ToString());
			}
		}

		internal static float[] GetFloats()
		{
			return Chunks[0, 0, 0].GetData();
		}
		internal static float[] GetFloats2()
		{
			return Chunks[0, 0, 0].GetData();
		}

		public static bool VoxelRaycast(Vector3 position, Vector3 direction, out VoxelHit hit)
		{
			VoxelHit vh = new VoxelHit(null, null, Vector3.zero, Vector3.zero, float.MaxValue);

			foreach(Chunk chunk in Chunks)
			{
				raycast(chunk.Octree);

				void raycast(Octree oct)
				{
					if (oct.IsLeaf)
					{
						calc(oct);
						return;
					}
					for (int i = 0; i < oct.leafs.Length; i++)
					{
						if (oct.leafs[i] != null)
							raycast(oct.leafs[i]);
					}
				}

				void calc(Octree oct)
				{
					if (oct.GetState(VoxelStateIndex.FillState) == false) return;
					Vector3 size = new Vector3(oct.NodeSize / 2);
					float dist = 0;
					if(_RayAABBIntersection(position, direction, oct.Position - size, oct.Position + size, out dist))
					{
						if(dist < vh.Distance)
						{
							vh.Distance = dist;
							vh.Leaf = oct;
							vh.HitPosition = position + (direction * dist);
							vh.Chunk = chunk;
						}
					}
				}
			}

			hit = vh;

			return vh.Chunk != null;
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
