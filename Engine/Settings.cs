using OpenTK.Windowing.Common;
using System;
using System.Collections.Generic;
using System.Text;

namespace VMEngine.Engine
{
	public static class Settings
	{
		//public static bool VSync = false;
		public static VSyncMode VSync = VSyncMode.Off;
		public static Vector3 WindowSize = new Vector3(1600, 900);
	}
}
