using OpenTK;
using OpenTK.Graphics;
using OpenTK.Graphics.OpenGL;
using OpenTK.Mathematics;
using OpenTK.Windowing.Common;
using OpenTK.Windowing.Desktop;
using OpenTK.Windowing.GraphicsLibraryFramework;
using OpenTK.Input;

using System;
using System.Collections.Generic;
using System.Text;
using System.Threading;
using Microsoft.Maui.Graphics;

using VMEngine.Components;
using VMEngine.RMMath.RM;
using VMEngine.GameComponents;
using VMEngine.Engine;
//using VMEngine.UI;

namespace VMEngine
{
	class VMEngine: GameWindow
	{
		private GameObject[] _gmPool = new GameObject[256];
		private RMMeshComponent[] _rmPool = new RMMeshComponent[256];
		private Camera[] _camPool = new Camera[8];
		//private 
		//private Ope _camera;

		private int _gmPoolActualLength = 0;
		private int _rmPoolActualLength = 0;
		private int _camPoolActualLength = 0;

		//public View view;

		private Thread _fpsThread;

		private Dictionary<String, String> _titleDebug = new Dictionary<string, string>();

		public byte[] _planeTexColors;

		private float _screenRatio = 800 / 600;

		public int _pix = 0;
		public Quaternion qcenter;
		public Quaternion qstart;
		public Quaternion qcurrent;

		public float hfov = 90;
		public float vfov = 90 / (800 / 600);

		private int _vertexArray;
		//private int _vetrexBuffer;
		private VertexBufferObject vbo;
		private int _indicesBuffer;

		private Phantom.otkCamera camera;

		private int test = 4;

		private GhostCameraController ghost;

		private VoxelOctree testOct = new VoxelOctree(Vector3.zero, 5, VoxelColor.Random());

		//public TextRenderer DebugTextRenderer;

		Font mono = new Font("Impact");

		//public Text _debugText = new Text();
		public VMEngine(GameWindowSettings gameWindowSettings, NativeWindowSettings nativeWindowSettings) : base(gameWindowSettings, nativeWindowSettings)
		{
			VSync = VSyncMode.On;
			//UpdateFrequency = 120;
			//RenderFrequency = 120;

			UpdateFrame += Win_UpdateFrame;
			RenderFrame += Win_RenderFrame;
			Load += Win_Load;
			Resize += Win_Resize;
			MouseMove += Win_MouseMove;
			//Closed += Win_Closed;


			testOct.Divide();
		}


		public void Start()
		{


			Assets.Load();

			_fpsThread = new Thread(FpsCounter);
			_fpsThread.Start();


			ghost = Prefabs.prefab_cameraGhost(new Vector3(-5f, 5.25f, 0f), Quaternion.FromRadians(0, MathV.DegToRad(90), 0)).GetComponent<GhostCameraController>();
			Prefabs.testCube(new Vector3(0,-1f,0), Quaternion.identity);
			//Prefabs.testCube(new Vector3(4, 0, 0), Quaternion.identity);
			//Prefabs.testCube(new Vector3(-4, 0, 0), Quaternion.identity);

			//GameObject gm = Prefabs.prefab_rmSphere(new Vector3(0, 0, 10), fColor.Red, 1);
			//gm.transform.rotation = Quaternion.FromRadians(Vector3.forward, MathV.DegToRad(45));


			Console.WriteLine(GL.GetString(StringName.Version));
			Console.WriteLine(GL.GetString(StringName.Vendor));
			Console.WriteLine(GL.GetString(StringName.Renderer));
			Console.WriteLine(GL.GetString(StringName.ShadingLanguageVersion));

			//Assets.textures["tex01"].Bind();

		}

		private void _reloadShader()
		{
			Assets.ReloadShaders();

			GL.Uniform2(Assets.Shaders["raymarch"].GetParam("u_resolution"), new Vector2(Size.X, Size.Y));
			//Assets.textures["tex01"].Bind();
			//Assets.Textures["tex02"].Use(TextureUnit.Texture2);
			//Assets.Textures["tex02_bump"].Use(TextureUnit.Texture3);
			//Assets.Shaders["raymarch"].SetInt("u_tex_01", Assets.Textures["tex02"].Handle - 1);
			//Assets.Shaders["raymarch"].SetInt("u_tex_01_bump", Assets.Textures["tex02_bump"].Handle - 1);
			//_shader.SetInt("texture0", 0);
			//_shader.SetInt("texture1", 1);
		}

		private void Win_Resize(ResizeEventArgs e)
		{
			GL.Viewport(0, 0, e.Width, e.Height);
			GL.Uniform2(Assets.Shaders["raymarch"].GetParam("u_resolution"), new Vector2(Size.X, Size.Y));
		}

