using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace VMEngine.Engine
{
    public static class Raymarching
    {
        public static float fBox(Vector3 p, Vector3 b)
        {
            Vector3 d = p.Abs() - b;
            return Vector3.SqrMagnitude(Vector3.VMax(d, new Vector3(0)) + Vector3.VMax(Vector3.VMin(d, new Vector3(0))));
        }
    }
}
