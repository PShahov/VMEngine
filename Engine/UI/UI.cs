using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace VMEngine.Engine.UI
{
	public class RectTransform
	{
		public RectTransform Parent;
		private RectTransform[] Children = new RectTransform[8];
		private int _childrenCount = 0;

		public void AppendChild(RectTransform child)
		{
			if(_childrenCount >= Children.Length)
			{
				Array.Resize(ref Children, Children.Length + 8);
			}

			for(int i = 0; i < Children.Length; i++)
			{

			}
		}
	}
	//abstract class UIO
	//{
	//	public 
	//}
}