		private void Win_Load()
		{
			//camera = new Phantom.otkCamera(this);
			CursorState = CursorState.Normal;

			Console.WriteLine(Quaternion.FromEulers(Vector3.up, 45).ToString());
			Console.WriteLine(Quaternion.ToEuler(Quaternion.FromEulers(Vector3.up, 45)).y.ToString());

			Vertex[] vertices = new Vertex[]
			{
				new Vertex(new Vector3(1f, 1f, 0), new Color4(1,0,0,0.1f)),//0
				new Vertex(new Vector3(-1f, 1f, 0), new Color4(0,1,0,0.1f)),//1
				new Vertex(new Vector3(-1f, -1f, 0), new Color4(0,0,1,0.1f)),//2
				new Vertex(new Vector3(1f, 1f, 0), new Color4(1,0,0,0.1f)),//0
				new Vertex(new Vector3(-1f, -1f, 0), new Color4(0,0,1,0.1f)),//2
				new Vertex(new Vector3(1f, -1f, 0), new Color4(1,1,1,0.1f)),//3
			};

			int[] indices = new int[]
			{
				0,1,2,
				3,4,5
			};

			Assets.Meshes["cube_01"].Vertices = vertices;
			Assets.Meshes["cube_01"].Indices = indices;

			vbo = new VertexBufferObject(Vertex.Info, Assets.Meshes["cube_01"].Vertices.Length);
			vbo.SetData(Assets.Meshes["cube_01"].Vertices, Assets.Meshes["cube_01"].Vertices.Length);
			vbo.PrimitiveType = PrimitiveType.Quads;

			vbo.SetIndices(Assets.Meshes["cube_01"].Indices, Assets.Meshes["cube_01"].Indices.Length);


			GL.BindBuffer(BufferTarget.ArrayBuffer, vbo.VertexBufferHandle);



			_vertexArray = GL.GenVertexArray();
			GL.BindVertexArray(_vertexArray);


			int vertexSize = vbo.VertexInfo.size;
			//vertices & color
			for(int i = 0;i < Vertex.Info.attributes.Length; i++)
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



			GL.PointSize(5f);

			//GL.Enable(EnableCap.DepthTest);
			GL.Enable(EnableCap.Blend);
			GL.Enable(EnableCap.Texture2D);
			GL.BlendFunc(BlendingFactor.SrcAlpha, BlendingFactor.OneMinusSrcAlpha);

			Assets.Shaders["raymarch"].Use();
			//GL.Uniform2(Assets.Shaders["raymarch"].GetParam("u_resolution"), new Vector2(Size.X, Size.Y));

		}

		//update
		private void Win_UpdateFrame(FrameEventArgs e)
		{
			Time.Tick();

			//camera.Update(e);

			if (KeyboardState.IsKeyDown(Keys.Escape))
			{
				//Close();
			}
			if (KeyboardState.IsKeyPressed(Keys.F11))
			{
				WindowState = WindowState == WindowState.Normal ? WindowState.Fullscreen : WindowState.Normal;
			}
			if (KeyboardState.IsKeyPressed(Keys.F1))
			{
				CursorState = CursorState == CursorState.Normal ? CursorState.Grabbed : CursorState.Normal;
			}
			if (KeyboardState.IsKeyPressed(Keys.KeyPad2))
			{
				test++;
			}
			if (KeyboardState.IsKeyPressed(Keys.KeyPad1))
			{
				test--;
			}
			if (KeyboardState.IsKeyPressed(Keys.F2))
			{
				this._reloadShader();
				//Shaders.Add("raymarch", sh);
			}
			if (KeyboardState.IsKeyPressed(Keys.F3))
			{
				VSync = VSync == VSyncMode.On ? VSyncMode.Off : VSyncMode.On;
			}
			if (KeyboardState.IsKeyPressed(Keys.V))
			{
				testOct.Divide();
			}
			if (KeyboardState.IsKeyPressed(Keys.B))
			{
				float[] arr = testOct.ToArray();

				string s = "";
				int i = 0;
				foreach(float f in arr)
				{
					s += $"{f}f, ";
					i++;
					if (i % 5 == 0) s += "\n";
				}
				Console.WriteLine(s);
				Console.WriteLine("\n");
				Console.WriteLine((arr.Length / 5).ToString());
			}
			if (KeyboardState.IsKeyPressed(Keys.N))
			{
				float[] arr = testOct.ToArray();
				int l = arr.Length;
				//test cube
				GL.Uniform1(Assets.Shaders["raymarch"].GetParam("u_objects"), l, arr);
				GL.Uniform1(Assets.Shaders["raymarch"].GetParam("u_object_size"), l / 5);
			}


			Tick();

			DebugTick();
		}

