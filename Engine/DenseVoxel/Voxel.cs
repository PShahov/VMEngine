using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace VMEngine.Engine.DenseVoxel
{

	public enum VoxelState
	{
		Filled = 0,
		Fullfilled = 1,
		Surrounded = 2
	}

	public enum VoxelDiagonalDirections
	{
		LTF = 0,
		RTF = 1,
		RTN = 2,
		LTN = 3,
		LBF = 4,
		RBF = 5,
		RBN = 6,
		LBN = 7
	}


	public class Voxel
	{
		public static int FloatCount = 5;
		public float[] InitialColor = new float[4];
		public float[] CurrentColor = new float[4];

		public bool Filled { get { return this.GetState(VoxelState.Filled); } set { this.SetState(VoxelState.Filled, value); } }
		public bool Fullfilled { get { return this.GetState(VoxelState.Fullfilled); } set { this.SetState(VoxelState.Fullfilled, value); } }
		public bool Surrounded { get { return this.GetState(VoxelState.Surrounded); } set { this.SetState(VoxelState.Surrounded, value); } }

		//VoxelColor Color;
		public byte Id;
		public byte State = 0b0000_0001;

		public Voxel(float[] color, byte blockId, byte state)
		{
			InitialColor = color;
			CurrentColor = color;
			Id = blockId;
			State = state;
		}

		public void SetState(VoxelState pos, bool value)
		{
			SetState((int)pos, value);
		}
		public bool GetState(VoxelState pos)
		{
			return GetState((int)pos);
		}

		public void SetState(int pos, bool value)
		{
			if (value)
			{
				State = (byte)(State | 1 << pos);
			}
			else
			{
				State = (byte)(State & ~(1 << pos));
			}
		}
		public bool GetState(int pos)
		{
			return (State & 1 << pos) != 0;
		}

		public static byte CreateState(params VoxelState[] args)
		{
			byte state = 0;
			for (int i = 0; i < args.Length; i++)
			{
				state = (byte)(state | 1 << (int)args[i]);
			}
			return state;
		}
		public static byte CreateState(params int[] args)
		{
			byte state = 0;
			for (int i = 0; i < args.Length; i++)
			{
				state = (byte)(state | 1 << args[i]);
			}
			return state;
		}
	}
}
