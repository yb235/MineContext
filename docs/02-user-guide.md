# User Guide

This comprehensive guide covers all features and functionality of MineContext for end users.

## 🏠 Home Dashboard

The Home dashboard is your central hub where MineContext proactively delivers daily insights.

### Daily Summary

**What it is:** An AI-generated summary of your daily activities and accomplishments.

**When it updates:** Every day at 8 PM (configurable)

**What you can do:**
- View your daily activities timeline
- See highlights and key accomplishments
- Track productivity patterns
- Export summaries for personal records

### Todo List

**What it is:** Automatically extracted tasks from your captured contexts.

**Features:**
- Auto-detected from screenshots and documents
- Mark complete/incomplete
- Edit or delete tasks
- Add manual todos
- Priority levels

**How it works:**
1. MineContext analyzes your captured content
2. Identifies actionable items and deadlines
3. Creates todo entries automatically
4. You review and manage the list

### Tips & Insights

**What it is:** AI-generated insights about your work patterns and habits.

**Examples:**
- "You're most productive between 9-11 AM"
- "You've been focusing on AI projects this week"
- "Consider taking breaks every 90 minutes"

### Weekly Summary

**What it is:** A comprehensive overview of your week's activities.

**Generated:** Every Sunday at 8 PM

**Includes:**
- Major accomplishments
- Time spent on different activities
- Projects worked on
- Suggested improvements

## 📸 Screen Monitor

The Screen Monitor captures and analyzes your screen activity.

### Starting Screen Capture

1. Navigate to **Screen Monitor** section
2. Grant system permissions (first time only)
   - macOS: System Preferences → Security & Privacy → Screen Recording
   - Restart application after granting permission
3. Configure capture settings in **Settings**
4. Click **Start Recording**

### Configuring Capture

**Capture Interval:**
- Default: 5 seconds
- Range: 1-60 seconds
- Recommendation: 5-10 seconds for balance

**Capture Area:**
- Full screen (all monitors)
- Specific monitor
- Custom region

**Privacy Settings:**
- Exclude specific applications
- Pause capture manually
- Clear captured data

### Viewing Captured Screenshots

1. Navigate to **Screen Monitor → Activity**
2. Browse by date/time
3. Click any screenshot to view details
4. See AI-generated descriptions
5. Search within screenshots

### Understanding Activity Analysis

Each screenshot is analyzed to extract:
- **Description:** What was happening
- **Application:** Which app was active
- **Content:** Extracted text
- **Context Type:** Work, leisure, meeting, etc.
- **Entities:** Mentioned people, projects, topics

## 📝 Vaults (Document Management)

Vaults is where you create, organize, and interact with documents.

### Creating Documents

**Method 1: From scratch**
1. Click **New Document** button
2. Enter a title
3. Start writing in the editor
4. Auto-saves every few seconds

**Method 2: From template**
1. Click **New from Template**
2. Choose a template (notes, meeting, project)
3. Customize the content

**Method 3: Upload**
1. Click **Upload** button
2. Select file (Markdown, Text, PDF)
3. Document is processed and stored

### Document Editor

**Features:**
- Markdown support with live preview
- AI-powered smart completion
- Rich text formatting
- Code block support
- Image embedding
- Table creation

**Keyboard Shortcuts:**
- `Ctrl/Cmd + S`: Save
- `Ctrl/Cmd + B`: Bold
- `Ctrl/Cmd + I`: Italic
- `Ctrl/Cmd + K`: Insert link
- `Tab`: Accept completion

### Smart Completion

As you type, MineContext suggests relevant completions based on:
- Your captured context
- Current document content
- Recent activities
- Similar documents

**Using completions:**
1. Start typing
2. Wait for suggestion (or press `Ctrl+Space`)
3. Press `Tab` to accept
4. Press `Esc` to dismiss

### Document Organization

**Folders:**
- Create nested folder structures
- Drag and drop to organize
- Color-code folders

**Tags:**
- Add multiple tags to documents
- Auto-suggested based on content
- Filter by tags

