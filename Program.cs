using OpenTK.Mathematics;
using OpenTK.Windowing.Common;
using OpenTK.Windowing.Desktop;
using System;

namespace VMEngine
{
	class Program
	{
		public static VMEngine vm;
		static void Main(string[] args)
		{
			GameWindowSettings _gwSettings = new GameWindowSettings();
			//_gwSettings
			NativeWindowSettings _nwSettings = new NativeWindowSettings()
			{
				Title = "VMEngine",
				WindowBorder = OpenTK.Windowing.Common.WindowBorder.Resizable,
				Size = (Vector2i)Engine.Settings.WindowSize.vector2F,
				StartFocused = true,
				StartVisible = true,
				
				Flags = OpenTK.Windowing.Common.ContextFlags.Default,
				Profile = ContextProfile.Core,
				API = ContextAPI.OpenGL,
			};
			vm = new VMEngine(_gwSettings, _nwSettings);
			vm.Start();
			vm.Run();
			//Console.WriteLine("Hello World!");
		}
	}
}
