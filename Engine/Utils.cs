using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection.Emit;
using System.Text;
using System.Threading.Tasks;

namespace VMEngine.Engine
{
	public static class Utils
	{
		public static int SizeOf<T>(T obj)
		{
			return SizeOfCache<T>.SizeOf;
		}

		private static class SizeOfCache<T>
		{
			public static readonly int SizeOf;

			static SizeOfCache()
			{
				var dm = new DynamicMethod("func", typeof(int),
										   Type.EmptyTypes, typeof(Utils));

				ILGenerator il = dm.GetILGenerator();
				il.Emit(OpCodes.Sizeof, typeof(T));
				il.Emit(OpCodes.Ret);

				var func = (Func<int>)dm.CreateDelegate(typeof(Func<int>));
				SizeOf = func();
			}
		}
	}
}
