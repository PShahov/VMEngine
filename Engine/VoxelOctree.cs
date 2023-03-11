using Microsoft.Maui.Graphics;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using System.Text;
using System.Threading.Tasks;

namespace VMEngine.Voxel
{
	public struct VoxelColor
	{
		public byte[] Color;

		public byte R
		{
			get { return Color[0]; }
			set { Color[0] = value; }
		}
		public byte G
		{
			get { return Color[1]; }
			set { Color[1] = value; }
		}
		public byte B
		{
			get { return Color[2]; }
			set { Color[2] = value; }
		}
		public byte A
		{
			get { return Color[3]; }
			set { Color[3] = value; }
		}

		public VoxelColor(byte r, byte g, byte b, byte a = 1)
		{
			Color = new byte[] { r, g, b, a };
		}
		public VoxelColor(uint hex = 0xff0000ff)
		{
			Color = BitConverter.GetBytes(hex);
		}

		public float ToFloat()
		{
			//a
			//b
			//g
			//r
			//return System.BitConverter.ToSingle(new byte[] { 0x00, 0x00, 0x00, 0xff });
			return System.BitConverter.ToSingle(new byte[] { Color[3], Color[2], Color[1], Color[0] });
		}
		public static VoxelColor Random()
		{
			Random r = new Random();
			//uint hex = (uint)r.NextInt64(uint.MaxValue);
			VoxelColor v = new VoxelColor((byte)r.Next(256), (byte)r.Next(256), (byte)r.Next(256));
			//v = new VoxelColor(0, 255, 0, 255);
			return v;
		}
		public override string ToString()
		{
			return $"R: {R}, G: {G}, B: {B}, A:{A}";
		}
	}

	public enum VoxelStateIndex
	{
		FillState = 0,
		Fullfilled = 1,
		Surrounded = 2
	}

	public enum VoxelDiagonalDirections
	{
		LTF = 0,
		RTF = 1,
		RTN = 2,
		LTN = 3,
		LBF = 4,
		RBF = 5,
		RBN = 6,
		LBN = 7
	}

	public class VoxelOctree
	{
		public const uint DEFAULT_VOXEL_COLOR = 0x777777FF;
		public const byte MAX_SUB_LAYER = 8;
		public const float DEFAULT_EDGE_SIZE = 12.8f;
		public const float MIN_EDGE_SIZE = 0.1f;

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

		public static Vector3[] AXIS_DIRECTIONS = new Vector3[]
		{
			new Vector3(-1,0,0),//left
			new Vector3(1,0,0),//right

			new Vector3(0,1,0), //top
			new Vector3(0,-1,0), //bottom

			new Vector3(0,0,1), //near
			new Vector3(0,0,-1), //far
		};

		public byte Index = 1;
		public VoxelOctree[] SubVoxels = new VoxelOctree[8];
		public VoxelOctree ParentVoxel = null;
		public byte State = 0b00000011;
		public VoxelColor Color = new VoxelColor(DEFAULT_VOXEL_COLOR);
		public Vector3 Position = new Vector3();
		public float EdgeSize = DEFAULT_EDGE_SIZE;

		public uint VoxelMaterial = 0;
		public uint CollisionMask = 1;
		public uint VoxelBlockId = 1;

		public bool IsLeaf { get { return SubVoxels[0] != null; } }

		public bool CanDivide { get { return Index < MAX_SUB_LAYER; } }

		public VoxelOctree(Vector3 position, float edgeSize, VoxelColor color, byte index = 1, byte state = 0b00000011)
		{
			Position = position;
			EdgeSize = edgeSize;
			Color = color;
			Index = index;
			State = state;
		}
		public void Divide()
		{
			if(Index >= MAX_SUB_LAYER)
			{
				return;
			}
			if (SubVoxels[0] !=  null)
			{
				foreach(VoxelOctree vo in SubVoxels)
				{
					vo.Divide();
				}
				return;
			}
			float offset = EdgeSize / 4;
			float edge = EdgeSize / 2;
			byte index = (byte)(Index + 1);

			for(int i = 0;i < 8; i++)
			{
				SubVoxels[i] = new VoxelOctree(Position + (DIAGONAL_DIRECTIONS[i] * offset), edge, this.Color, index);
				SubVoxels[i].ParentVoxel= this;
				SubVoxels[i].CollisionMask = this.CollisionMask;
				SubVoxels[i].VoxelMaterial = this.VoxelMaterial;
				SubVoxels[i].VoxelBlockId = this.VoxelBlockId;
			}
		}


