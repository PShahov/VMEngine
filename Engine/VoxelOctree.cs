using Microsoft.Maui.Graphics;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using System.Text;
using System.Threading.Tasks;

namespace VMEngine.Engine
{
	struct VoxelColor
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
			return System.BitConverter.ToSingle(Color);
		}
		public static VoxelColor Random()
		{
			Random r = new Random();
			uint hex = (uint)r.NextInt64(uint.MaxValue);
			VoxelColor v = new VoxelColor(hex);
			return v;
		}
		public override string ToString()
		{
			return $"R: {R}, G: {G}, B: {B}, A:{A}";
		}
	}

	class VoxelOctree
	{
		public const uint DEFAULT_VOXEL_COLOR = 0x777777FF;
		public const byte MAX_SUB_LAYER = 5;
		public const float DEFAULT_EDGE_SIZE = 10;

		public static Vector3[] DIAGONAL_DIRECTIONS = new Vector3[]
		{
			new Vector3(-1,1,-1),
			new Vector3(1,1,-1),
			new Vector3(1,1,1),
			new Vector3(-1,1,1),

			new Vector3(-1,-1,-1),
			new Vector3(1,-1,-1),
			new Vector3(1,-1,1),
			new Vector3(-1,-1,1),
		};

		public byte Index = 1;
		public VoxelOctree[] SubVoxels = new VoxelOctree[8];
		public VoxelOctree ParentVoxel = null;
		public byte State = 0b0001;
		public VoxelColor Color = new VoxelColor(DEFAULT_VOXEL_COLOR);
		public Vector3 Position = new Vector3();
		public float EdgeSize = DEFAULT_EDGE_SIZE;

		public VoxelOctree(Vector3 position, float edgeSize, VoxelColor color, byte index = 1, byte state = 0b0001)
		{
			Position = position;
			EdgeSize = edgeSize;
			Color = color;
			Index = index;
			State = state;
		}
		public void Divide()
		{
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
				SubVoxels[i] = new VoxelOctree(Position + (DIAGONAL_DIRECTIONS[i] * offset), edge, VoxelColor.Random(), index);
				SubVoxels[i].ParentVoxel= this;
			}
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
					list.AddRange(new float[]{// 5 * 4 bytes
						oct.Position.x, oct.Position.y, oct.Position.z,
						oct.EdgeSize,
						oct.Color.ToFloat(),
					});
				}
			}

			return list.ToArray();
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
