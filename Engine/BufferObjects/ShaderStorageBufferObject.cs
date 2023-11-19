using System;
using OpenTK.Graphics.OpenGL;

namespace VMEngine.Engine.BufferObjects
{
	public class ShaderStorageBufferObject : IDisposable
	{
		private bool _disposed;

		public int BufferHandle;
		public static int DataLength = 256;

		public ShaderStorageBufferObject(int dataLength)
		{
			DataLength = dataLength;
			int[] data = new int[DataLength];
			for (int i = 0; i < DataLength; i++)
			{
				data[i] = -1;
			}

			GL.GenBuffers(1, out BufferHandle);
			Console.WriteLine("BufferHandle: " + BufferHandle);
			GL.BindBuffer(BufferTarget.ShaderStorageBuffer, BufferHandle);
			GL.BufferData(BufferTarget.ShaderStorageBuffer, (IntPtr)(DataLength * sizeof(int)), data, BufferUsageHint.DynamicDraw);
			GL.BindBufferBase(BufferRangeTarget.ShaderStorageBuffer, 3, BufferHandle);
			GL.BindBuffer(BufferTarget.ShaderStorageBuffer, 0);


		}

		public void Dispose()
		{
			throw new NotImplementedException();
		}

		~ShaderStorageBufferObject()
		{
			Dispose();
		}
	}
}
