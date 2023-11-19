using System;
using System.Threading.Tasks;


using OpenTK.Graphics.OpenGL;
using VMEngine.Engine.HybridVoxel;
//using VMEngine.Engine.DenseVoxel;
using static System.Runtime.InteropServices.JavaScript.JSType;

namespace VMEngine
{
	public class TextureBufferObject
	{
		public int BufferHandle;
		public int TextureHandle;
		public SizedInternalFormat Format;
		//public static int DataLength = Chunk.CHUNK_TOTAL_FLOATS * ChunkController.TotalChunksCount * sizeof(float);
		public static int DataLength = 5762584 / 2;

		public TextureBufferObject(int bufferN = 1, float[] data = null, SizedInternalFormat format = SizedInternalFormat.Rgba32f)
		{
			Format = format;

			if(data == null)
			{
				Random r = new Random();
				data = new float[Program.vm.Size.X * Program.vm.Size.Y];
				//for (int i = 0; i < data.Length; i++)
				//{
				//	data[i] = (float)r.NextDouble();
				//}
			}

			//actual max Data length!!!
			//5762584


			GL.GenBuffers(bufferN, out BufferHandle);
			GL.BindBuffer(BufferTarget.TextureBuffer, BufferHandle);
			GL.BufferData(BufferTarget.TextureBuffer, (IntPtr)(DataLength), data, BufferUsageHint.DynamicDraw);

			GL.GenTextures(bufferN, out TextureHandle);
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
		public void SetData(byte[] data = null)
		{
			if (data == null)
			{
				Random r = new Random();
				data = new byte[1] { 255};
			}
			float[] fd = new float[(int)MathF.Ceiling(data.Length / 4)];


			for(int i = 0;i < fd.Length; i++)
			{
				if(i == fd.Length - 1)
				{
					int j = i * 4;
					int l = data.Length;
					byte[] _b = new byte[]
					{
						data[j],
						j + 1 < l ? data[j + 1] : (byte)0,
						j + 2 < l ? data[j + 2] : (byte)0,
						j + 3 < l ? data[j + 3] : (byte)0,
					};
					
					fd[i] = VoxelColor.ToFloat(_b);
				}
				else
				{
					int j = i * 4;
					fd[i] = VoxelColor.ToFloat(new byte[] { data[j], data[j + 1], data[j + 2], data[j + 3] });
				}
			}


			GL.BindBuffer(BufferTarget.TextureBuffer, BufferHandle);
			GL.BufferData(BufferTarget.TextureBuffer, (IntPtr)(fd.Length * sizeof(float)), fd, BufferUsageHint.DynamicDraw);

			//GL.BindBuffer(BufferTarget.TextureBuffer, BufferHandle);
			//GL.BufferData(BufferTarget.TextureBuffer, (IntPtr)(data.Length), data, BufferUsageHint.DynamicDraw);
		}

		public void Use(Shader shader)
		{
			GL.ActiveTexture(TextureUnit.Texture0);
			GL.BindTexture(TextureTarget.TextureBuffer, TextureHandle);
			GL.Uniform1(GL.GetUniformLocation(shader.Handle, "u_tbo_tex"), 0);
			GL.Uniform1(GL.GetUniformLocation(shader.Handle, "u_tbo_tex2"), 1);
		}
	}
}
