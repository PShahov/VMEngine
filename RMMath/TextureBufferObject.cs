using System;
using System.Threading.Tasks;


using OpenTK.Graphics.OpenGL;
using static System.Runtime.InteropServices.JavaScript.JSType;

namespace VMEngine
{
	class TextureBufferObject
	{
		public int BufferHandle;
		public int TextureHandle;
		public SizedInternalFormat Format;

		public TextureBufferObject(float[] data = null, SizedInternalFormat format = SizedInternalFormat.R32f)
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


			GL.GenBuffers(1, out BufferHandle);
			GL.BindBuffer(BufferTarget.TextureBuffer, BufferHandle);
			GL.BufferData(BufferTarget.TextureBuffer, (IntPtr)(data.Length * sizeof(float)), data, BufferUsageHint.StaticDraw);

			GL.GenTextures(1, out TextureHandle);
			GL.BindTexture(TextureTarget.TextureBuffer, TextureHandle);
			GL.TexBuffer(TextureBufferTarget.TextureBuffer, Format, BufferHandle);

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
			GL.BufferData(BufferTarget.TextureBuffer, (IntPtr)(data.Length * sizeof(float)), data, BufferUsageHint.StaticDraw);

		}

		public void Use(Shader shader)
		{
			GL.ActiveTexture(TextureUnit.Texture0);
			GL.BindTexture(TextureTarget.TextureBuffer, TextureHandle);
			GL.Uniform1(GL.GetUniformLocation(shader.Handle, "u_tbo_tex"), 0);
		}
	}
}
