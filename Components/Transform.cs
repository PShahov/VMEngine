using System;
using System.Collections.Generic;
using System.Text;

namespace VMEngine.Components
{
	public class Transform
	{
		public Vector3 position
		{
			get
			{
				return _position;
			}
			set
			{
				_position = value;
				for(int i = 0;i < _childList.Count; i++)
				{
					_childList[i].position = _position + _childList[i].localPosition;
				}
			}
		}
		public Vector3 localPosition
		{
			get
			{
				return _localPosition;
			}
			set
			{
				_localPosition = value;
				if(_parent != null)
				{
					position = parent.position + localPosition;
				}
			}
		}
		public Quaternion rotation
		{
			get
			{
				if(parent != null)
				{
					return _rotation + parent.rotation;
				}
				return _rotation;
			}
			set
			{
				Quaternion q = _rotation - value;
				_rotation = value;
				for (int i = 0; i < _childList.Count; i++)
				{
					_childList[i].RotateAround(position, q);
				}

			}
		}
		public Quaternion localRotation
		{
			get
			{
				return _localRotation;
			}
			set
			{
				_localRotation = value;
				if (_parent != null)
				{
					rotation = _localRotation * parent.rotation;
				}
			}
		}

		public Vector3 scale
		{
			get
			{
				return _scale;
			}
			set
			{
				_scale = value;
				for (int i = 0; i < _childList.Count; i++)
				{
					_childList[i].scale = _scale + _childList[i].localScale;
				}
			}
		}
		public Vector3 localScale
		{
			get
			{
				return _localScale;
			}
			set
			{
				_localScale = value;
				if (_parent != null)
				{
					scale = parent._scale + localScale;
				}
			}
		}


		private Vector3 _position = Vector3.zero;
		private Vector3 _localPosition = Vector3.zero;
		private Quaternion _rotation = Quaternion.identity;
		private Quaternion _localRotation = Quaternion.identity;
		private Vector3 _scale = Vector3.one;
		private Vector3 _localScale = Vector3.one;

		private List<Transform> _childList = new List<Transform>();
		public Transform parent
		{
			get
			{
				return _parent;
			}
			set
			{
				if (value != null)
				{
					localPosition = position - value.position;
					_parent = value;
					_childList.Add(value);
				}
				else
				{
					localPosition = Vector3.zero;
					_childList.Remove(_parent);
					_parent = null;
				}
			}
		}
		private Transform _parent;

		public Transform(Transform parent = null)
		{
			this.parent = parent;
		}

		public void RotateAround(Vector3 point, Quaternion rotation)
		{
			this.position = rotation * (this.position - point) + point;
			this.rotation = rotation * this.rotation;
		}
	}
}
