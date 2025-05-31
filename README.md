# 📹 Raspberry Pi Camera Web Server

A modern, secure web-based camera monitoring system for Raspberry Pi with user authentication, live streaming, and easy sharing capabilities.

## ✨ Features

- 🔐 **Secure Authentication** - Multi-user support with admin/user roles
- 📹 **Live HD Streaming** - Real-time MJPEG camera feed with timestamps
- 📱 **Mobile Responsive** - Modern glassmorphism UI that works on all devices  
- 👥 **Easy Sharing** - Share camera access with family and friends
- ⚙️ **Admin Panel** - User management and system monitoring
- 📸 **Snapshot Capture** - Take and download photos
- 🖥️ **Fullscreen Mode** - Immersive viewing experience

## 🛠️ Hardware Requirements

- Raspberry Pi 3B+ or newer
- Raspberry Pi Camera Module OR USB webcam
- MicroSD card (16GB+)
- Network connection (WiFi/Ethernet)

## 🚀 Quick Installation

### Method 1: Automated Setup (Recommended)

```bash
# Clone the repository
git clone https://github.com/yourusername/pi-camera-server.git
cd pi-camera-server

# Run the installation script
chmod +x setup.sh
./setup.sh
```

### Method 2: Manual Installation

```bash
# Clone repository
git clone https://github.com/yourusername/pi-camera-server.git
cd pi-camera-server

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies  
pip install -r requirements.txt

# Test your camera
python3 scripts/test_camera.py

# Run the server
python3 app.py
```

## 📋 Configuration

### 1. Enable Camera (Pi Camera Module only)
```bash
sudo raspi-config
# Interface Options → Camera → Enable
sudo reboot
```

### 2. First Run
- Access: `http://your-pi-ip:5000`
- Default login: `admin` / `admin123`
- **⚠️ Change default password immediately!**

### 3. Camera Settings
Edit `app.py` to adjust camera settings:
```python
CAMERA_INDEX = 0  # Try 0, 1, or 2 for different cameras
# Resolution: 640x480 (default) or 1280x720 for HD
```

## 🔧 Running as Service

To run automatically on boot:

```bash
# Copy service file
sudo cp config/pi-camera.service /etc/systemd/system/

# Enable and start service
sudo systemctl enable pi-camera.service
sudo systemctl start pi-camera.service

# Check status
sudo systemctl status pi-camera.service
```

## 👥 User Management

### Admin Features:
- Add/remove users
- Assign user roles (admin/user)
- Monitor system status
- View connection statistics

### Sharing with Family:
1. Create user accounts in Admin Panel
2. Share your Pi's IP: `http://your-pi-ip:5000`
3. Users login with their credentials

## 🌐 Remote Access Setup

### Port Forwarding (Router Configuration):
1. Forward port 5000 to your Pi's local IP
2. Access via: `http://your-public-ip:5000`

### Security Recommendations:
- Change default admin password
- Use strong passwords for all users
- Consider VPN access instead of port forwarding
- Regular security updates: `sudo apt update && sudo apt upgrade`

## 🔍 Troubleshooting

### Camera Issues:
```bash
# Test camera
python3 scripts/test_camera.py

# Try different camera index
python3 scripts/test_camera.py 1

# Check camera permissions
sudo usermod -a -G video $USER
```

### Network Issues:
```bash
# Check if port is in use
sudo netstat -tlnp | grep :5000

# Allow through firewall
sudo ufw allow 5000/tcp
```

### Service Issues:
```bash
# View logs
sudo journalctl -u pi-camera -f

# Restart service
sudo systemctl restart pi-camera
```

## 📁 File Structure

```
pi-camera-server/
├── app.py                 # Main Flask application
├── requirements.txt       # Python dependencies
├── setup.sh              # Installation script
├── templates/            # HTML templates
│   ├── dashboard.html    # Main camera view
│   ├── login.html        # Login page
│   └── admin.html        # Admin panel
├── config/               # Configuration files
│   └── pi-camera.service # Systemd service
└── scripts/              # Helper scripts
    ├── test_camera.py    # Camera testing
    └── start_server.sh   # Server startup
```

## 🔐 Security Features

- Bcrypt password hashing
- Session-based authentication  
- Role-based access control
- CSRF protection
- Secure cookie handling

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details.

## 🆘 Support

- **Issues**: Report bugs via GitHub Issues
- **Discussions**: General questions and community support
- **Wiki**: Detailed setup guides and troubleshooting

## 🙏 Acknowledgments

- Flask web framework
- OpenCV for camera handling
- Bootstrap-inspired responsive design
- Raspberry Pi Foundation

---

**⭐ Star this repository if it helped you!**
