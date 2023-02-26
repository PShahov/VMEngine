using System;
using System.Collections.Generic;
using System.Text;

using VMEngine.Components;
using VMEngine.RMMath;
using VMEngine.RMMath.RM.MeshComponents;

namespace VMEngine
{
	static class Prefabs
	{
		public static GameObject prefab_cameraGhost(Vector3 position, Quaternion rotation)
		{
			//Console.WriteLine(rotation.forward);
			GameObject gm = Program.vm.Instantiate();
			gm.transform.position = position;
			gm.transform.rotation = rotation;
			gm.AddComponent(new Camera(true)).gameObject = gm;
			gm.AddComponent(new GameComponents.GhostCameraController()).gameObject = gm;
			//GameObject gm2 = Program.vm.Instantiate();
			//gm2.transform.position = position;
			//gm2.transform.rotation = rotation;
			//gm.transform.parent = gm2.transform;

			return gm;
		}
		public static GameObject testSphere(Vector3 position, Quaternion rotation)
		{
			GameObject gm = Program.vm.Instantiate();
			gm.transform.position = position;
			gm.transform.rotation = rotation;
			gm.AddComponent(new RMMesh(0, 0));

			return gm;
		}
		public static GameObject testCube(Vector3 position, Quaternion rotation)
		{
			GameObject gm = Program.vm.Instantiate();
			gm.transform.position = position;
			gm.transform.rotation = rotation;
			gm.AddComponent(new RMMesh(-1, 1));

			return gm;
		}
	}
}