**Search:**
- Full-text search
- Search by date range
- Filter by document type
- Semantic search ("similar to this")

## 💬 Chat with AI

Interact with MineContext's AI agent to get answers and accomplish tasks.

### Starting a Conversation

1. Navigate to **Chat** section
2. Type your message
3. Press Enter or click Send

### What You Can Ask

**Information Retrieval:**
- "What did I work on yesterday?"
- "Find documents about machine learning"
- "Show me my meetings this week"

**Content Creation:**
- "Write a summary of today's activities"
- "Create a todo list from recent screenshots"
- "Draft an email about the project update"

**Analysis:**
- "What are my productivity patterns?"
- "How much time did I spend on coding?"
- "What topics have I been researching?"

**Operations:**
- "Create a new document about [topic]"
- "Update my todo list"
- "Schedule a summary for tomorrow"

### Confirmation Mode

For important actions, the AI will ask for confirmation:

```
AI: I'll create a todo list with 5 items:
1. Complete project documentation
2. Review pull requests
3. ...

[Approve] [Reject]
```

### Contextual Chat

**Using selected content:**
1. Select text in any document
2. Right-click → "Chat about this"
3. Ask questions about the selection

**Using document context:**
- Open a document
- Chat references the document automatically
- Ask specific questions about the content

## ⚙️ Settings

### General Settings

**Language:**
- English / Chinese
- Affects UI and prompts

**Theme:**
- Light / Dark / Auto
- Follows system theme

**Startup:**
- Launch on startup
- Start capture automatically
- Minimize to tray

### Capture Settings

**Screenshots:**
- Enable/disable capture
- Capture interval (seconds)
- Image quality
- Monitor selection
- Excluded applications

**Documents:**
- Watch folders
- File types to monitor
- Scan interval

### AI Settings

**Model Selection:**
- Embedding model
- Vision model
- Language model

**API Keys:**
- OpenAI key
- Doubao key
- Custom endpoints

**Behavior:**
- Temperature (creativity)
- Max tokens (length)
- Response style

### Privacy Settings

**Content Filtering:**
- Filter passwords automatically
- Filter credit card numbers
- Custom filter patterns

**Data Retention:**
- Screenshot retention period
- Context retention period
- Auto-delete old data

**Exclusions:**
- Excluded applications
- Excluded file types
- Private folders

### Storage Settings

**Database Location:**
- Change data directory
- View storage usage
- Clear cache

**Backup:**
- Auto-backup schedule
- Backup location
- Restore from backup

### Performance Settings

**Processing:**
- Thread pool size
- Batch size
- Cache size

**Resource Limits:**
- Max memory usage
- CPU priority
- Disk space limits

## 🔍 Search

### Basic Search

1. Use the search bar at the top
2. Type your query
3. Results appear instantly
4. Click result to open

### Advanced Search

**Filters:**
- Date range
- Content type (Screenshot, Document, Note)
- Tags
- Importance level

**Search Operators:**
- `"exact phrase"` - Match exact phrase
- `tag:work` - Filter by tag
- `type:document` - Filter by type
- `date:2025-01-01` - Specific date

**Semantic Search:**
- Understands meaning, not just keywords
- "machine learning articles" finds ML content
- Works with natural language queries

### Search Results

**Result Cards:**
- Title and summary
- Relevance score
- Creation date
- Context type
- Quick preview

**Actions:**
- Open in editor
- Copy to clipboard
- Add to collection
- Delete

## 📊 Analytics

### Activity Dashboard

**Time Tracking:**
- Hours per day/week/month
- Activity by application
- Activity by project/topic

**Productivity Insights:**
- Most productive hours
- Focus time vs. distraction
- Work patterns

**Content Analysis:**
- Most discussed topics
- Frequently used tools
- Collaboration patterns

### Reports

**Daily Report:**
- Activities summary
- Top applications
- Key accomplishments

**Weekly Report:**
- Weekly overview
- Project progress
- Time distribution

**Monthly Report:**
- Monthly summary
- Trends and patterns
- Goal tracking

