using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace VMEngine.Engine.HybridVoxel
{
	public class Octree
	{

		public static Vector3[] DIAGONAL_DIRECTIONS = new Vector3[]
		{
			new Vector3(-1,1,-1), //left top far
			new Vector3(1,1,-1), //right top far
			new Vector3(1,1,1), //right top near
			new Vector3(-1,1,1), //left top near

			new Vector3(-1,-1,-1), //left bottom far
			new Vector3(1,-1,-1), // right bottom far
			new Vector3(1,-1,1), //right bottom near
			new Vector3(-1,-1,1), //left bottom near
		};

		public static int FloatsPerOctree = 5;
		public int Index = 0;
		public static float InitialSize = Chunk.CHUNK_EDGE;
		public byte State = 0;
		public VoxelColor Color;
		public Vector3 Position;

		public Octree[] leafs = null;

		public Octree Parent = null;


		public bool IsLeaf { get { return leafs == null; } }
		public bool IsRoot { get { return Index == 0; } }

		public float NodeSize
		{
			get
			{
				return GetSizeByIndex(this.Index);
			}
		}

		public int OctreeSize
		{
			get
			{
				int count = 1;
				calcChildCount(this);
				return count;

				void calcChildCount(Octree oct)
				{
					if (oct.IsLeaf) return;
					count += 8;
					for (int i = 0; i < oct.leafs.Length; i++)
					{
						if (oct.leafs[i] != null)
							calcChildCount(oct.leafs[i]);
					}
				}
			}
		}
		public int LowestIndex
		{
			get
			{
				int index = 0;
				calcChildCount(this);
				return index;

				void calcChildCount(Octree oct)
				{
					if (oct.Index > index) index = oct.Index;
					if (oct.IsLeaf) return;
					for (int i = 0; i < oct.leafs.Length; i++)
					{
						if (oct.leafs[i] != null)
							calcChildCount(oct.leafs[i]);
					}
				}
			}
		}
		public int LeafsCount
		{
			get
			{
				int count = 0;
				calcChildCount(this);
				return count;

				void calcChildCount(Octree oct)
				{
					if (oct.IsLeaf)
					{
						count++;
						return;
					}
					for (int i = 0; i < oct.leafs.Length; i++)
					{
						if (oct.leafs[i] != null)
							calcChildCount(oct.leafs[i]);
					}
				}
			}
		}

		public bool Surrounded
		{
			get
			{
				return GetState(VoxelStateIndex.Surrounded);
			}
			set
			{
				SetState(value, VoxelStateIndex.Surrounded);
			}
		}

		public Octree(int index,Vector3 position, VoxelColor color, byte state, Octree parent = null)
		{
			Index = index;
			Color = color;
			State = state;
			Position = position;
			Parent = parent;
		}

		public bool Divide()
		{
			if(IsLeaf == false)
				return false;

			leafs = new Octree[8];
			byte state = hvState.SetState(State, VoxelStateIndex.Divided, false);
			float size = GetSizeByIndex(Index + 2);
			for (int i = 0;i < leafs.Length;i++)
			{
				leafs[i] = new Octree(Index + 1, this.Position + (DIAGONAL_DIRECTIONS[i] * size), VoxelColor.Random(), state, this);
				
			}

			State = hvState.SetState(State, VoxelStateIndex.Divided, true);

			return true;
		}

		public void DivideLowestLeafs()
		{
			div(this);

			void div(Octree oct)
			{
				if (oct.leafs == null)
				{
					oct.Divide();
				}
				else
				{
					for (int i = 0; i < oct.leafs.Length; i++)
					{
						div(oct.leafs[i]);
					}
				}
			}
		}
		public void DivideFirstLowestLeafs()
		{
			div(this);

			void div(Octree oct)
			{
				if (oct.leafs == null)
				{
					oct.Divide();
				}
				else
				{
					div(oct.leafs[0]);
				}
			}
		}

		public bool Collapse(Octree refLeaf = null, bool forcedCollapse = false)
		{
			if(forcedCollapse == false || leafs != null)
			{
				forcedCollapse = true;
				for(int i = 0;i < leafs.Length;i++)
				{
					if (leafs[i].leafs != null)
					{
						forcedCollapse = false;
						break;
					}
				}
			}

			if (forcedCollapse || leafs == null)
			{
				if(refLeaf != null)
				{
					Color = refLeaf.Color;
					State = refLeaf.State;
				}

				State = hvState.SetState(State, VoxelStateIndex.Divided, false);
				leafs = null;
			}

			return forcedCollapse;

		}

		public float[] GetOctreeDataRecursively()
		{
			float[] data = new float[this.OctreeSize * Octree.FloatsPerOctree + 3];
			uint dtPointer = 3;

			recur(this);


			return data;

			void recur(Octree oct)
			{
				if (oct.IsLeaf)
				{
					data[dtPointer] = oct.Color.ToFloat();
					data[dtPointer + 1] = oct.GetOctreeData();
					dtPointer += 2;
				}
				else
				{
					int c = 0;
					try
					{
						c = oct.OctreeSize;
					}
					catch (NullReferenceException e)
					{
						Console.WriteLine(e.ToString());
					}
					data[dtPointer] = new VoxelColor(c).ToFloat(true);
					data[dtPointer + 1] = oct.GetOctreeData();
					dtPointer += 2;
					for (int i = 0; i < oct.leafs.Length; i++)
					{
						recur(oct.leafs[i]);
					}
				}

			}
		}


		public float[] GetLowestOctreeDataRecursively()
		{
			float[] data = new float[this.OctreeSize * Octree.FloatsPerOctree + 4];
			uint dtPointer = 4;

			recur(this);


			return data;

			void recur(Octree oct)
			{
				if (oct.IsLeaf)
				{
					if (oct.Surrounded == true) return;
					data[dtPointer] = oct.Color.ToFloat();
					data[dtPointer + 1] = oct.GetOctreeData();
					data[dtPointer + 2] = oct.Position.x;
					data[dtPointer + 3] = oct.Position.y;
					data[dtPointer + 4] = oct.Position.z;
					dtPointer += 5;
				}
				else
				{
					for (int i = 0; i < oct.leafs.Length; i++)
					{
						recur(oct.leafs[i]);
					}
				}

			}
		}

		protected float GetOctreeData()
		{
			return new VoxelColor(State, (byte)Index, IsLeaf ? (byte)255 : (byte)0, 0).ToFloat();
		}

		public static float GetSizeByIndex(int index = 0)
		{
			return InitialSize / (MathF.Pow(2, index));
		}
		public float GetSizeByIndex()
		{
			return InitialSize / (MathF.Pow(2, Index));
		}

		public void SetState(bool value, VoxelStateIndex index)
		{
			State = hvState.SetState(State, index, value);
		}
		public bool GetState(VoxelStateIndex index)
		{
			return hvState.GetState(State, index);
		}
	}
}
