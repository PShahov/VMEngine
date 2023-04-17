using System;
using System.Threading.Tasks;


using OpenTK.Graphics.OpenGL;
using VMEngine.Engine.DenseVoxel;
using static System.Runtime.InteropServices.JavaScript.JSType;

namespace VMEngine
{
	public class TextureBufferObject
	{
		public int BufferHandle;
		public int TextureHandle;
		public SizedInternalFormat Format;
		public static int DataLength = Chunk.CHUNK_TOTAL_FLOATS * 1;

		public TextureBufferObject(float[] data = null, SizedInternalFormat format = SizedInternalFormat.Rgba32f)
		{
			Format = format;

			if(data == null)
			{
				Random r = new Random();
				data = new float[Program.vm.Size.X * Program.vm.Size.Y];
				for (int i = 0; i < data.Length; i++)
				{
					data[i] = (float)r.NextDouble();
				}
			}

			nint length = (DataLength * sizeof(float));

			GL.GenBuffers(1, out BufferHandle);
			GL.BindBuffer(BufferTarget.TextureBuffer, BufferHandle);
			GL.BufferData(BufferTarget.TextureBuffer, (IntPtr)length, data, BufferUsageHint.DynamicDraw);

			GL.GenTextures(1, out TextureHandle);
			GL.BindTexture(TextureTarget.TextureBuffer, TextureHandle);
			GL.TexBuffer(TextureBufferTarget.TextureBuffer, Format, BufferHandle);

		}

		public void SetSubData(float[] data = null, int offset = 0)
		{
			if (data == null)
			{
				Random r = new Random();
				data = new float[Program.vm.Size.X * Program.vm.Size.Y];
				for (int i = 0; i < data.Length; i++)
				{
					data[i] = (float)r.NextDouble();
				}
			}

			GL.BindBuffer(BufferTarget.TextureBuffer, BufferHandle);
			GL.BufferSubData(BufferTarget.TextureBuffer, (IntPtr)(data.Length * sizeof(float)) * offset, (IntPtr)(data.Length * sizeof(float)), data);
			//GL.BufferData(BufferTarget.TextureBuffer, (IntPtr)(data.Length * sizeof(float)), data, BufferUsageHint.StaticDraw);
		}

		public void SetData(float[] data = null)
		{
			if (data == null)
			{
				Random r = new Random();
				data = new float[Program.vm.Size.X * Program.vm.Size.Y];
				for (int i = 0; i < data.Length; i++)
				{
					data[i] = (float)r.NextDouble();
				}
			}

			GL.BindBuffer(BufferTarget.TextureBuffer, BufferHandle);
			GL.BufferData(BufferTarget.TextureBuffer, (IntPtr)(data.Length * sizeof(float)), data, BufferUsageHint.DynamicDraw);

		}

		public void Use(Shader shader)
		{
			GL.ActiveTexture(TextureUnit.Texture0);
			GL.BindTexture(TextureTarget.TextureBuffer, TextureHandle);
			GL.Uniform1(GL.GetUniformLocation(shader.Handle, "u_tbo_tex"), 0);
		}
	}
}
