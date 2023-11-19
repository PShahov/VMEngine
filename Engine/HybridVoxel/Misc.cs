using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace VMEngine.Engine.HybridVoxel
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

		public VoxelColor(byte r, byte g, byte b, byte a = 255)
		{
			Color = new byte[] { r, g, b, a };
		}
		public VoxelColor(uint hex = 0xff0000ff)
		{
			Color = BitConverter.GetBytes(hex);
		}
		public VoxelColor(int hex = 0xff0000)
		{
			Color = BitConverter.GetBytes(hex);
		}

		public static Color FloatToColor(float value)
		{
			byte[] bytes = BitConverter.GetBytes(value);
			return System.Drawing.Color.FromArgb(bytes[0], bytes[1], bytes[2], bytes[3]);
		}
		public static float ColorToFloat(Color value)
		{
			return new VoxelColor(value.A, value.R, value.G, value.B).ToFloat(true);
		}

		public float ToFloat(bool backwards = false)
		{
			if (backwards)
			{
				return BitConverter.ToSingle(new byte[] { Color[0], Color[1], Color[2], Color[3] });
			}
			else
			{
				return BitConverter.ToSingle(new byte[] { Color[3], Color[2], Color[1], Color[0] });
			}

		}
		public static float ToFloat(byte[] Color, bool backwards = false)
		{
			//a
			//b
			//g
			//r
			//return System.BitConverter.ToSingle(new byte[] { 0x00, 0x00, 0x00, 0xff });
			if (backwards)
			{
				return BitConverter.ToSingle(new byte[] { Color[0], Color[1], Color[2], Color[3] });
			}
			else
			{
				return BitConverter.ToSingle(new byte[] { Color[3], Color[2], Color[1], Color[0] });
			}
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

		internal void Invert()
		{
			for(int i = 0;i < 3; i++)
			{
				int v = Color[i];
				v = v * -1 + 255;
				Color[i] = (byte)v;
			}
		}
	}

	public enum VoxelStateIndex
	{
		FillState = 0,
		Fullfilled = 1,
		Surrounded = 2,
		Opacity = 3,
		Divided = 4,
	}

	public static class hvState
	{

		public static bool GetState(byte state, VoxelStateIndex index)
		{
			return (state & 1 << (int)index) != 0;
		}

		public static byte SetState(byte state, VoxelStateIndex index, bool value)
		{
			if (value)
				state = (byte)(state | 1 << (int)index);
			else
				state = (byte)(state & ~(1 << (int)index));

			return state;
		}

		public static byte GenerateState(params VoxelStateIndex[] indices)
		{
			byte state = 0;
			for(int i = 0;i < indices.Length;i++)
			{
				state = SetState(state, indices[i], true);
			}
			return state;
		}
	}
}
