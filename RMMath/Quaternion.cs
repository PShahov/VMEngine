using System;
using System.Collections.Generic;
using System.Text;

namespace VMEngine
{
	public struct Quaternion
	{
		public float x;
		public float y;
		public float z;
		public float w;

		public static float EPSILON = 0.000001F;

		public override string ToString()
		{
			return $"X: ~{this.x.ToString()}, Y: ~{this.y.ToString()}, Z: ~{this.z.ToString()}, W: ~{this.w.ToString()}";
		}
		public Quaternion(float x, float y, float z, float w)
		{
			this.x = x;
			this.y = y;
			this.z = z;
			this.w = w;
		}

		public float[] ToArray()
		{
			float[] array = new float[4];
			array[0] = x;
			array[1] = y;
			array[2] = z;
			array[3] = w;
			return array;
		}

		public Vector3 forward
		{
			get
			{
				return new Vector3(
					2 * (x * z + w * y),
					2 * (y * z - w * x),
					1 - 2 * (x * x + y * y)
					).normalized;
			}
		}
			
		public Vector3 up
		{
			get
			{
				return new Vector3(
					2 * (x * y - w * z),
					1 - 2 * (x * x + z * z),
					2 * (y * z + w * x)
					).normalized;
			}
		}
		public Vector3 left
		{
			get
			{
				return (new Vector3(
					1 - 2 * (y * y + z * z),
					2 * (x * y + w * z),
					2 * (x * z - w * y)
					) * -1).normalized;
			}
		}
		public Vector3 backward { get { return this.forward * -1; } }
		public Vector3 down { get { return this.up * -1; } }
		public Vector3 right { get { return this.left * -1; } }
		/// <summary>
		///		Angles in radians
		/// </summary>
		/// <param name="roll">x-axis</param>
		/// <param name="pitch">y-axis</param>
		/// <param name="yaw">z-axis</param>
		public static Quaternion FromRadians(float roll, float pitch, float yaw)
		{

			float cr = MathF.Cos(roll * 0.5f);
			float sr = MathF.Sin(roll * 0.5f);
			float cp = MathF.Cos(pitch * 0.5f);
			float sp = MathF.Sin(pitch * 0.5f);
			float cy = MathF.Cos(yaw * 0.5f);
			float sy = MathF.Sin(yaw * 0.5f);

			Quaternion q;
			q.w = cr * cp * cy + sr * sp * sy;
			q.x = sr * cp * cy - cr * sp * sy;
			q.y = cr * sp * cy + sr * cp * sy;
			q.z = cr * cp * sy - sr * sp * cy;

			return q;

		}
		public static Quaternion FromRadians( Vector3 axis, float rads)
		{
			float factor = MathF.Sin(rads / 2.0f);

			Quaternion q;

			q.x = axis.x * factor;
			q.y = axis.y * factor;
			q.z = axis.z * factor;
			q.w = MathF.Cos(rads / 2.0f);

			return Quaternion.Normalize(q);
		}
		public static Quaternion FromEulers(float x, float y, float z)
		{
			return Quaternion.FromRadians(MathV.DegToRad(x), MathV.DegToRad(y), MathV.DegToRad(z));
		}
		public static Quaternion FromEulers(Vector3 axis, float angle)
		{
			return Quaternion.FromRadians(axis, MathV.DegToRad(angle));
		}
		public static Vector3 ToEuler(Quaternion q)
		{
			Vector3 angles;

			// x axis
			float sinr_cosp = 2 * (q.w * q.x + q.y * q.z);
			float cosr_cosp = 1 - 2 * (q.x * q.x + q.y * q.y);
			angles.x = MathF.Atan2(sinr_cosp, cosr_cosp);

			//y axis
			float sinp = 2 * (q.w * q.y - q.z * q.x);
			if (MathF.Abs(sinp) >= 1)
				angles.y = MathF.CopySign(MathF.PI / 2, sinp);
			else
				angles.y = MathF.Asin(sinp);

			// z axis
			float siny_cosp = 2 * (q.w * q.z + q.x * q.y);
			float cosy_cosp = 1 - 2 * (q.y * q.y + q.z * q.z);
			angles.z = MathF.Atan2(siny_cosp, cosy_cosp);



			return new Vector3(MathV.RadToDeg(angles.x), MathV.RadToDeg(angles.y), MathV.RadToDeg(angles.z));
		}

		public static float Dot(Quaternion a, Quaternion b)
		{
			return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;
		}
		public static Quaternion Invert(Quaternion q)
		{
			Quaternion nq = new Quaternion(-q.x, -q.y, -q.z, q.w);
			return Quaternion.Normalize(nq);
		}
		public Quaternion inverted
		{
			get
			{
				return Quaternion.Invert(this);
			}
		}
		public void RotateEulers(Vector3 axis, float angle)
		{
			Quaternion q = FromEulers(axis, angle) * this;
			this.x= q.x;
			this.y= q.y;
			this.z= q.z;
			this.w= q.w;
			//this *= Quaternion.FromEulers(axis, angle);
		}
		public void RotateRadians(Vector3 axis, float angle)
		{
			this *= Quaternion.FromRadians(axis, angle);
		}
		public static Quaternion identity { get { return new Quaternion(0, 0, 0, 1); } }
		public static Quaternion Normalize(Quaternion q)
		{
			float mag = MathF.Sqrt(Dot(q, q));

			if (mag < Quaternion.EPSILON)
				return Quaternion.identity;

			return new Quaternion(q.x / mag, q.y / mag, q.z / mag, q.w / mag);
		}

		public static Quaternion operator *(Quaternion a, Quaternion b)
		{
			return new Quaternion(
				a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
				a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
				a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
				a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z
				);
		}
		//public static Quaternion operator *(Quaternion a, Vector3 b)
		//{
		//	return new Quaternion(
		//		a.w * b.x + a.y * b.z - a.z * b.y,
		//		a.w * b.y - a.x * b.z + a.z * b.x,
		//		a.w * b.z + a.x * b.y - a.y * b.x,
		//		-a.x * b.x - a.y * b.y - a.z * b.z
		//		);
		//}
		public static Quaternion operator +(Quaternion a, Quaternion b)
		{
			return Quaternion.Normalize(new Quaternion(
				a.x + b.x,
				a.y + b.y,
				a.z + b.z,
				a.w + b.w
				));
		}
		public static Quaternion operator -(Quaternion a, Quaternion b)
		{
			return Quaternion.Normalize(new Quaternion(
				a.x - b.x,
				a.y - b.y,
				a.z - b.z,
				a.w - b.w
				));
		}

		public static Vector3 operator *(Quaternion rotation, Vector3 point)
		{
			float x = rotation.x * 2F;
			float y = rotation.y * 2F;
			float z = rotation.z * 2F;
			float xx = rotation.x * x;
			float yy = rotation.y * y;
			float zz = rotation.z * z;
			float xy = rotation.x * y;
			float xz = rotation.x * z;
			float yz = rotation.y * z;
			float wx = rotation.w * x;
			float wy = rotation.w * y;
			float wz = rotation.w * z;

			Vector3 res;
			res.x = (1F - (yy + zz)) * point.x + (xy - wz) * point.y + (xz + wy) * point.z;
			res.y = (xy + wz) * point.x + (1F - (xx + zz)) * point.y + (yz - wx) * point.z;
			res.z = (xz - wy) * point.x + (yz + wx) * point.y + (1F - (xx + yy)) * point.z;
			return res;
		}
	}
}
