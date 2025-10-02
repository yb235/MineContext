# Getting Started with MineContext

This guide will help you get up and running with MineContext quickly.

## 📦 Installation Methods

### Method 1: Desktop Application (Recommended for Users)

1. **Download the Application**
   - Visit [GitHub Releases](https://github.com/volcengine/MineContext/releases)
   - Download the latest `.dmg` file for macOS
   - Future releases will support Windows and Linux

2. **Install the Application**
   ```bash
   # For macOS, disable quarantine attribute
   sudo xattr -d com.apple.quarantine "/Applications/MineContext.app"
   ```

3. **Launch MineContext**
   - Open the MineContext application
   - Initial startup may take a few minutes as it installs backend dependencies

### Method 2: Backend Installation (For Developers)

1. **Clone the Repository**
   ```bash
   git clone https://github.com/volcengine/MineContext.git
   cd MineContext
   ```

2. **Create Virtual Environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

## 🔑 Initial Configuration

### 1. API Key Setup

MineContext requires an LLM API key for AI features. Currently supported providers:

- **Doubao (ByteDance)** - Recommended for users in China
- **OpenAI** - Global availability

**Desktop App Users:**
- Follow the in-app prompts to enter your API key on first launch

**Backend Users:**
- Create or edit `config/config.yaml` (see [Configuration Guide](./05-configuration-guide.md))

### 2. Basic Configuration File

Create `config/config.yaml` with the following minimal configuration:

```yaml
server:
  host: 127.0.0.1
  port: 8765
  debug: false

# LLM for embeddings
embedding_model:
  provider: doubao  # Options: openai, doubao
  api_key: your-api-key-here
  model: doubao-embedding-large-text-240915

# Vision-Language Model for image analysis
vlm_model:
  provider: doubao  # Options: openai, doubao
  api_key: your-api-key-here
  model: doubao-seed-1-6-flash-250828

# Context capture settings
capture:
  enabled: true
  screenshot:
    enabled: true
    capture_interval: 5  # seconds
```

## 🚀 Running MineContext

### Desktop Application

Simply launch the application from your Applications folder.

### Backend Server

```bash
# Start with default configuration
python -m opencontext.cli start

# Start with custom config
python -m opencontext.cli start --config /path/to/config.yaml

# Start with multiple workers (for production)
python -m opencontext.cli start --workers 4
```

### Access the Web Interface

Once running, open your browser and navigate to:
- Default: `http://localhost:8765`
- Or the host:port specified in your configuration

## 🎮 First Steps

### 1. Enable Screen Recording

1. Navigate to **Screen Monitor** section
2. Enable system permissions for screen sharing
3. Restart the application for changes to take effect

### 2. Configure Capture Area

1. Go to **Settings**
2. Set your preferred screen capture area
3. Adjust capture interval (default: 5 seconds)

### 3. Start Recording

1. Click **Start Recording** in the Screen Monitor
2. MineContext will begin capturing and analyzing your screen

### 4. Explore Features

- **Home**: View daily summaries, todos, and tips
- **Vaults**: Create and manage documents with AI assistance
- **Chat with AI**: Ask questions based on your captured context
- **Settings**: Customize behavior and integrations

## 🔍 Verification

### Check System Health

Visit `http://localhost:8765/health` to verify all components are running:

```json
{
  "status": "healthy",
  "components": {
    "config": true,
    "storage": true,
    "llm": true,
    "capture": true,
    "consumption": true
  }
}
```

### View Logs

**Desktop App:**
- Logs are stored in the application's data directory

**Backend:**
- Logs are output to console by default
- Configure file logging in `config/config.yaml`

## 🆘 Troubleshooting

### Common Issues

**1. Application won't start**
- Check that Python 3.10+ is installed
- Verify all dependencies are installed: `pip install -r requirements.txt`
- Check logs for specific error messages

**2. Screen capture not working**
- Ensure screen recording permissions are granted
- On macOS: System Preferences → Security & Privacy → Screen Recording
- Restart the application after granting permissions

**3. API key errors**
- Verify your API key is correct
- Check that you have sufficient API credits
- Ensure the provider (openai/doubao) matches your key

**4. Storage errors**
- Ensure the data directory is writable
- Check disk space availability
- Verify SQLite is installed

### Getting Help

- **Documentation**: Browse these docs for detailed information
- **GitHub Issues**: Report bugs or request features
- **Community**: Join our Discord or WeChat groups
- **Email**: minecontext@bytedance.com

## 📚 Next Steps

- Read the [User Guide](./02-user-guide.md) for detailed feature information
- Explore [Architecture Overview](./03-architecture-overview.md) to understand the system
- Check [Configuration Guide](./05-configuration-guide.md) for advanced settings
- Review [API Reference](./06-api-reference.md) for integration possibilities

## 🎯 Quick Tips

💡 **Privacy First**: All data is stored locally. No information is sent to external servers except LLM API calls.

💡 **Resource Usage**: Screen capture can be resource-intensive. Adjust the capture interval based on your needs.

💡 **Storage Management**: MineContext automatically manages storage, but monitor disk space for large datasets.

💡 **API Costs**: Be mindful of API usage. Configure capture intervals and processing settings to control costs.
