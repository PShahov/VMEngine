using OpenTK.Graphics.OpenGL;
using OpenTK.Mathematics;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using static System.Formats.Asn1.AsnWriter;

namespace VMEngine.Engine.DenseVoxel
{
	public class Chunk
	{
		public bool flag_regenMesh = false;
		public bool flag_recalсState = false;
		//public bool flagUpdate = false;
		private float _lastRegenMesh = 0;
		private float _lastRecalcState = 0;

		public static float UpdateFreq = 0.05f;
		

		//public static int CHUNK_SIZE_X = 16;
		//public static int CHUNK_SIZE_Y = 64;
		//public static int CHUNK_SIZE_Z = 16;
		public static int CHUNK_EDGE = 2;

		public static int DENSITY = 10;

		public static int VOXEL_PER_ROW = CHUNK_EDGE * DENSITY;

		public static float VOXEL_SIZE = 0.1f;

		public int _vertexArray;

		public static int CHUNK_TOTAL_BLOCK { get { return CHUNK_EDGE * CHUNK_EDGE * CHUNK_EDGE * (DENSITY * DENSITY * DENSITY); } }
		public static int CHUNK_TOTAL_FLOATS { get { return CHUNK_TOTAL_BLOCK * Voxel.FloatCount + 3; } }

		public Voxel[,,] Voxels;
		public Vector3 position = Vector3.zero;
		public int DataOffset = 0;

		public Chunk(Vector3 position, int dataOffset = 0)
		{
			this.position = position/* + Vector3.half * VOXEL_SIZE*/;
			this.DataOffset = dataOffset;
			int side = CHUNK_EDGE * DENSITY;
			Voxels = new Voxel[side,side,side];
			for (int x = 0; x < side; x++)
			{
				for (int y = 0; y < side; y++)
				{
					for (int z = 0; z < side; z++)
					{
						byte state = 0;
						//state = (byte)((x + y + z) % 3);

						if (x == 0 || y == 0 || z == 0 || x == side - 1 || y == side - 1 || z == side - 1)
							state = Voxel.CreateState(VoxelState.Fullfilled, VoxelState.Filled);
						else
							state = Voxel.CreateState(VoxelState.Fullfilled, VoxelState.Filled, VoxelState.Surrounded);

						float f = 0.5f;
						Voxels[x, y, z] = new Voxel(new float[] { f, f, f, 1 }, 1, state);
					}
				}
			}

			//Voxels[0, 0, 0].CurrentColor[0] = 1;

			RegenMesh();
		}

		public void Tick()
		{
			if (flag_regenMesh)
			{
				if (Time.alive > _lastRegenMesh + UpdateFreq)
				{
					RecalcState();
					//RegenMesh();

					try
					{
						float[] arr = this.GetFloats();
						int l = arr.Length;
						////test cube
						GL.Uniform1(Assets.Shaders["raymarch"].GetParam("u_object_size"), l / 5);
						//Program.vm.tbo.SetSubData(arr, DataOffset);

						//Program.vm.tbo.Use(Assets.Shaders["raymarch"]);
						flag_regenMesh = false;

					}
					catch (Exception ex)
					{
						Console.WriteLine(ex.ToString());
					}

				}
			}
			if (flag_recalсState)
			{
				if (Time.alive > _lastRecalcState + UpdateFreq)
				{
					RecalcState();
				}
			}
		}


		public Voxel GetVoxelAtPosition(Vector3 pos)
		{
			if (this.IsPointInside(pos) == false) return null;

			float half = (float)CHUNK_EDGE / 2f;
			int side = CHUNK_EDGE * DENSITY;
			pos -= position;
			pos -= Vector3.one * half;

			pos /= VOXEL_SIZE;

			pos *= -1;

			pos = pos - (Vector3.one * side);
			pos *= -1;

			Vector3i ind = new Vector3i(
				(int)MathF.Floor(pos.x),
				(int)MathF.Floor(pos.y),
				(int)MathF.Floor(pos.z)
			);

			if (ind.X >= VOXEL_PER_ROW) ind.X = VOXEL_PER_ROW - 1;
			if (ind.Y >= VOXEL_PER_ROW) ind.Y = VOXEL_PER_ROW - 1;
			if (ind.Z >= VOXEL_PER_ROW) ind.Z = VOXEL_PER_ROW - 1;


			if(Voxels[ind.X, ind.Y, ind.Z].Filled)
				return Voxels[ind.X, ind.Y, ind.Z];
			else
				return null;
		}

