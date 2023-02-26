using System;
using System.Collections.Generic;
using System.Text;

namespace VMEngine.Components
{

	public class GameObject
	{
		public List<Component> components = new List<Component>();

		public Transform transform = new Transform();

		public T GetComponent<T>()
		{
			for (int i = 0; i < components.Count; i++)
			{

				if (components[i].GetType() == typeof(T))
				{
					return (T)Convert.ChangeType(components[i], typeof(T));
				}
			}

			return default(T);
		}
		public Component AddComponent(Component component)
		{
			component.gameObject = this;
			components.Add(component);
			return component;
		}

		public virtual void Start() { }
		public virtual void Update() { }

	}
}
