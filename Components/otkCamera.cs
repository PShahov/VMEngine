﻿using System;

using OpenTK;
using OpenTK.Input;
using OpenTK.Mathematics;
using OpenTK.Windowing.Common;
using OpenTK.Windowing.Desktop;
using OpenTK.Windowing.GraphicsLibraryFramework;

namespace Phantom
{
    public class otkCamera
    {
        protected Vector3 m_position = new Vector3(0, 0, 30);
        protected Vector3 m_up = Vector3.UnitY;
        protected Vector3 m_direction;

        protected const float m_pitchLimit = 1.4f;

        protected const float m_speed = 0.25f;
        protected const float m_mouseSpeedX = 0.0045f;
        protected const float m_mouseSpeedY = 0.0025f;

        protected MouseState m_prevMouse;


        /// <summary>
        /// Creates the instance of the camera.
        /// </summary>
        public otkCamera(GameWindow game)
        {
            // Create the direction vector and normalize it since it will be used for movement
            m_direction = Vector3.Zero - m_position;
            m_direction.Normalize();

            // Create default camera matrices
            Projection = Matrix4.CreatePerspectiveFieldOfView(MathHelper.PiOver4, game.Size.X / (float)game.Size.Y, 0.01f, 1000);
            View = CreateLookAt();
        }


        /// <summary>
        /// Creates the instance of the camera at the given location.
        /// </summary>
        /// <param name="position">Position of the camera.</param>
        /// <param name="target">The target towards which the camera is pointing.</param>
        public otkCamera(GameWindow game, Vector3 position, Vector3 target) : this(game)
        {
            m_position = position;
            m_direction = target - m_position;
            m_direction.Normalize();

            View = CreateLookAt();
        }


        /// <summary>
        /// Handle the camera movement using user input.
        /// </summary>
        protected virtual void ProcessInput()
        {
        }


        /// <summary>
        /// Allows the game component to update itself.
        /// </summary>
        public void Update(FrameEventArgs e)
        {
            // Handle camera movement
            ProcessInput();

            View = CreateLookAt();
        }


        /// <summary>
        /// Create a view (modelview) matrix using camera vectors.
        /// </summary>
        protected Matrix4 CreateLookAt()
        {
            return Matrix4.LookAt(m_position, m_position + m_direction, m_up);
        }


        /// <summary>
        /// Position vector.
        /// </summary>
        public Vector3 Position
        {
            get { return m_position; }
        }

        /// <summary>
        /// Yaw of the camera in radians.
        /// </summary>
        public double Yaw
        {
            get { return Math.PI - Math.Atan2(m_direction.X, m_direction.Z); }
        }

        /// <summary>
        /// Pitch of the camera in radians.
        /// </summary>
        public double Pitch
        {
            get { return Math.Asin(m_direction.Y); }
        }

        /// <summary>
        /// View (modelview) matrix accessor.
        /// </summary>
        public Matrix4 View { get; protected set; }

        /// <summary>
        /// Projection matrix accessor.
        /// </summary>
        public Matrix4 Projection { get; protected set; }

    }
}