		private Vector3i PosToInd(Vector3 pos)
		{

			float half = (float)CHUNK_EDGE / 2f;
			int side = CHUNK_EDGE * DENSITY;
			pos -= position;
			pos -= Vector3.one * half;

			pos /= 0.1f;

			pos *= -1;

			pos = pos - (Vector3.one * side);
			pos *= -1;

			Vector3i ind = new Vector3i(
				(int)MathF.Floor(pos.x),
				(int)MathF.Floor(pos.y),
				(int)MathF.Floor(pos.z)
			);

			if (ind.X >= VOXEL_PER_ROW) ind.X = VOXEL_PER_ROW - 1;
			if (ind.Y >= VOXEL_PER_ROW) ind.Y = VOXEL_PER_ROW - 1;
			if (ind.Z >= VOXEL_PER_ROW) ind.Z = VOXEL_PER_ROW - 1;
			if (ind.X < 0) ind.X = 0;
			if (ind.Y < 0) ind.Y = 0;
			if (ind.Z < 0) ind.Z = 0;

			return ind;
		}


		public Voxel[] GetVoxelsInRadius(Vector3 pos, int radius)
		{
			List<Voxel> v = new List<Voxel>();

			Vector3i p = PosToInd(pos);

			Vector3i pMin = p - new Vector3i(radius, radius, radius);
			Vector3i pMax = p + new Vector3i(radius, radius, radius);

			if (pMin.X < 0) pMin.X = 0;
			if (pMin.Y < 0) pMin.Y = 0;
			if (pMin.Z < 0) pMin.Z = 0;

			if (pMax.X >= VOXEL_PER_ROW) pMax.X = VOXEL_PER_ROW - 1;
			if (pMax.Y >= VOXEL_PER_ROW) pMax.Y = VOXEL_PER_ROW - 1;
			if (pMax.Z >= VOXEL_PER_ROW) pMax.Z = VOXEL_PER_ROW - 1;

			for (int x = pMin.X; x <= pMax.X; x += 1)
			{
				for (int y = pMin.Y; y <= pMax.Y; y += 1)
				{
					for (int z = pMin.Z; z <= pMax.Z; z += 1)
					{
						if (new Vector3(p.X - x, p.Y - y, p.Z - z).SqrMagnitude() <= radius * radius)
							v.Add(Voxels[x, y, z]);
					}
				}
			}



			return v.ToArray();
		}

		public Vector3 NearestVoxelCenter(Vector3 pos)
		{
			if (this.IsPointInside(pos) == false) return Vector3.zero;

			float half = (float)CHUNK_EDGE / 2f;
			int side = CHUNK_EDGE * DENSITY;
			pos -= position;
			pos -= Vector3.one * half;



			return pos;

		}

		public bool IsPointInside(Vector3 pos, bool relative = false)
		{
			if(!relative)
				pos -= position;

			float half = (float)CHUNK_EDGE / 2f;

			return pos.x <= half && pos.x >= -half && pos.y <= half && pos.y >= -half && pos.z <= half && pos.z >= -half;
		}