		//public VoxelOctree DivideAt(Vector3 pos, int div = 2)
		//{

		//}

		public bool IsPointInside(Vector3 pos)
		{
			Vector3 min = this.Position - (Vector3.one * 0.5f * this.EdgeSize);
			Vector3 max = this.Position + (Vector3.one * 0.5f * this.EdgeSize);

			//Check if the point is less than max and greater than min
			if (pos.x > min.x && pos.x < max.x &&
			pos.y > min.y && pos.y < max.y &&
			pos.z > min.z && pos.z < max.z)
			{
				return true;
			}

			//If not, then return false
			return false;
		}

		public bool IsPointInsideRecursive(Vector3 pos, out VoxelOctree vox)
		{
			VoxelOctree oct = this;
			while(oct.ParentVoxel != null) oct = oct.ParentVoxel;

			while (oct.SubVoxels[0] != null)
			{
				bool b = false;
				for(int i = 0;i < 8; i++)
				{
					if (oct.SubVoxels[i].IsPointInside(pos))
					{
						b = true;
						oct = oct.SubVoxels[i];
						break;
					}
				}
				if (!b)
				{
					vox = oct;
					return false;
				}
			}

			if (oct.IsPointInside(pos))
			{
				vox = oct;
				return true;
			}
			else
			{
				vox = oct;
				return false;
			}

		}



		public void CalcFullfilledState()
		{
			//if()
		}

		public void CalcArround()
		{

			//VoxelOctree root = this;
			//while(root.ParentVoxel != null) root = root.ParentVoxel;
			//VoxelOctree[] leafs = root.GetAllSubvoxels();

			//for(int i = 0;i < leafs.Length; i++)
			//{
			//	Vector3 pos = leafs[i].Position + (VoxelOctree.AXIS_DIRECTIONS[0] * (this.EdgeSize / 2 + MIN_EDGE_SIZE / 2));
			//	bool filled = false;
			//	for (int j = 0; j < leafs.Length; j++)
			//	{
			//		if (leafs[j].IsPointInside(pos))
			//		{
			//			filled = true;
			//			//leafs[i].SetState(VoxelStateIndex.Surrounded, true);
			//			break;
			//		}
			//	}
			//	leafs[i].Color = filled ? new VoxelColor(0, 255, 0) : new VoxelColor(255, 0, 0);
			//}


		}

		public VoxelOctree[] GetAllSubvoxels()
		{

			if (!GetState(0))
				return new VoxelOctree[0];

			List<VoxelOctree> list = new List<VoxelOctree>();

			digDown(this);


			void digDown(VoxelOctree oct)
			{
				if (oct.IsLeaf == false)
				{
					foreach (VoxelOctree sv in oct.SubVoxels)
					{
						digDown(sv);
					}
				}
				else
				{
					list.Add(oct);
				}
			}

			return list.ToArray();
		}

		public float[] ToArray()
		{

			if(!GetState(0))
				return new float[0];

			List<float> list = new List<float>();

			digDown(this);


			void digDown(VoxelOctree oct)
			{
				if (oct.SubVoxels[0] != null)
				{
					foreach(VoxelOctree sv in oct.SubVoxels)
					{
						digDown(sv);
					}
				}
				else
				{
					if(oct.GetState(VoxelStateIndex.FillState) && !oct.GetState(VoxelStateIndex.Surrounded))
						list.AddRange(new float[]{// 5 * 4 bytes
							oct.Position.x, oct.Position.y, oct.Position.z,
							oct.EdgeSize,
							oct.Color.ToFloat(),
						});
				}
			}

			return list.ToArray();
		}

		public void SetState(VoxelStateIndex pos, bool value)
		{
			SetState((int)pos, value);
		}
		public bool GetState(VoxelStateIndex pos)
		{
			return GetState((int)pos);
		}

		public void SetState(int pos, bool value)
		{
			if (value)
			{
				State = (byte)(State | (1 << pos));
			}
			else
			{
				State = (byte)(State & ~(1 << pos));
			}
		}
		public bool GetState(int pos)
		{
			return ((State & (1 << pos)) != 0);
		}
	}

}
