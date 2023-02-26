using System;
using System.Collections.Generic;
using System.Text;

using OpenTK.Graphics.OpenGL;

namespace VMEngine
{
	class VertexBufferObject: IDisposable
	{
		public static readonly int MaxVertexCount = 100_00;
		public static readonly int MinVertexCount = 1;

		private bool _disposed;


		public readonly VertexInfo VertexInfo;
		public readonly int VertexCount;
		public int IndicesCount;

		public int VertexBufferHandle;
		public int IndexBufferHandle;
		public int VertexArrayHandle;

		public PrimitiveType PrimitiveType = PrimitiveType.Triangles;

		public VertexBufferObject(VertexInfo vertexInfo, int vertexCount, BufferUsageHint bufferUsage = BufferUsageHint.StaticDraw)
		{
			_disposed = false;

			if (vertexCount < MinVertexCount || vertexCount > MaxVertexCount)
			{
				Console.ForegroundColor = ConsoleColor.Red;
				Console.WriteLine($"Vertex count must be in range [${MinVertexCount}, ${MaxVertexCount}]");
				throw new ArgumentOutOfRangeException(nameof(vertexCount));
			}

			this.VertexInfo = vertexInfo;
			this.VertexCount = vertexCount;

			VertexBufferHandle = GL.GenBuffer();
			GL.BindBuffer(BufferTarget.ArrayBuffer, VertexBufferHandle);
			GL.BufferData(BufferTarget.ArrayBuffer, VertexCount * VertexInfo.size, IntPtr.Zero, bufferUsage);
			GL.BindBuffer(BufferTarget.ArrayBuffer, 0);

		}
		public VertexBufferObject(VertexInfo vertexInfo, MeshAsset asset, BufferUsageHint bufferUsage = BufferUsageHint.StaticDraw)
		{
			_disposed = false;

			if (asset.Vertices.Length < MinVertexCount || asset.Vertices.Length > MaxVertexCount)
			{
				Console.ForegroundColor = ConsoleColor.Red;
				Console.WriteLine($"Vertex count must be in range [${MinVertexCount}, ${MaxVertexCount}]");
				throw new ArgumentOutOfRangeException(nameof(asset.Vertices.Length));
			}

			this.VertexInfo = vertexInfo;
			this.VertexCount = asset.Vertices.Length;

			VertexBufferHandle = GL.GenBuffer();
			GL.BindBuffer(BufferTarget.ArrayBuffer, VertexBufferHandle);
			GL.BufferData(BufferTarget.ArrayBuffer, VertexCount * VertexInfo.size, IntPtr.Zero, bufferUsage);
			GL.BindBuffer(BufferTarget.ArrayBuffer, 0);

			//this.SetData();

		}

		public void SetData<T>(T[] data, int count) where T : struct
		{
			if(typeof(T) != this.VertexInfo.type)
			{
				throw new ArgumentException("Type of 'T' does not match vertex type of vertex buffer type");
			}
			if (data == null)
			{
				throw new ArgumentNullException(nameof(data));
			}
			if (data.Length == 0)
			{
				throw new ArgumentOutOfRangeException(nameof(data));
			}
			//if(count <= 0 || count > this.VertexCount || count > data.Length)
			//{
			//	throw new ArgumentOutOfRangeException(nameof(count));
			//}

			GL.BindBuffer(BufferTarget.ArrayBuffer, VertexBufferHandle);
			GL.BufferSubData(BufferTarget.ArrayBuffer, IntPtr.Zero, count * VertexInfo.size, data);
			GL.BindBuffer(BufferTarget.ArrayBuffer, 0);
		}

		public void SetIndices(int[] indices, int count)
		{

			IndexBufferHandle = GL.GenBuffer();
			GL.BindBuffer(BufferTarget.ElementArrayBuffer, IndexBufferHandle);
			GL.BufferData(BufferTarget.ElementArrayBuffer, indices.Length * sizeof(int), indices, BufferUsageHint.StaticDraw);
			GL.BindBuffer(BufferTarget.ElementArrayBuffer, 0);
			IndicesCount = count;
			//IndexBufferHandle = GL.GenBuffer();
			//GL.BindBuffer(BufferTarget.ElementArrayBuffer, IndexBufferHandle);
			//GL.BufferData(BufferTarget.ElementArrayBuffer, indices.Length * sizeof(int), indices, BufferUsageHint.StaticDraw);
			//GL.BindBuffer(BufferTarget.ElementArrayBuffer, 0);
		}

		public void Bind()
		{
			VertexArrayHandle = GL.GenVertexArray();
			GL.BindVertexArray(VertexArrayHandle);

			int vertexSize = VertexInfo.size;
			//vertices & color
			for (int i = 0; i < Vertex.Info.attributes.Length; i++)
			{
				GL.VertexAttribPointer(
					Vertex.Info.attributes[i].index,
					Vertex.Info.attributes[i].count,
					VertexAttribPointerType.Float,
					false,
					vertexSize,
					//vertices.Length * Vertex.Info.size,
					Vertex.Info.attributes[i].offset
					);
				GL.EnableVertexAttribArray(Vertex.Info.attributes[i].index);
			}

			GL.BindVertexArray(0);
		}

		public void Draw()
		{
			GL.BindVertexArray(VertexArrayHandle);
			GL.BindBuffer(BufferTarget.ElementArrayBuffer, IndexBufferHandle);

			GL.DrawElements(PrimitiveType.Triangles, 6, DrawElementsType.UnsignedInt, 0);
		}

		~VertexBufferObject()
		{
			this.Dispose();
		}
		public void Dispose()
		{
			if (this._disposed)
			{
				return;
			}
			this._disposed = true;

			GL.BindBuffer(BufferTarget.ArrayBuffer, 0);
			GL.DeleteBuffer(VertexBufferHandle);
			GL.DeleteBuffer(IndexBufferHandle);
			GL.DeleteVertexArrays(1, ref VertexArrayHandle);

			GC.SuppressFinalize(this);
		}
	}
}
