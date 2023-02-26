using System;
using System.Collections.Generic;
using System.Text;

namespace VMEngine.RMMath.RM
{
	static class RayMarching
	{
		public static float EPSILON = 0.000001F;
		public static int MAX_STEPS = 256;

		public static float sdSphere(Vector3 point, Vector3 sphereCenter, float sphereRadius)
		{
			return (point - sphereCenter).Magnitude() - sphereRadius;
		}

		//public Color
	}
}
