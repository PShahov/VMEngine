using System;
using System.Collections.Generic;
using System.Text;

using VMEngine.Components;

namespace VMEngine.RMMath.RM
{
	public abstract class RMMeshComponent: Component
	{
		public int MaterialId = 0;
		public int MeshId = 0;
		public int MeshType = 0;

		public Vector3 localPosition = Vector3.zero;
		public Quaternion localRotation = Quaternion.identity;
		public Vector3 localScale = Vector3.one;
		

		public RMMeshComponent()
		{
			Program.vm._rmPoolAdd(this);
		}

		public float[] ToArray()
		{
			List<float> list = new List<float>
			{
				this.MeshType,//0
				this.MaterialId,//1
				this.MeshId//2
			};
			list.AddRange((localPosition + gameObject.transform.position).ToArray());//3,4,5
			list.AddRange((localRotation + gameObject.transform.rotation).ToArray());//6,7,8,9
			list.AddRange((localScale + gameObject.transform.scale).ToArray());//10,11,12
			return list.ToArray();// 1 + 1 + 1 + 3 + 4 + 3 = 13
		}
	}
}
