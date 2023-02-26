using System;
using System.Collections.Generic;
using System.Text;

using OpenTK;
using OpenTK.Windowing.GraphicsLibraryFramework;

namespace VMEngine
{
	public static class Input
	{
		public static Vector3 MousePosition = new Vector3(0, 0, 0);
		public static Vector3 MouseDelta = new Vector3(0, 0, 0);

		public static KeyboardState Keyboard;
		public static MouseState Mouse;
	}
}
