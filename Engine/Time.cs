using System;
using System.Collections.Generic;
using System.Text;

namespace VMEngine
{
	class Time
	{
		public static float deltaTime { get { return _dt * timeScale; } }
		public static double renderDeltaTime = 0;
		public static float deltaTimeUnscaled { get { return _dt; } }
		public static float timeScale = 1;
		public static float alive { get { return (DateTime.Now - _startTime).Ticks / 10000000f; } }

		private static float _dt = 0;
		private static float _alive = 0;
		private static DateTime _lastTime = DateTime.Now;
		public static DateTime _startTime = DateTime.Now;
		public static void Tick()
		{
			DateTime dt = DateTime.Now;
			_dt = (dt.Ticks - _lastTime.Ticks) / 10000000f;
			_lastTime = dt;
			//_alive = _alive + _dt;
			//deltaTime = 100;
		}
	}
}
