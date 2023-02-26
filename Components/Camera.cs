using OpenTK.Mathematics;
using System;
using System.Collections.Generic;
using System.Text;
using VMEngine.Components;

namespace VMEngine
{
	public class Camera: Component
	{
		public static Camera mainCamera {
			get
			{
				return _mainCamera;
			}
			set
			{
				_mainCamera = value;

			}
		}
		private static  Camera _mainCamera;
		public float FOV = 90;
		public Vector3 Size = new Vector3(1920, 1080, 100);
		
		public Camera(bool isMain = false)
		{
			Program.vm._camPoolAdd(this);
			if (isMain || Camera.mainCamera == null)
			{
				Camera.mainCamera = this;
			}
		}
		public override void Start()
		{
			base.Start();
			View = CreateLookAt();
			Projection = Matrix4.CreatePerspectiveFieldOfView(MathHelper.PiOver4, (float)Program.vm.Size.X / (float)Program.vm.Size.Y, 0.01f, 1000);
		}
		public override void Update()
		{
			base.Update();
			View = CreateLookAt();
		}
		protected Matrix4 CreateLookAt()
		{
			return Matrix4.LookAt(gameObject.transform.position.vector3F, gameObject.transform.position.vector3F + gameObject.transform.rotation.forward.vector3F, gameObject.transform.rotation.up.vector3F);
			//return Matrix4.LookAt(gameObject.transform.position.vector3F, new OpenTK.Mathematics.Vector3(0,0,0), gameObject.transform.rotation.up.vector3F);
		}
		public double Yaw
		{
			get { return Math.PI - Math.Atan2(gameObject.transform.rotation.forward.y, gameObject.transform.rotation.forward.z); }
		}
		public double Pitch
		{
			get { return Math.Asin(gameObject.transform.rotation.forward.y); }
		}
		public Matrix4 View { get; protected set; }
		public Matrix4 Projection { get; protected set; }
	}
}
