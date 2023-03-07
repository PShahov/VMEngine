using OpenTK.Mathematics;
using System;
using System.Collections.Generic;
using System.Text;

namespace VMEngine
{
	public struct Vector3
	{
		public override string ToString()
		{
			return $"X: ~{this.x.ToString()}, Y: ~{this.y.ToString()}, Z: ~{this.z.ToString()}";
		}
		public string ToString(string param = "")
		{
			return $"X: ~{this.x.ToString(param)}, Y: ~{this.y.ToString(param)}, Z: ~{this.z.ToString(param)}";
		}
		public Vector2 vector2F
		{
			get
			{
				return new Vector2(x, y);
			}
		}
		public OpenTK.Mathematics.Vector3 vector3F
		{
			get
			{
				return new OpenTK.Mathematics.Vector3(x, y, z);
			}
		}
		public OpenTK.Mathematics.Vector3i vector3I
		{
			get
			{
				return new OpenTK.Mathematics.Vector3i((int)MathF.Round(x), (int)MathF.Round(y), (int)MathF.Round(z));
			}
		}

		public float[] ToArray()
		{
			float[] array = new float[3];
			array[0] = x;
			array[1] = y;
			array[2] = z;
			return array;
		}

		// *Undocumented*
		public const float kEpsilon = 0.00001F;
		// *Undocumented*
		public const float kEpsilonNormalSqrt = 1e-15F;

		public float x, y, z;

		public static Vector3 zero { get { return new Vector3(0, 0, 0); } }
		public static Vector3 one { get { return new Vector3(1, 1, 1); } }
		public static Vector3 up { get { return new Vector3(0, 1, 0); } }
		public static Vector3 down { get { return new Vector3(0, -1, 0); } }
		public static Vector3 right { get { return new Vector3(1, 0, 0); } }
		public static Vector3 left { get { return new Vector3(-1, 0, 0); } }
		public static Vector3 forward { get { return new Vector3(0, 0, 1); } }
		public static Vector3 back { get { return new Vector3(0, 0, -1); } }

		public Vector3(float x, float y, float z) { this.x = x; this.y = y; this.z = z; }
		public Vector3(float x, float y) { this.x = x; this.y = y; z = 0F; }

		public void Normalize()
		{
			float mag = Magnitude(this);
			this = this / mag;
		}

		public void ExcludeInfinity()
		{
			if (float.IsInfinity(this.x)) this.x = 0;
			if (float.IsInfinity(this.y)) this.y = 0;
			if (float.IsInfinity(this.z)) this.z = 0;
		}

		public static Vector3 Normalize(Vector3 v)
		{
			float mag = Magnitude(v);
			return v / mag;
		}
		public static float Dot(Vector3 v1, Vector3 v2)
		{
			return (v1.x * v2.x) + (v1.y * v2.y) + (v1.z * v2.z);
		}
		public Vector3 normalized { get { return Vector3.Normalize(this); } }
		public static float Magnitude(Vector3 vector) { return (float)Math.Sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z); }
		public float Magnitude() { return (float)Math.Sqrt(this.x * this.x + this.y * this.y + this.z * this.z); }
		public static float SqrMagnitude(Vector3 vector) { return vector.x * vector.x + vector.y * vector.y + vector.z * vector.z; }
		public float SqrMagnitude() { return this.x * this.x + this.y * this.y + this.z * this.z; }

		public static Vector3 Abs(Vector3 v)
		{
			return new Vector3(MathF.Abs(v.x), MathF.Abs(v.y), MathF.Abs(v.z));
		}
		public Vector3 abs
		{
			get
			{
				return new Vector3(MathF.Abs(this.x), MathF.Abs(this.y), MathF.Abs(this.z));
			}
		}

		public static Vector3 operator +(Vector3 a, Vector3 b) { return new Vector3(a.x + b.x, a.y + b.y, a.z + b.z); }
		public static Vector3 operator -(Vector3 a, Vector3 b) { return new Vector3(a.x - b.x, a.y - b.y, a.z - b.z); }
		public static Vector3 operator *(Vector3 a, Vector3 b) { return new Vector3(a.x * b.x, a.y * b.y, a.z * b.z); }
		public static Vector3 operator /(Vector3 a, Vector3 b) { return new Vector3(a.x / b.x, a.y / b.y, a.z / b.z); }
		public static Vector3 operator -(Vector3 a) { return new Vector3(-a.x, -a.y, -a.z); }
		public static Vector3 operator *(Vector3 a, float d) { return new Vector3(a.x * d, a.y * d, a.z * d); }
		public static Vector3 operator *(float d, Vector3 a) { return new Vector3(a.x * d, a.y * d, a.z * d); }
		public static Vector3 operator /(Vector3 a, float d) { return new Vector3(a.x / d, a.y / d, a.z / d); }

		public static Vector3 operator +(Vector3 a, Vector2 b) { return new Vector3(a.x + b.X, a.y + b.Y, a.z); }
		public static Vector3 operator -(Vector3 a, Vector2 b) { return new Vector3(a.x - b.X, a.y - b.Y, a.z); }

		public float GetComponent(int index)
		{
			switch (index)
			{
				case 0: return this.x;
				case 1: return this.y;
				case 2: return this.z;
			}
			return this.x;
		}

		public static Vector3 Min(Vector3 a, Vector3 b)
		{
			if (Dot(a, a) < Dot(b, b))
				return a;
			else
				return b;
		}
		public static Vector3 Max(Vector3 a, Vector3 b)
		{
			if (Dot(a,a) < Dot(b,b))
				return b;
			else
				return a;
		}
	}
}
