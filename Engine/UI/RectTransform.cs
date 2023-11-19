using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace VMEngine.Engine.UI
{
	public enum UIMeasure
	{
		Pixels, AbsolutePercent, RelativePercent
	}
	public class RectTransform
	{
		public Vector3 Position;
		public Vector3 Rotation;
		public Vector3 Size;
		public Vector3 Scale;

		public UIMeasure Measure;


		public RectTransform Parent;
		private RectTransform[] Children = new RectTransform[8];
		private int _childrenCount = 0;

		public RectTransform(Vector3 position, Vector3 size, UIMeasure measure)
		{
			Position= position;
			Size= size;
			Measure= measure;
		}
		public void AppendChild(RectTransform child)
		{
			if (_childrenCount >= Children.Length)
			{
				Array.Resize(ref Children, Children.Length + 8);
			}

			for (int i = 0; i < Children.Length; i++)
			{

			}
		}
	}


}
