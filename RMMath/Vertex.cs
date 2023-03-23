using OpenTK.Mathematics;
using System;
using System.Collections.Generic;
using System.Text;

namespace VMEngine
{
	public readonly struct VertexAttribute
	{
		public readonly string name;
		public readonly int index;
		public readonly int count;
		public readonly int offset;

		public VertexAttribute(string name, int index, int count, int offset)
		{
			this.name = name;
			this.index = index;
			this.count = count;
			this.offset = offset;
		}
	}
	public sealed class VertexInfo
	{
		public readonly Type type;
		public readonly int size;
		public readonly VertexAttribute[] attributes;

		public VertexInfo(Type type, params VertexAttribute[] attributes)
		{
			this.type = type;
			this.size = 0;
			this.attributes = attributes;

			for (int i = 0; i < attributes.Length; i++)
			{
				this.size += attributes[i].count * sizeof(float);
			}
		}
	}
	public struct Vertex
	{

		//public const int Size = (4 + 4) * sizeof(float); // size of struct in bytes

		public Vector3 position;
		public Color4 color;
		public Vector3 normal;

		public static readonly VertexInfo Info = new VertexInfo(
			typeof(Vertex),
			new VertexAttribute("Position", 0, 3, 0),
			new VertexAttribute("Color", 1, 4, 3 * sizeof(float)),
			new VertexAttribute("Normal", 2, 3, 7 * sizeof(float))
			);

		public Vertex(Vector3 position, Color4 color, Vector3 normal)
		{
			this.position = position;
			this.color = color;
			this.normal = normal;
			//this.info = info;
		}
	}

}
