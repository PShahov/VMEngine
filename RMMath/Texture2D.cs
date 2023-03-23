using OpenTK.Graphics.OpenGL;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Text;

namespace VMEngine
{
	public class Texture2D: IDisposable
	{
		public int Handle { get; private set; }
		public int Width { get; private set; }
		public int Height { get; private set; }
		public int BufferId { get; private set; }
		public float[] Coordinates { get; private set; }

		public Texture2D(string filePath, System.Drawing.Imaging.PixelFormat pixelFormat = System.Drawing.Imaging.PixelFormat.Format32bppArgb)
		{
			Bitmap bitmap= new Bitmap(1, 1);
			if(!File.Exists(filePath))
			{
				bitmap = (Bitmap)Image.FromFile(Assets.CONTENT_DIR + "tex\\_text02.bmp");
				//throw new FileNotFoundException();
			}
			else
			{
				bitmap = (Bitmap)Image.FromFile(filePath);
			}

			Width = bitmap.Width;
			Height = bitmap.Height;

			BitmapData data = bitmap.LockBits(new Rectangle(0,0,Width, Height), ImageLockMode.ReadOnly, pixelFormat);
			Handle = GL.GenTexture();
			GL.BindTexture(TextureTarget.Texture2D, Handle);
			GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.TextureWrapS, (int)TextureWrapMode.ClampToEdge);
			GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.TextureWrapT, (int)TextureWrapMode.ClampToEdge);
			GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.TextureMinFilter, (int)TextureMinFilter.Linear);
			GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.TextureMagFilter, (int)TextureMagFilter.Linear);
			GL.TexImage2D(TextureTarget.Texture2D, 0, PixelInternalFormat.Rgba, data.Width, data.Height, 0, OpenTK.Graphics.OpenGL.PixelFormat.Rgba, PixelType.UnsignedByte, data.Scan0);
			GL.BindTexture(TextureTarget.Texture2D, 0);
			bitmap.UnlockBits(data);

			Coordinates = new float[]
			{
				0f, 1f, //LU
				1f, 1f, //RU
				1f, 0f, //RD
				0f, 0f, //LD
			};

			BufferId = GL.GenBuffer();
			GL.BindBuffer(BufferTarget.ArrayBuffer, BufferId);
			GL.BufferData(BufferTarget.ArrayBuffer, Coordinates.Length * sizeof(float), Coordinates, BufferUsageHint.StaticDraw);
			GL.BindBuffer(BufferTarget.ArrayBuffer, 0);
		}

		public void Bind()
		{
			GL.ActiveTexture(TextureUnit.Texture0);
			GL.BindTexture(TextureTarget.Texture2D, Handle);
			GL.BindBuffer(BufferTarget.ArrayBuffer, BufferId);
			GL.TexCoordPointer(2, TexCoordPointerType.Float, 0, IntPtr.Zero);
		}

		public void Unbind()
		{
			GL.BindTexture(TextureTarget.Texture2D, 0);
			GL.BindBuffer(BufferTarget.ArrayBuffer, 0);
		}


		private bool disposedValue = false;

		protected virtual void Dispose(bool disposing)
		{
			if (!disposedValue)
			{
				GL.DeleteBuffer(BufferId);
				GL.DeleteTexture(Handle);

				disposedValue = true;
			}
		}

		~Texture2D()
		{
			//GL.DeleteProgram(Handle);
		}


		public void Dispose()
		{
			Dispose(true);
			GC.SuppressFinalize(this);
		}
	}
}
