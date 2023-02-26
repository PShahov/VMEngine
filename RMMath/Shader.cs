using OpenTK.Graphics.OpenGL;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace VMEngine
{
	public class Shader: IDisposable
	{
		public int Handle { get; private set; }

		public Shader(string vertexPath, string fragmentPath)
		{
			string VertexShaderSource = File.ReadAllText(vertexPath);
			string FragmentShaderSource = File.ReadAllText(fragmentPath);

			CreateShaderFromSource(VertexShaderSource, FragmentShaderSource);
		}

		public Shader(string[] fragmentPathes, string[] vertexPathes, string vertexCompiled = "", string fragmentCompiled = "")
		{
			string VertexShaderSource = "";
			string FragmentShaderSource = "";

			foreach (string vertexPath in vertexPathes)
			{
				string fileName = vertexPath.Split("/").Last();
				VertexShaderSource += File.ReadAllText(vertexPath) + "\n\n";
				//VertexShaderSource += $"\n\n ////// ${fileName}\n\n";
			}
			foreach (string fragmentPath in fragmentPathes)
			{
				string fileName = fragmentPath.Split("/").Last();
				FragmentShaderSource += File.ReadAllText(fragmentPath) + "\n\n";
				//FragmentShaderSource += $"\n\n ////// ${fileName}\n\n";
			}

			if (vertexCompiled.Length != 0)
			{
				File.WriteAllText(vertexCompiled, VertexShaderSource);
			}
			if (fragmentCompiled.Length != 0)
			{
				File.WriteAllText(fragmentCompiled, FragmentShaderSource);
			}

			CreateShaderFromSource(VertexShaderSource, FragmentShaderSource);
		}

		private void CreateShaderFromSource(string vertexShaderSource, string fragmentShaderSource)
		{

			var vertexShader = GL.CreateShader(ShaderType.VertexShader);
			GL.ShaderSource(vertexShader, vertexShaderSource);
			GL.CompileShader(vertexShader);

			var fragmentShader = GL.CreateShader(ShaderType.FragmentShader);
			GL.ShaderSource(fragmentShader, fragmentShaderSource);
			GL.CompileShader(fragmentShader);

			var program = GL.CreateProgram();
			GL.AttachShader(program, vertexShader);
			GL.AttachShader(program, fragmentShader);
			GL.LinkProgram(program);

			GL.DetachShader(program, vertexShader);
			GL.DetachShader(program, fragmentShader);
			GL.DeleteShader(vertexShader);
			GL.DeleteShader(fragmentShader);


			String infoLog = GL.GetProgramInfoLog(program);
			Console.WriteLine(infoLog);

			infoLog = GL.GetShaderInfoLog(vertexShader);
			Console.WriteLine(infoLog);
			infoLog = GL.GetShaderInfoLog(fragmentShader);
			Console.WriteLine(infoLog);

			Handle = program;
		}

		public void Use()
		{
			GL.UseProgram(Handle);
		}

		public int GetParam(String name)
		{
			return GL.GetUniformLocation(Handle, name);
		}
		public void SetInt(string name, int value)
		{
			int location = GL.GetUniformLocation(Handle, name);

			GL.Uniform1(location, value);
		}

		private bool disposedValue = false;

		protected virtual void Dispose(bool disposing)
		{
			if (!disposedValue)
			{
				GL.DeleteProgram(Handle);

				disposedValue = true;
			}
		}

		~Shader()
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
