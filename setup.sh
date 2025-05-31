#!/bin/bash

# Raspberry Pi Camera Web Server Setup Script
# Automated installation and configuration

set -e  # Exit on any error

echo "🔧 Raspberry Pi Camera Web Server Setup"
echo "======================================"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if running on Raspberry Pi
check_raspberry_pi() {
    if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
        print_warning "This doesn't appear to be a Raspberry Pi. Continuing anyway..."
    fi
}

# Update system packages
update_system() {
    print_step "Updating system packages..."
    sudo apt update
    sudo apt upgrade -y
    print_status "System updated successfully"
}

# Install required packages
install_dependencies() {
    print_step "Installing required packages..."
    
    # Essential packages
    sudo apt install -y \
        python3-pip \
        python3-venv \
        python3-dev \
        git \
        cmake \
        pkg-config \
        libjpeg-dev \
        libpng-dev \
        libtiff-dev \
        libavcodec-dev \
        libavformat-dev \
        libswscale-dev \
        libv4l-dev \
        libxvidcore-dev \
        libx264-dev \
        libgtk-3-dev \
        libatlas-base-dev \
        gfortran
    
    print_status "Dependencies installed successfully"
}

# Set up project directory
setup_project() {
    print_step "Setting up project directory..."
    
    PROJECT_DIR="$HOME/pi-camera-server"
    
    # Remove existing directory if it exists
    if [ -d "$PROJECT_DIR" ]; then
        print_warning "Existing project directory found. Backing up..."
        mv "$PROJECT_DIR" "${PROJECT_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # If we're already in the cloned directory, use current directory
    if [ -f "$(pwd)/app.py" ]; then
        PROJECT_DIR="$(pwd)"
        print_status "Using current directory: $PROJECT_DIR"
    else
        mkdir -p "$PROJECT_DIR"
        cd "$PROJECT_DIR"
        print_status "Created project directory: $PROJECT_DIR"
    fi
    
    echo "PROJECT_DIR=$PROJECT_DIR" > ~/.pi-camera-config
}

# Create Python virtual environment
setup_python_env() {
    print_step "Setting up Python virtual environment..."
    
    # Create virtual environment
    python3 -m venv venv
    source venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install Python packages
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
    else
        pip install flask flask-bcrypt opencv-python
    fi
    
    print_status "Python environment set up successfully"
}

# Test camera functionality
test_camera() {
    print_step "Testing camera functionality..."
    
    # Create test script if it doesn't exist
    if [ ! -f "scripts/test_camera.py" ]; then
        mkdir -p scripts
        cat > scripts/test_camera.py << 'EOF'
#!/usr/bin/env python3
import cv2
import sys

def test_camera(camera_index=0):
    print(f"Testing camera at index {camera_index}...")
    cap = cv2.VideoCapture(camera_index)
    
    if not cap.isOpened():
        print(f"❌ Cannot open camera at index {camera_index}")
        return False
    
    ret, frame = cap.read()
    if ret:
        height, width = frame.shape[:2]
        print(f"✅ Camera working! Resolution: {width}x{height}")
        cap.release()
        return True
    else:
        print(f"❌ Cannot read from camera at index {camera_index}")
        cap.release()
        return False

if __name__ == "__main__":
    camera_index = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    test_camera(camera_index)
EOF
        chmod +x scripts/test_camera.py
    fi
    
    # Test camera
    source venv/bin/activate
    if python3 scripts/test_camera.py; then
        print_status "Camera test passed!"
    else
        print_warning "Camera test failed. You may need to:"
        echo "  - Enable camera in raspi-config (for Pi Camera)"
        echo "  - Check USB camera connection"
        echo "  - Try different camera index (0, 1, 2)"
        echo "  - Add user to video group: sudo usermod -a -G video \$USER"
    fi
}

# Create systemd service
setup_service() {
    print_step "Setting up systemd service..."
    
    # Create service file if it doesn't exist
    if [ ! -f "config/pi-camera.service" ]; then
        mkdir -p config
        cat > config/pi-camera.service << EOF
[Unit]
Description=Pi Camera Web Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$PROJECT_DIR
Environment=PATH=$PROJECT_DIR/venv/bin
ExecStart=$PROJECT_DIR/venv/bin/python app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    fi
    
    # Install service
    sudo cp config/pi-camera.service /etc/systemd/system/
    sudo systemctl daemon-reload
    
    print_status "Systemd service created"
}

# Configure firewall
setup_firewall() {
    print_step "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        sudo ufw allow 5000/tcp
        print_status "Firewall configured (port 5000 opened)"
    else
        print_warning "UFW not installed. Port 5000 may need manual firewall configuration"
    fi
}

# Create startup script
create_startup_script() {
    print_step "Creating startup scripts..."
    
    mkdir -p scripts
    
    # Start server script
    cat > scripts/start_server.sh << EOF
#!/bin/bash
cd "$PROJECT_DIR"
source venv/bin/activate
python3 app.py
EOF
    chmod +x scripts/start_server.sh
    
    # Service management script
    cat > scripts/manage_service.sh << 'EOF'
#!/bin/bash

case "$1" in
    start)
        sudo systemctl start pi-camera
        echo "Service started"
        ;;
    stop)
        sudo systemctl stop pi-camera
        echo "Service stopped"
        ;;
    restart)
        sudo systemctl restart pi-camera
        echo "Service restarted"
        ;;
    status)
        sudo systemctl status pi-camera
        ;;
    enable)
        sudo systemctl enable pi-camera
        echo "Service enabled (will start on boot)"
        ;;
    disable)
        sudo systemctl disable pi-camera
        echo "Service disabled"
        ;;
    logs)
        sudo journalctl -u pi-camera -f
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|enable|disable|logs}"
        exit 1
        ;;
esac
EOF
    chmod +x scripts/manage_service.sh
    
    print_status "Startup scripts created"
}

# Get system information
get_system_info() {
    PI_IP=$(hostname -I | awk '{print $1}')
    HOSTNAME=$(hostname)
    
    echo ""
    echo "🎉 Installation Complete!"
    echo "========================"
    echo ""
    echo "📋 System Information:"
    echo "   Hostname: $HOSTNAME"
    echo "   IP Address: $PI_IP"
    echo "   Project Directory: $PROJECT_DIR"
    echo ""
    echo "🚀 Next Steps:"
    echo "1. Start the server:"
    echo "   cd $PROJECT_DIR"
    echo "   ./scripts/start_server.sh"
    echo ""
    echo "2. Or install as service:"
    echo "   ./scripts/manage_service.sh enable"
    echo "   ./scripts/manage_service.sh start"
    echo ""
    echo "3. Access your camera server:"
    echo "   🌐 http://$PI_IP:5000"
    echo "   👤 Username: admin"
    echo "   🔑 Password: admin123"
    echo ""
    echo "⚠️  IMPORTANT: Change the default admin password!"
    echo ""
    echo "🔧 Useful Commands:"
    echo "   Service management: ./scripts/manage_service.sh [start|stop|restart|status]"
    echo "   View logs: ./scripts/manage_service.sh logs"
    echo "   Test camera: ./scripts/test_camera.py"
    echo ""
    echo "📚 Documentation: Check README.md for detailed usage instructions"
}

# Main installation process
main() {
    print_status "Starting Raspberry Pi Camera Web Server installation..."
    
    check_raspberry_pi
    update_system
    install_dependencies
    setup_project
    setup_python_env
    test_camera
    setup_service
    setup_firewall
    create_startup_script
    get_system_info
    
    print_status "Setup completed successfully! 🎉"
}

# Run main function
main "$@"