using OpenTK.Mathematics;
using OpenTK.Windowing.Common;
using OpenTK.Windowing.Desktop;
using System;
using System.Text;

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

		public static void FloatToBinary(float f)
		{
			StringBuilder sb = new StringBuilder();
			Byte[] ba = BitConverter.GetBytes(f);
			foreach (Byte b in ba)
				for (int i = 0; i < 8; i++)
				{
					sb.Insert(0, ((b >> i) & 1) == 1 ? "1" : "0");
				}
			string s = sb.ToString();
			string r = s.Substring(0, 1) + " " + s.Substring(1, 8) + " " + s.Substring(9); //sign exponent mantissa

			Console.WriteLine(r);
		}
	}
}
