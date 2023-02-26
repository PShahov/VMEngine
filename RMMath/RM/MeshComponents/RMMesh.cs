using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace VMEngine.RMMath.RM.MeshComponents
{
	class RMMesh : RMMeshComponent
	{
		public RMMesh(int MaterialId, int MeshId)
		{
			this.MaterialId = MaterialId;
			this.MeshId = MeshId;
		}
		public RMMesh(int MaterialId, int MeshId, Vector3 offset)
		{
			this.MaterialId = MaterialId;
			this.MeshId = MeshId;
			this.localPosition = offset;
		}
		public RMMesh(int MaterialId, int MeshId, Vector3 offset, Quaternion rotation)
		{
			this.MaterialId = MaterialId;
			this.MeshId = MeshId;
			this.localPosition = offset;
			this.localRotation = rotation;
		}

		public override void Update()
		{
			base.Update();
			//this.localRotation = Quaternion.FromEulers(new Vector3(1,0.5f,-0.5f), 180 * Time.deltaTime) * this.localRotation;
		}
	}
}
