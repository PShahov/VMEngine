using System;
using System.Collections.Generic;
using System.Text;

namespace VMEngine
{
	public static class MathV
	{
		public static float RadToDeg(float rad)
		{
			return rad * 180 / MathF.PI;
		}
		public static float DegToRad(float deg)
		{
			return deg * MathF.PI/180;
		}
	}
}
