using OpenTK.Graphics.OpenGL;
using System.Drawing;
using System.Drawing.Imaging;
using PixelFormat = OpenTK.Graphics.OpenGL.PixelFormat;
using StbImageSharp;
using System.IO;
using System;

namespace VMEngine
{
	public class Texture
	{
		public readonly int Handle;

		public static Texture LoadFromFile(string path)
		{
			int handle = GL.GenTexture();

			Console.WriteLine(path + " " + handle.ToString());

			GL.ActiveTexture(TextureUnit.Texture0);
			GL.BindTexture(TextureTarget.Texture2D, handle);
			StbImage.stbi_set_flip_vertically_on_load(1);

			using (Stream stream = File.OpenRead(path))
			{
				ImageResult image = ImageResult.FromStream(stream, ColorComponents.RedGreenBlueAlpha);
				GL.TexImage2D(TextureTarget.Texture2D, 0, PixelInternalFormat.Rgba, image.Width, image.Height, 0, PixelFormat.Rgba, PixelType.UnsignedByte, image.Data);
			}

			GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.TextureMinFilter, (int)TextureMinFilter.Linear);
			GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.TextureMagFilter, (int)TextureMagFilter.Linear);

			GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.TextureWrapS, (int)TextureWrapMode.Repeat);
			GL.TexParameter(TextureTarget.Texture2D, TextureParameterName.TextureWrapT, (int)TextureWrapMode.Repeat);

			GL.GenerateMipmap(GenerateMipmapTarget.Texture2D);

			return new Texture(handle);
		}

		public Texture(int glHandle)
		{
			Handle = glHandle;
		}

		// Activate texture
		// Multiple textures can be bound, if your shader needs more than just one.
		// If you want to do that, use GL.ActiveTexture to set which slot GL.BindTexture binds to.
		// The OpenGL standard requires that there be at least 16, but there can be more depending on your graphics card.
		public void Use(TextureUnit unit)
		{
			GL.ActiveTexture(unit);
			GL.BindTexture(TextureTarget.Texture2D, Handle);
		}
	}
}
