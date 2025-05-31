#!/usr/bin/env python3
"""
Raspberry Pi Camera Web Server
A Flask-based web server for streaming camera feed with authentication
"""

from flask import Flask, render_template, Response, request, redirect, url_for, session, flash
from flask_bcrypt import Bcrypt
import cv2
import threading
import time
import json
import os
from datetime import datetime

app = Flask(__name__)
app.secret_key = 'your-secret-key-change-this'  # Change this!
bcrypt = Bcrypt(app)

# Configuration
USERS_FILE = 'users.json'
CAMERA_INDEX = 0  # 0 for USB camera, adjust as needed

# Global camera object
camera = None
camera_lock = threading.Lock()

class CameraStream:
    def __init__(self):
        self.camera = cv2.VideoCapture(CAMERA_INDEX)
        self.camera.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
        self.camera.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        self.camera.set(cv2.CAP_PROP_FPS, 30)
        
    def __del__(self):
        if self.camera:
            self.camera.release()
    
    def get_frame(self):
        success, frame = self.camera.read()
        if not success:
            return None
        
        # Add timestamp
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        cv2.putText(frame, timestamp, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
        
        # Encode frame as JPEG
        ret, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 85])
        return buffer.tobytes()

def load_users():
    """Load users from JSON file"""
    if os.path.exists(USERS_FILE):
        with open(USERS_FILE, 'r') as f:
            return json.load(f)
    return {}

def save_users(users):
    """Save users to JSON file"""
    with open(USERS_FILE, 'w') as f:
        json.dump(users, f, indent=2)

def init_default_user():
    """Create default admin user if no users exist"""
    users = load_users()
    if not users:
        # Default admin user - change these credentials!
        default_password = bcrypt.generate_password_hash('admin123').decode('utf-8')
        users['admin'] = {
            'password': default_password,
            'role': 'admin'
        }
        save_users(users)
        print("Default admin user created - Username: admin, Password: admin123")
        print("Please change these credentials immediately!")

def generate_frames():
    """Generate camera frames for streaming"""
    global camera
    
    while True:
        with camera_lock:
            if camera is None:
                camera = CameraStream()
        
        frame = camera.get_frame()
        if frame is not None:
            yield (b'--frame\r\n'
                   b'Content-Type: image/jpeg\r\n\r\n' + frame + b'\r\n')
        else:
            time.sleep(0.1)

@app.route('/')
def index():
    """Main dashboard page"""
    if 'username' not in session:
        return redirect(url_for('login'))
    
    return render_template('dashboard.html', username=session['username'])

@app.route('/login', methods=['GET', 'POST'])
def login():
    """User login page"""
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        users = load_users()
        
        if username in users and bcrypt.check_password_hash(users[username]['password'], password):
            session['username'] = username
            session['role'] = users[username]['role']
            return redirect(url_for('index'))
        else:
            flash('Invalid username or password')
    
    return render_template('login.html')

@app.route('/logout')
def logout():
    """User logout"""
    session.clear()
    return redirect(url_for('login'))

@app.route('/video_feed')
def video_feed():
    """Video streaming route"""
    if 'username' not in session:
        return redirect(url_for('login'))
    
    return Response(generate_frames(),
                    mimetype='multipart/x-mixed-replace; boundary=frame')

@app.route('/admin')
def admin():
    """Admin panel for user management"""
    if 'username' not in session or session.get('role') != 'admin':
        flash('Admin access required')
        return redirect(url_for('index'))
    
    users = load_users()
    return render_template('admin.html', users=users)

@app.route('/add_user', methods=['POST'])
def add_user():
    """Add new user (admin only)"""
    if 'username' not in session or session.get('role') != 'admin':
        return redirect(url_for('index'))
    
    username = request.form['username']
    password = request.form['password']
    role = request.form.get('role', 'user')
    
    users = load_users()
    
    if username in users:
        flash('User already exists')
    else:
        hashed_password = bcrypt.generate_password_hash(password).decode('utf-8')
        users[username] = {
            'password': hashed_password,
            'role': role
        }
        save_users(users)
        flash(f'User {username} added successfully')
    
    return redirect(url_for('admin'))

@app.route('/delete_user/<username>')
def delete_user(username):
    """Delete user (admin only)"""
    if 'username' not in session or session.get('role') != 'admin':
        return redirect(url_for('index'))
    
    if username == session['username']:
        flash('Cannot delete yourself')
        return redirect(url_for('admin'))
    
    users = load_users()
    if username in users:
        del users[username]
        save_users(users)
        flash(f'User {username} deleted successfully')
    
    return redirect(url_for('admin'))

if __name__ == '__main__':
    # Create templates directory
    os.makedirs('templates', exist_ok=True)
    
    # Initialize default user
    init_default_user()
    
    print("Starting Raspberry Pi Camera Server...")
    print("Access the server at: http://your-pi-ip:5000")
    print("Default login - Username: admin, Password: admin123")
    
    # Run Flask app
    app.run(host='0.0.0.0', port=5000, debug=False, threaded=True)