## 🔔 Notifications

### Types of Notifications

**Generation Complete:**
- Daily summary ready
- Weekly summary ready
- Todo list updated

**Reminders:**
- Scheduled tasks
- Upcoming deadlines
- System updates

**Alerts:**
- Low disk space
- API errors
- Permission issues

### Notification Settings

**Enable/Disable:**
- Toggle by type
- Quiet hours
- Do Not Disturb mode

**Delivery:**
- Desktop notifications
- In-app only
- Email (if configured)

## 💡 Tips & Best Practices

### Getting the Most Out of MineContext

1. **Let it run in the background**
   - MineContext works best with continuous capture
   - The more data, the better the insights

2. **Review daily summaries**
   - Check your daily summary each evening
   - Helps track progress and plan tomorrow

3. **Use tags consistently**
   - Tag documents with projects
   - Makes search more effective

4. **Configure privacy settings**
   - Exclude sensitive applications
   - Review privacy filters

5. **Leverage smart completion**
   - Let AI assist with repetitive text
   - Accept suggestions to improve learning

6. **Ask specific questions**
   - Be specific in chat queries
   - Reference time ranges and topics

### Common Workflows

**Research Project:**
1. Capture screens while researching
2. Create document with findings
3. Use chat to summarize key points
4. Generate todo list for next steps

**Meeting Notes:**
1. Capture meeting screens
2. Create meeting notes document
3. Extract action items automatically
4. Share summary with team

**Content Creation:**
1. Research topic (captured automatically)
2. Create new document
3. Use smart completion for drafting
4. Review and refine with AI assistance

## 🆘 Troubleshooting

### Common Issues

**Screenshots not capturing:**
- Check permissions in System Settings
- Verify capture is enabled in Settings
- Check excluded applications list
- Restart application

**AI not responding:**
- Check API key is valid
- Verify internet connection
- Check API credits/limits
- Review error logs

**Slow performance:**
- Increase capture interval
- Clear cache in Settings
- Close unused documents
- Check disk space

**Search not finding content:**
- Wait for processing to complete
- Check search filters
- Verify content was captured
- Try semantic search

### Getting Help

**In-App Help:**
- Help menu → Documentation
- Tooltips and hints throughout UI

**Community Support:**
- Discord community
- GitHub issues
- WeChat/Lark groups

**Email Support:**
- minecontext@bytedance.com
- Include log files for technical issues

## 📚 Keyboard Shortcuts

### Global

- `Ctrl/Cmd + ,` - Open Settings
- `Ctrl/Cmd + K` - Quick search
- `Ctrl/Cmd + N` - New document
- `Ctrl/Cmd + T` - New chat
- `Ctrl/Cmd + H` - Go to Home

### Editor

- `Ctrl/Cmd + S` - Save document
- `Ctrl/Cmd + B` - Bold text
- `Ctrl/Cmd + I` - Italic text
- `Ctrl/Cmd + U` - Underline
- `Ctrl/Cmd + K` - Insert link
- `Tab` - Accept completion
- `Esc` - Dismiss completion

### Chat

- `Enter` - Send message
- `Shift + Enter` - New line
- `Ctrl/Cmd + L` - Clear chat
- `↑` - Previous message
- `↓` - Next message

## 🎓 Learning Resources

- [Getting Started Guide](./01-getting-started.md) - Initial setup
- [Configuration Guide](./05-configuration-guide.md) - Advanced settings
- [API Reference](./06-api-reference.md) - For integrations
- [GitHub Repository](https://github.com/volcengine/MineContext) - Source code

## 🔄 Updates

**Checking for updates:**
- Help → Check for Updates
- Auto-update notification

**Release notes:**
- View in Help → What's New
- GitHub releases page

## 📞 Contact & Support

- **Email:** minecontext@bytedance.com
- **Discord:** [Join our community](https://discord.gg/tGj7RQ3nUR)
- **GitHub Issues:** Report bugs and feature requests
- **Documentation:** Full technical documentation available
