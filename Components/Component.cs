using System;
using System.Collections.Generic;
using System.Text;

namespace VMEngine.Components
{
	public abstract class Component
	{
		public GameObject gameObject;
		private bool _isStarted = false;
		public virtual void Start() { 
		}
		public virtual void Update() {
			if (!_isStarted)
			{
				this.Start();
				_isStarted = true;
			}
		}
	}
}
