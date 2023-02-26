using System;
using System.Collections.Generic;
using System.Text;

namespace VMEngine
{
	public struct bColor
	{
		public byte a;
		public byte r;
		public byte g;
		public byte b;

		public fColor fColor { get { return new fColor(255 / r, 255 / g, 255 / b, 255 / a); } }
		public bColor(byte r, byte g, byte b, byte a)
		{
			this.a = a;
			this.r = r;
			this.g = g;
			this.b = b;
		}
	}
	public struct fColor
	{
		public static fColor Red { get { return new fColor(1, 0, 0, 1); } }
		public static fColor Green { get { return new fColor(0, 1, 0, 1); } }
		public static fColor Blue { get { return new fColor(0, 0, 1, 1); } }
		public static fColor Black { get { return new fColor(0, 0, 0, 1); } }
		public static fColor White { get { return new fColor(1, 1, 1, 1); } }

		public float a;
		public float r;
		public float g;
		public float b;

		public bColor bColor { get { return new bColor((byte)(255 * r), (byte)(255 * g), (byte)(255 * b), (byte)(255 * a)); } }
		public fColor(float r, float g, float b, float a)
		{
			this.a = a;
			this.r = r;
			this.g = g;
			this.b = b;
		}

	}
}