		//render
		private void Win_RenderFrame(FrameEventArgs e)
		{
			Time.renderDeltaTime = e.Time;
			//GL.ClearColor(MathF.Abs(MathF.Sin(Time.alive)), MathF.Abs(MathF.Sin(Time.alive - 1f)), MathF.Abs(MathF.Sin(Time.alive + 1f)), 1);
			GL.Clear(ClearBufferMask.ColorBufferBit);

			//Assets.Textures["tex01"].Use(TextureUnit.Texture0);
			Assets.Shaders["raymarch"].Use();


			List<float> list = new List<float>();

			foreach (RMMeshComponent rmmesh in this._rmPool)
			{
				if (rmmesh != null)
					list.AddRange(rmmesh.ToArray());
			}

			try
			{
				float[] arr = testOct.ToArray();
				int l = arr.Length;
				//test cube
				GL.Uniform1(Assets.Shaders["raymarch"].GetParam("u_objects"), l, arr);
				GL.Uniform1(Assets.Shaders["raymarch"].GetParam("u_object_size"), l / 5);

				//int arrayPtr = Assets.Shaders["raymarch"].GetParam("u_objects");
				//float[] arr = list.ToArray();
				////int l = 13 * sizeof(float);
				//int l = arr.Length;
				//GL.Uniform1(arrayPtr, l, arr);

				//GL.Uniform1(Assets.Shaders["raymarch"].GetParam("u_object_size"), _rmPoolActualLength);
			}
			catch (Exception ex)
			{
				Console.WriteLine(ex.ToString());
			}



			GL.BindVertexArray(_vertexArray);
			GL.BindBuffer(BufferTarget.ElementArrayBuffer, vbo.IndexBufferHandle);
			GL.DrawElements((PrimitiveType)test, Assets.Meshes["cube_01"].Indices.Length, DrawElementsType.UnsignedInt, IntPtr.Zero);


			GL.Flush();
			Context.SwapBuffers();
			//SwapBuffers();
		}
		private void Win_MouseMove(MouseMoveEventArgs e)
		{
			//Assets.shaders["test"]
			//GL.Uniform4()
			Input.MousePosition = new Vector3(e.X, e.Y, 0);
			Input.MouseDelta = new Vector3(e.DeltaX, e.DeltaY, 0);
			//GL.Uniform4(Assets.shaders["test_rm"].GetParam("iMouse"), e.X, e.Y, 1, 1);
		}

		private void UpdateTitleDebug(String key, String value)
		{
			if (_titleDebug.ContainsKey(key))
			{
				_titleDebug[key] = value;
			}
			else
			{
				_titleDebug.Add(key, value);
			}
		}

		private void DebugTick()
		{
			UpdateTitleDebug("gms", "GM pool: " + _gmPoolActualLength.ToString());
			UpdateTitleDebug("rms", "RM meshes: " + _rmPoolActualLength.ToString());

			String s = "";
			String[] keys = new string[_titleDebug.Count];
			_titleDebug.Keys.CopyTo(keys, 0);
			foreach (string key in keys)
			{
				s += _titleDebug[key] + "\n";
			}
			//win.SetTitle(s);
			//_debugText.DisplayedString = s;
		}

