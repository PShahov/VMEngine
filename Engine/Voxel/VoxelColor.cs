using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace VMEngine.Engine.Voxel
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
}
