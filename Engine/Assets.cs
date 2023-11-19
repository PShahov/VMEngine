using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace VMEngine
{
	static class Assets
	{
		//public static string ShaderFolder = "octree_traversal";
		public static string ShaderFolder = "hybrid";
		//public static string ShaderFolder = "traversal";

		public static readonly string CONTENT_DIR = "..\\..\\..\\assets\\";

		public static Dictionary<String, Texture2D> textures = new Dictionary<string, Texture2D>();
		public static Dictionary<String, Texture> Textures = new Dictionary<string, Texture>();
		//public static Dictionary<String, Font> fonts = new Dictionary<string, Font>();
		public static Dictionary<String, Shader> Shaders = new Dictionary<string, Shader>();
		public static Dictionary<String, MeshAsset> Meshes = new Dictionary<string, MeshAsset>();

		public static void Load()
		{
			Meshes.Add("cube_01", new MeshAsset(CONTENT_DIR + "models\\cube_01.obj", 0.01f));
			//textures.Add("tex01", new Texture2D(CONTENT_DIR + "tex\\test0.png"));
			Textures.Add("testTex", Texture.LoadFromFile(CONTENT_DIR + "tex\\_tex_test.png"));
			//Textures.Add("tex02", Texture.LoadFromFile(CONTENT_DIR + "tex\\tex_01.png"));
			//Textures.Add("tex02_bump", Texture.LoadFromFile(CONTENT_DIR + "tex\\tex_01_bump.png"));
			//Textures.Add("tex01", Texture.LoadFromFile(CONTENT_DIR + "tex\\test0.png"));
			//Textures.Add("tex01_bump", Texture.LoadFromFile(CONTENT_DIR + "tex\\test0_bump.png"));
			//textures.Add("tex02", new Texture(CONTENT_DIR + "tex\\_text02.bmp"));

			//fonts.Add("roboto-regular", new Font(CONTENT_DIR + "fonts\\Roboto-Regular.ttf"));

			//shaders.Add("simple", new Shader(null, null, CONTENT_DIR + "shaders\\first_frag.glsl"));
			//Shader t = new Shader(null, null, CONTENT_DIR + "shaders\\testShader.glsl");
			//t.SetUniform("iResolution", new SFML.Graphics.Glsl.Vec3(Engine.Settings.WindowSize.x, Engine.Settings.WindowSize.y, 0));
			//shaders.Add("test", t);

			Shader sh = new Shader(CONTENT_DIR + "shaders/dev/first_vert.glsl", CONTENT_DIR + "shaders/dev/first_frag.glsl");
			Shaders.Add("test", sh);

			sh = new Shader(CONTENT_DIR + "shaders/dev/first_vert.glsl", CONTENT_DIR + "shaders/dev/#version 330 core.glsl");
			Shaders.Add("test_rm", sh);

			//sh = new Shader(CONTENT_DIR + "shaders\\first_vert.glsl", CONTENT_DIR + "shaders\\testRMShader.glsl");

			//sh = new Shader(new string[]
			//{
			//	CONTENT_DIR + "shaders/build/header.glsl",
			//	CONTENT_DIR + "shaders/build/vars.glsl",
			//	CONTENT_DIR + "shaders/build/hg_sdf.glsl",
			//	//CONTENT_DIR + "shaders/build/pbl_sdf.glsl",
			//	CONTENT_DIR + "shaders/build/pbl_class.glsl",
			//	CONTENT_DIR + "shaders/build/pbl_math.glsl",
			//	CONTENT_DIR + "shaders/build/pbl_sdf_ID.glsl",
			//	CONTENT_DIR + "shaders/build/pbl_models.glsl",
			//	CONTENT_DIR + "shaders/build/pbl_mat.glsl",
			//	CONTENT_DIR + "shaders/build/pbl_light.glsl",
			//	CONTENT_DIR + "shaders/build/vertexShader_main.glsl",
			//}, new string[]
			//{
			//	CONTENT_DIR + "shaders/build/fragmentShader_main.glsl"
			//}, CONTENT_DIR + "shaders/compiled/vertex.glsl", CONTENT_DIR + "shaders/compiled/fragment.glsl");
			//Shaders.Add("raymarch", sh);

			//sh = new Shader(new string[]
			//{
			//	CONTENT_DIR + "shaders/build/traversal/header.glsl",
			//	CONTENT_DIR + "shaders/build/traversal/support.glsl",
			//	CONTENT_DIR + "shaders/build/traversal/vertex.glsl",
			//}, new string[]
			//{
			//	CONTENT_DIR + "shaders/build/traversal/fragment.glsl"
			//}, CONTENT_DIR + "shaders/compiled/vertex.glsl", CONTENT_DIR + "shaders/compiled/fragment.glsl");

			sh = new Shader(new string[]
			{
				CONTENT_DIR + "shaders/build/" + ShaderFolder + "/header.glsl",
				CONTENT_DIR + "shaders/build/" + ShaderFolder + "/support.glsl",
				CONTENT_DIR + "shaders/build/" + ShaderFolder + "/vertex.glsl",
			}, new string[]
			{
				CONTENT_DIR + "shaders/build/" + ShaderFolder + "/fragment.glsl"
			}, CONTENT_DIR + "shaders/compiled/vertex.glsl", CONTENT_DIR + "shaders/compiled/fragment.glsl");

			Shaders.Add("raymarch", sh);
		}
		public static void ReloadShaders()
		{
			Shaders["test_rm"].Use();


			Shaders["raymarch"] = new Shader(new string[]
			{
				CONTENT_DIR + "shaders/build/" + ShaderFolder + "/header.glsl",
				CONTENT_DIR + "shaders/build/" + ShaderFolder + "/support.glsl",
				CONTENT_DIR + "shaders/build/" + ShaderFolder + "/vertex.glsl",
			}, new string[]
			{
				CONTENT_DIR + "shaders/build/" + ShaderFolder + "/fragment.glsl"
			}, CONTENT_DIR + "shaders/compiled/vertex.glsl", CONTENT_DIR + "shaders/compiled/fragment.glsl");

			Shaders["raymarch"].Use();
		}
	}


	public class MeshAsset
	{
		public Vertex[] Vertices;
		public int[] Indices;

		public MeshAsset(String filePath, float scale = 1)
		{
			if (!File.Exists(filePath))
			{
				filePath = Assets.CONTENT_DIR + filePath;
				if (!File.Exists(filePath))
				{
					throw new FileNotFoundException(filePath + " - File not found.");
				}
			}
			string ext = Path.GetExtension(filePath).ToLower();
			switch (ext)
			{
				case ".obj":
					{
						_loadFromOBJ(filePath, scale);
						break;
					}
				default:
					{
						throw new Exception(ext + " extenstion does not supported yet.");
					}

				
			}
			
		}

		private void _loadFromOBJ(String filePath, float scale = 1)
		{

			string[] lines = File.ReadAllLines(filePath);

			List<Vertex> verticesList = new List<Vertex>();
			List<int> indicesList = new List<int>();

			foreach (string l in lines)
			{
				if(l.Length < 1)
				{
					continue;
				}
				switch (l[0])
				{
					case 'v':
						{
							string[] s = l.Substring(2).Split(' ');
							verticesList.Add(new Vertex(
								new Vector3(
									float.Parse(s[0]) * scale,
									float.Parse(s[1]) * scale,
									float.Parse(s[2]) * scale
									),
								OpenTK.Mathematics.Color4.Red
								));
							break;
						}
					case 'f':
						{
							string[] s = l.Substring(2).Split(' ');
							for (int i = 0; i < s.Length; i++)
							{
								indicesList.Add(int.Parse(s[i]));
							}
							break;
						}
				}
			}

			Vertices = verticesList.ToArray();
			Indices = indicesList.ToArray();
		}
	}
}
