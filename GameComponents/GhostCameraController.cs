using OpenTK.Windowing.GraphicsLibraryFramework;
using System;
using System.Collections.Generic;
using System.Text;

namespace VMEngine.GameComponents
{
	class GhostCameraController: Components.Component
	{
		private float speed = 5f;
		private float sensevity = 0.25f;

		public bool sendAlive = true;
		public bool sendMousePos = true;

		public override void Update()
		{
			if (Input.Keyboard.IsKeyPressed(Keys.D1))
			{
				//Console.WriteLine();
				//Console.WriteLine(Camera.mainCamera.gameObject.transform.parent.rotation.ToString());
				//Console.WriteLine(Quaternion.ToEuler(Camera.mainCamera.gameObject.transform.parent.rotation).ToString());
			}

			if (Input.Keyboard.IsKeyPressed(key: Keys.D1))
			{
				sendAlive = !sendAlive;
			}
			if (Input.Keyboard.IsKeyPressed(key: Keys.D2))
			{
				sendMousePos = !sendMousePos;
			}

			Vector3 dir = Vector3.zero;
			dir.z += Input.Keyboard.IsKeyDown(Keys.W) ? 1 : 0;
			dir.z += Input.Keyboard.IsKeyDown(Keys.S) ? -1 : 0;
			dir.y += Input.Keyboard.IsKeyDown(Keys.Space) ? 1 : 0;
			dir.y += Input.Keyboard.IsKeyDown(Keys.C) ? -1 : 0;
			dir.x += Input.Keyboard.IsKeyDown(Keys.D) ? -1 : 0;
			dir.x += Input.Keyboard.IsKeyDown(Keys.A) ? 1 : 0;

			dir = Camera.mainCamera.gameObject.transform.rotation.forward * dir.z +
				Camera.mainCamera.gameObject.transform.rotation.left * dir.x +
				Camera.mainCamera.gameObject.transform.rotation.up * dir.y;

			if (Input.Keyboard.IsKeyDown(Keys.LeftShift)) dir *= 2;

			Camera.mainCamera.gameObject.transform.position += dir * speed * Time.deltaTime;
			dir = Vector3.zero;
			dir.y += Input.Mouse.Delta.Y * -1;
			dir.x += Input.Mouse.Delta.X * -1;

			dir.x += Input.Keyboard.IsKeyDown(Keys.Left) ? 1 : 0;
			dir.x += Input.Keyboard.IsKeyDown(Keys.Right) ? -1 : 0;

			dir.y += Input.Keyboard.IsKeyDown(Keys.Up) ? 1 : 0;
			dir.y += Input.Keyboard.IsKeyDown(Keys.Down) ? -1 : 0;

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
					zoom = 1 / Math.Abs(Input.Mouse.Scroll.Y);
				}
			}

			dir *= sensevity / (zoom > 1 ? zoom : 1);

			Vector3 up = Camera.mainCamera.gameObject.transform.rotation.up;
			up = Vector3.up;

			if (Program.vm.CursorState == OpenTK.Windowing.Common.CursorState.Grabbed)
			{
				//Camera.mainCamera.gameObject.transform.rotation.RotateEulers(up, 5);
				Camera.mainCamera.gameObject.transform.rotation =
					Quaternion.FromEulers(up, dir.x * -1) * Camera.mainCamera.gameObject.transform.rotation;
				Camera.mainCamera.gameObject.transform.rotation = 
					Quaternion.FromEulers(Camera.mainCamera.gameObject.transform.rotation.left, dir.y) * Camera.mainCamera.gameObject.transform.rotation;
			}

		}
	}
}