		private void Tick()
		{
			Input.Keyboard = KeyboardState;
			Input.Mouse = MouseState;
			int gm = 0;
			int comps = 0;
			for (int i = 0; i < _gmPool.Length; i++)
			{
				if (_gmPool[i] == null)
				{
					continue;
				}

				if(_gmPool[i].transform.parent != null)
				{
					_gmPool[i].transform.position = _gmPool[i].transform.parent.position + _gmPool[i].transform.localPosition;
				}

				for (int j = 0; j < _gmPool[i].components.Count; j++)
				{
					_gmPool[i].components[j].Update();
					comps++;
				}
				_gmPool[i].Update();
				gm++;
			}

			if(Camera.mainCamera != null)
			{
				//_shader.SetMatrix4("view", _camera.GetViewMatrix());
				//_shader.SetMatrix4("projection", _camera.GetProjectionMatrix());
				Matrix4 view = Camera.mainCamera.View;
				Matrix4 projection = Camera.mainCamera.Projection;
				//var model = Matrix4.Identity * Matrix4.CreateRotationX((float)MathHelper.DegreesToRadians(Time.deltaTime));
				GL.UniformMatrix4(Assets.Shaders["raymarch"].GetParam("view"), true, ref view);
				GL.UniformMatrix4(Assets.Shaders["raymarch"].GetParam("projection"), true, ref projection);
				//GL.UniformMatrix4(Assets.shaders["test"].GetParam("model"), true, ref model);
				//Camera.mainCamera.ApplyTransform();

			}

			UpdateTitleDebug("gmupd", "GM`s updated: " + gm.ToString());
			UpdateTitleDebug("compupd", "comp`s updated: " + comps.ToString());

			Input.MouseDelta = Vector3.zero;



			Assets.Shaders["raymarch"].Use();
			GL.Uniform3(Assets.Shaders["raymarch"].GetParam("u_camera_position"), Camera.mainCamera.gameObject.transform.position.vector3F);
			GL.Uniform3(Assets.Shaders["raymarch"].GetParam("u_camera_forward"), Camera.mainCamera.gameObject.transform.rotation.forward.vector3F);
			GL.Uniform3(Assets.Shaders["raymarch"].GetParam("u_camera_right"), Camera.mainCamera.gameObject.transform.rotation.right.vector3F);
			GL.Uniform3(Assets.Shaders["raymarch"].GetParam("u_camera_up"), Camera.mainCamera.gameObject.transform.rotation.up.vector3F);
			GL.Uniform3(Assets.Shaders["raymarch"].GetParam("u_camera_look_at"), Camera.mainCamera.gameObject.transform.rotation.up.vector3F + Camera.mainCamera.gameObject.transform.position.vector3F);
			float zoom = 0;
			if (Math.Abs(Input.Mouse.Scroll.Y) == 0)
			{
				zoom = 1;
			}
			else
			{
				zoom = Math.Abs(Input.Mouse.Scroll.Y);
				if (Input.Mouse.Scroll.Y < 0)
				{
					zoom = 1 / MathF.Pow(Math.Abs(Input.Mouse.Scroll.Y), 2);
				}
			}

			GL.Uniform1(Assets.Shaders["raymarch"].GetParam("u_mouse_wheel"), zoom);
			if (ghost.sendMousePos)
				GL.Uniform2(Assets.Shaders["raymarch"].GetParam("u_mouse"), this.MousePosition);
			if (ghost.sendAlive)
				GL.Uniform1(Assets.Shaders["raymarch"].GetParam("u_time"), Time.alive);
		}


		public GameObject Instantiate()
		{
			int i = 0;
			_gmPoolActualLength++;

			for (i = 0; i < _gmPool.Length; i++)
			{
				if (_gmPool[i] == null)
				{
					return _gmPool[i] = new GameObject();
				}
			}

			i = _gmPool.Length;
			Array.Resize(ref _gmPool, _gmPool.Length * 2);

			return _gmPool[i] = new GameObject();
		}
		public RMMeshComponent _rmPoolAdd(RMMeshComponent mesh)
		{
			_rmPoolActualLength++;
			int i = 0;

			for (i = 0; i < _rmPool.Length; i++)
			{
				if (_rmPool[i] == null)
				{
					return _rmPool[i] = mesh;
				}
			}

			i = _rmPool.Length;
			Array.Resize(ref _rmPool, _rmPool.Length * 2);

			return _rmPool[i] = mesh;
		}
		public Camera _camPoolAdd(Camera camera)
		{
			_camPoolActualLength++;
			int i = 0;

			for (i = 0; i < _camPool.Length; i++)
			{
				if (_camPool[i] == null)
				{
					return _camPool[i] = camera;
				}
			}

			i = _camPool.Length;
			Array.Resize(ref _camPool, _camPool.Length * 2);

			return _camPool[i] = camera;
		}


		private void Win_Closed()
		{
			GL.DeleteVertexArrays(1, ref _vertexArray);
			Close();
		}
		private async void FpsCounter()
		{
			while (Exists)
			{

				string s = (($"FPS: ~{1 / Time.deltaTime}"));
				UpdateTitleDebug("fps", s);
				Title = s;

				//Title = ghost.gameObject.transform.position.ToString();

				//Title = (1 / Time.renderDeltaTime).ToString();
				//Title = Camera.mainCamera.gameObject.transform.rotation.forward.ToString();
				float u_opacity = -1;
				GL.GetUniform(Assets.Shaders["raymarch"].Handle, Assets.Shaders["raymarch"].GetParam("u_opacity"), out u_opacity);
				//GL.Uniform2(Assets.Shaders["raymarch"].GetParam("u_resolution"), new Vector2(Size.X, Size.Y));
				//Title = u_opacity.ToString();

				Thread.Sleep(250);

			}

			Console.WriteLine("fps thread terminated");
		}
	}
}
