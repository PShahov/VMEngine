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

		public static float UpdateFreq = 0.1f;
		

		private VertexBufferObject vbo;

		//public static int CHUNK_SIZE_X = 16;
		//public static int CHUNK_SIZE_Y = 64;
		//public static int CHUNK_SIZE_Z = 16;
		public static int CHUNK_EDGE = 5;

		public static int DENSITY = 10;

		public int _vertexArray;

		public static int CHUNK_TOTAL_BLOCK { get { return CHUNK_EDGE * CHUNK_EDGE * CHUNK_EDGE * (DENSITY * DENSITY * DENSITY); } }

		public Voxel[,,] Voxels;
		public Vector3 position = Vector3.zero;

		public Chunk(Vector3 position)
		{
			this.position = position;
			int side = CHUNK_EDGE * DENSITY;
			Voxels = new Voxel[side,side,side];
			for (int x = 0; x < side; x++)
			{
				for (int y = 0; y < side; y++)
				{
					for (int z = 0; z < side; z++)
					{
						byte state = 0;
						if(x == 0 || y == 0 || z == 0 || x == side - 1 || y == side - 1 || z == side - 1)
							state = Voxel.CreateState(VoxelState.Fullfilled, VoxelState.Filled);
						else
							state = Voxel.CreateState(VoxelState.Fullfilled, VoxelState.Filled, VoxelState.Surrounded);

						float f = 0.5f;
						Voxels[x, y, z] = new Voxel(new float[] { f, f, f, 1 }, 1, state);
					}
				}
			}



			Vertex[] vertices = new Vertex[]
			{
				new Vertex(new Vector3(1f, 1f, 1f) + position, new Color4(1,0,0,0.1f), Vector3.zero),//0
				new Vertex(new Vector3(-1f, 1f, 1f) + position, new Color4(0,1,0,0.1f), Vector3.zero),//1
				new Vertex(new Vector3(-1f, -1f, 1f) + position, new Color4(0,0,1,0.1f), Vector3.zero),//2
				new Vertex(new Vector3(1f, -1f, 1f) + position, new Color4(1,1,1,0.1f), Vector3.zero),//3
				
				new Vertex(new Vector3(1f, 1f, -1f) + position, new Color4(1,0,0,0.1f), Vector3.zero),//0
				new Vertex(new Vector3(-1f, 1f, -1f) + position, new Color4(0,1,0,0.1f), Vector3.zero),//1
				new Vertex(new Vector3(-1f, -1f, -1f) + position, new Color4(0,0,1,0.1f), Vector3.zero),//2
				new Vertex(new Vector3(1f, -1f, -1f) + position, new Color4(1,1,1,0.1f), Vector3.zero),//3
			};

			int[] indices = new int[]
			{
				0,1,2, //back
				2,3,0,

				4,7,6, //face
				6,5,4,

				0,3,7, //left
				7,4,0,

				//5,6,2, //right
				//2,1,5,

				//0,4,5, //top
				//5,1,0,

				7,3,2, //bottom
				2,6,7,
			};



			//vbo = new VertexBufferObject(Vertex.Info, vertices.Length);
			vbo = new VertexBufferObject(Vertex.Info, CHUNK_TOTAL_BLOCK, BufferUsageHint.DynamicDraw);
			vbo.SetData(vertices, vertices.Length);
			vbo.PrimitiveType = PrimitiveType.Triangles;

			vbo.SetIndices(indices, indices.Length);


			GL.BindBuffer(BufferTarget.ArrayBuffer, vbo.VertexBufferHandle);



			_vertexArray = GL.GenVertexArray();
			GL.BindVertexArray(_vertexArray);


			int vertexSize = vbo.VertexInfo.size;
			//vertices & color
			for (int i = 0; i < Vertex.Info.attributes.Length; i++)
			{
				GL.VertexAttribPointer(
					Vertex.Info.attributes[i].index,
					Vertex.Info.attributes[i].count,
					VertexAttribPointerType.Float,
					false,
					vertexSize,
					//vertices.Length * Vertex.Info.size,
					Vertex.Info.attributes[i].offset
					);
				GL.EnableVertexAttribArray(Vertex.Info.attributes[i].index);
			}

			GL.BindVertexArray(0);

			RegenMesh();
		}

		public void Tick()
		{
			if (flag_regenMesh)
			{
				if (Time.alive > _lastRegenMesh + UpdateFreq)
				{
					RecalcState();
					RegenMesh();
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

			pos /= 0.1f;

			pos *= -1;

			pos = pos - (Vector3.one * side);
			pos *= -1;

			Vector3i ind = new Vector3i(
				(int)MathF.Round(pos.x),
				(int)MathF.Round(pos.y),
				(int)MathF.Round(pos.z)
			);

			if (ind.X >= 50) ind.X = 49;
			if (ind.Y >= 50) ind.Y = 49;
			if (ind.Z >= 50) ind.Z = 49;

			//ind = ind - new Vector3i(50, 50, 50);
			//ind *= -1;

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
				(int)MathF.Round(pos.x),
				(int)MathF.Round(pos.y),
				(int)MathF.Round(pos.z)
			);

			if (ind.X >= 50) ind.X = 49;
			if (ind.Y >= 50) ind.Y = 49;
			if (ind.Z >= 50) ind.Z = 49;
			if (ind.X < 0) ind.X = 0;
			if (ind.Y < 0) ind.Y = 0;
			if (ind.Z < 0) ind.Z = 0;

			return ind;
		}

		public Voxel[] GetVoxelsInRadius(Vector3 pos, int radius)
		{
			List<Voxel> v = new List<Voxel>();

			Vector3i p = PosToInd(pos);

			//Vector3i pMin = PosToInd(pos - Vector3.one * radius);
			//Vector3i pMax = PosToInd(pos + Vector3.one * radius);

			//for (int x = pMin.X; x < pMax.X; x += 1)
			//{
			//	for (int y = pMin.Y; y < pMax.Y; y += 1)
			//	{
			//		for (int z = pMin.Z; z < pMax.Z; z += 1)
			//		{
			//			v.Add(Voxels[x, y, z]);
			//		}
			//	}
			//}


			Vector3 pMin = pos - Vector3.one * radius;
			Vector3 pMax = pos + Vector3.one * radius;

			for (float x = pMin.x; x < pMax.x; x += 0.1f)
			{
				for (float y = pMin.y; y < pMax.y; y += 0.1f)
				{
					for (float z = pMin.z; z < pMax.z; z += 0.1f)
					{
						Voxel vp = GetVoxelAtPosition(pos + new Vector3(x, y, z));
						if(vp != null)
							v.Add(vp);
						//v.Add(Voxels[x, y, z]);
					}
				}
			}


			return new Voxel[] { Voxels[p.X, p.Y, p.Z] };

			return v.ToArray();
		}

		public Vector3 NearestVoxelCenter(Vector3 pos)
		{
			if (this.IsPointInside(pos) == false) return Vector3.zero;

			float half = (float)CHUNK_EDGE / 2f;
			int side = CHUNK_EDGE * DENSITY;
			pos -= position;
			pos -= Vector3.one * half;


			Console.WriteLine(pos.ToString());

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



			return null;
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
			int voxelsCount = 0;
			int side = CHUNK_EDGE * DENSITY;

			int scale = 1;

			for (int x = 0; x < side; x+= scale)
			{
				for (int y = 0; y < side; y += scale)
				{
					for (int z = 0; z < side; z += scale)
					{
						if (Voxels[x, y, z].GetState(VoxelState.Filled) && !Voxels[x, y, z].GetState(VoxelState.Surrounded))
						{
							voxelsCount++;
						}
					}
				}
			}

			//voxelsCount = 1;
			Vector3 startFrom = position - (Vector3.one * 0.5f * CHUNK_EDGE) + (Vector3.one * 0.05f);


			Vertex[] vertices = new Vertex[voxelsCount * 8];
			int[] indices = new int[voxelsCount * 36];

			int _offset = 0;

			for (int x = 0; x < side; x += scale)
			{
				for (int y = 0; y < side; y += scale)
				{
					for (int z = 0; z < side; z += scale)
					{
						if (Voxels[x, y, z].GetState(VoxelState.Filled) && !Voxels[x, y, z].GetState(VoxelState.Surrounded))
						{
							addCube(_offset, startFrom + new Vector3(x * 0.1f, y * 0.1f, z * 0.1f), Voxels[x, y, z], scale);
							//addCube(_offset, position, Voxels[x, y, z]);
							_offset++;
						}
					}
				}
			}


			vbo.SetData(vertices, vertices.Length);
			vbo.SetIndices(indices, indices.Length);


			_lastRegenMesh = Time.alive;
			flag_regenMesh = false;

			//vbo.VertexCount = vertices.Length;
			//vbo.IndicesCount = vertices.Length;

			void addCube(int offset, Vector3 pos, Voxel voxel, int scale)
			{
				Color4 color = new Color4(voxel.CurrentColor[0], voxel.CurrentColor[1], voxel.CurrentColor[2], voxel.CurrentColor[3]);
				
				//new Vector3(0.5773502691896258f, 0.5773502691896258f, 0.5773502691896258f));
				
				vertices[offset * 8 + 0] = new Vertex(
					new Vector3(0.05f, 0.05f, 0.05f) * scale + pos,
					color,
					new Vector3(1, 1, 1));

				vertices[offset * 8 + 1] = new Vertex(new Vector3(-0.05f, 0.05f, 0.05f) * scale + pos,
					color,
					new Vector3(-1, 1, 1));

				vertices[offset * 8 + 2] = new Vertex(new Vector3(-0.05f, -0.05f, 0.05f) * scale + pos,
					color,
					new Vector3(-1, -1, 1));

				vertices[offset * 8 + 3] = new Vertex(new Vector3(0.05f, -0.05f, 0.05f) * scale + pos,
					color,
					new Vector3(1, -1, 1));


				vertices[offset * 8 + 4] = new Vertex(new Vector3(0.05f, 0.05f, -0.05f) * scale + pos,
					color,
					new Vector3(1, 1, -1));

				vertices[offset * 8 + 5] = new Vertex(new Vector3(-0.05f, 0.05f, -0.05f) * scale + pos,
					color,
					new Vector3(-1, 1, -1));

				vertices[offset * 8 + 6] = new Vertex(new Vector3(-0.05f, -0.05f, -0.05f) * scale + pos,
					color,
					new Vector3(-1, -1, -1));

				vertices[offset * 8 + 7] = new Vertex(new Vector3(0.05f, -0.05f, -0.05f) * scale + pos,
					color,
					new Vector3(1, -1, -1));


				indices[offset * 36 + 0] = offset * 8 + 0;
				indices[offset * 36 + 1] = offset * 8 + 1;
				indices[offset * 36 + 2] = offset * 8 + 2;

				indices[offset * 36 + 3] = offset * 8 + 2;
				indices[offset * 36 + 4] = offset * 8 + 3;
				indices[offset * 36 + 5] = offset * 8 + 0;


				indices[offset * 36 + 6] = offset * 8 + 4;
				indices[offset * 36 + 7] = offset * 8 + 7;
				indices[offset * 36 + 8] = offset * 8 + 6;

				indices[offset * 36 + 9] = offset * 8 + 6;
				indices[offset * 36 + 10] = offset * 8 + 5;
				indices[offset * 36 + 11] = offset * 8 + 4;


				indices[offset * 36 + 12] = offset * 8 + 0;
				indices[offset * 36 + 13] = offset * 8 + 3;
				indices[offset * 36 + 14] = offset * 8 + 7;

				indices[offset * 36 + 15] = offset * 8 + 7;
				indices[offset * 36 + 16] = offset * 8 + 4;
				indices[offset * 36 + 17] = offset * 8 + 0;


				indices[offset * 36 + 18] = offset * 8 + 5;
				indices[offset * 36 + 19] = offset * 8 + 6;
				indices[offset * 36 + 20] = offset * 8 + 2;

				indices[offset * 36 + 21] = offset * 8 + 2;
				indices[offset * 36 + 22] = offset * 8 + 1;
				indices[offset * 36 + 23] = offset * 8 + 5;


				indices[offset * 36 + 24] = offset * 8 + 0;
				indices[offset * 36 + 25] = offset * 8 + 4;
				indices[offset * 36 + 26] = offset * 8 + 5;

				indices[offset * 36 + 27] = offset * 8 + 5;
				indices[offset * 36 + 28] = offset * 8 + 1;
				indices[offset * 36 + 29] = offset * 8 + 0;


				indices[offset * 36 + 30] = offset * 8 + 7;
				indices[offset * 36 + 31] = offset * 8 + 3;
				indices[offset * 36 + 32] = offset * 8 + 2;

				indices[offset * 36 + 33] = offset * 8 + 2;
				indices[offset * 36 + 34] = offset * 8 + 6;
				indices[offset * 36 + 35] = offset * 8 + 7;
			}


		}

		public void Draw()
		{
			//if (flag_regenMesh || flag_recalсState)
			//{
			//	return;
			//}
			GL.BindVertexArray(_vertexArray);
			GL.BindBuffer(BufferTarget.ElementArrayBuffer, vbo.IndexBufferHandle);

			GL.DrawElements(vbo.PrimitiveType, vbo.IndicesCount, DrawElementsType.UnsignedInt, IntPtr.Zero);
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
	}
}