		public Voxel GetVoxelByRay(Vector3 ro, Vector3 rd)
		{
			float f = 0;
			if (ChunkController._RayAABBIntersection(ro, rd, position - Vector3.half * -CHUNK_EDGE, position + Vector3.half * -CHUNK_EDGE, out f) == false)
				return null;

			//ro -= position;

			rd.Normalize();

			ro += rd * f;

			Voxel v = null;
			do
			{
				v = GetVoxelAtPosition(ro);
				Vector3 vc = NearestVoxelCenter(ro);
				if (v == null)
				{
					//float d = (ro - vc).Abs().Min() + 0.00001f;
					float d = 0.005f;
					ro += rd * d;
				}
			}
			while (IsPointInside(ro) && v == null);

			return v;
		}
		public Vector3 RayVoxelPosition(Vector3 ro, Vector3 rd)
		{
			float f = 0;
			if (ChunkController._RayAABBIntersection(ro, rd, position - Vector3.half * -CHUNK_EDGE, position + Vector3.half * -CHUNK_EDGE, out f) == false)
				return Vector3.zero;

			//ro -= position;

			rd.Normalize();

			ro += rd * f;

			Voxel v = null;
			do
			{
				v = GetVoxelAtPosition(ro);
				Vector3 vc = NearestVoxelCenter(ro);
				if (v == null)
				{
					//float d = (ro - vc).Abs().Min() + 0.00001f;
					float d = 0.005f;
					ro += rd * d;
				}
			}
			while (IsPointInside(ro) && v == null);

			return ro;
		}

		public void RecalcState()
		{
			int side = CHUNK_EDGE * DENSITY;

			for (int x = 0; x < side; x++)
			{
				for (int y = 0; y < side; y++)
				{
					for (int z = 0; z < side; z++)
					{
						if (x == 0 || y == 0 || z == 0 || x == side - 1 || y == side - 1 || z == side - 1)
						{
							Voxels[x, y, z].Surrounded = false;
						}
						else
						{
							int s = 0;
							s += Voxels[x - 1, y, z].Filled && Voxels[x - 1, y, z].Fullfilled ? 1 : 0;
							s += Voxels[x + 1, y, z].Filled && Voxels[x - 1, y, z].Fullfilled ? 1 : 0;
							s += Voxels[x, y - 1, z].Filled && Voxels[x - 1, y, z].Fullfilled ? 1 : 0;
							s += Voxels[x, y + 1, z].Filled && Voxels[x - 1, y, z].Fullfilled ? 1 : 0;
							s += Voxels[x, y, z - 1].Filled && Voxels[x - 1, y, z].Fullfilled ? 1 : 0;
							s += Voxels[x, y, z + 1].Filled && Voxels[x - 1, y, z].Fullfilled ? 1 : 0;
							if (s != 6)
							{
								Voxels[x, y, z].Surrounded = false;
							}
							else
							{
								Voxels[x, y, z].Surrounded = true;
							}
						}
					}
				}
			}

			_lastRecalcState = Time.alive;
			flag_recalсState = false;
		}
		public void RegenMesh()
		{
			_lastRegenMesh = Time.alive;
			flag_regenMesh = true;

		}

		public void Draw()
		{
			//if (flag_regenMesh || flag_recalсState)
			//{
			//	return;
			//}
		}

		public void Unbind()
		{
			GL.DeleteVertexArrays(1, ref _vertexArray);
		}

		//public float[] ToFloatArray()
		//{
		//	float[] ret = new float[CHUNK_SIZE_X * CHUNK_SIZE_Y * CHUNK_SIZE_Z * 1000];
		//	return ret;
		//}

		public void CalcArround()
		{

		}

		public float[] GetFloats()
		{
			int side = CHUNK_EDGE * DENSITY;
			float[] floats = new float[Chunk.CHUNK_TOTAL_FLOATS];
			int i = 3;
			floats[0] = this.position.x;
			floats[1] = this.position.y;
			floats[2] = this.position.z;
			for (int x = 0; x < side; x++)
			{
				for (int y = 0; y < side; y++)
				{
					for (int z = 0; z < side; z++)
					{
						floats[i] = Voxels[x, y, z].CurrentColor[0];
						floats[i + 1] = Voxels[x, y, z].CurrentColor[1];
						floats[i + 2] = Voxels[x, y, z].CurrentColor[2];
						floats[i + 3] = Voxels[x, y, z].CurrentColor[3];
						floats[i + 4] = new VoxelColor(Voxels[x, y, z].State, 0, 0, 0).ToFloat();
						i += 5;
					}
				}
			}

			return floats;
		}
	}
}
