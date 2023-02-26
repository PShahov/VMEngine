using OpenTK.Graphics.OpenGL;
using System;
using System.Collections.Generic;
using System.Text;

namespace VMEngine
{
	public static class VMHelper
	{
		public static class Meshes
		{
            public static void DrawBox(float size, Vector3 position)
            {
                float[,] n = new float[,]{
                    {-1.0f, 0.0f, 0.0f},
                    {0.0f, 1.0f, 0.0f},
                    {1.0f, 0.0f, 0.0f},
                    {0.0f, -1.0f, 0.0f},
                    {0.0f, 0.0f, 1.0f},
                    {0.0f, 0.0f, -1.0f}
                };
                int[,] faces = new int[,]{
                    {0, 1, 2, 3},
                    {3, 2, 6, 7},
                    {7, 6, 5, 4},
                    {4, 5, 1, 0},
                    {5, 6, 2, 1},
                    {7, 4, 0, 3}
                };
                float[,] v = new float[8, 3];
                int i;

                v[0, 0] = v[1, 0] = v[2, 0] = v[3, 0] = -size / 2;
                v[4, 0] = v[5, 0] = v[6, 0] = v[7, 0] = size / 2;
                v[0, 1] = v[1, 1] = v[4, 1] = v[5, 1] = -size / 2;
                v[2, 1] = v[3, 1] = v[6, 1] = v[7, 1] = size / 2;
                v[0, 2] = v[3, 2] = v[4, 2] = v[7, 2] = -size / 2;
                v[1, 2] = v[2, 2] = v[5, 2] = v[6, 2] = size / 2;

                for(i = 0;i < 6; i++)
                {
                    v[0, 0] += position.x;
                    v[0, 1] += position.y;
                    v[0, 2] += position.z;
                }

                GL.Begin(PrimitiveType.Quads);
                for (i = 5; i >= 0; i--)
                {
                    GL.Normal3(ref n[i, 0]);
                    GL.Vertex3(ref v[faces[i, 0], 0]);
                    GL.Vertex3(ref v[faces[i, 1], 0]);
                    GL.Vertex3(ref v[faces[i, 2], 0]);
                    GL.Vertex3(ref v[faces[i, 3], 0]);
                }
                GL.End();
            }
        }

	}
}
