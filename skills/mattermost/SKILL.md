---
name: mattermost
description: Mattermost API, message formatting, slash commands, webhooks, and bot development
trigger: mattermost, channel, message, webhook, slash command, bot, team, user management, mattermost API
---

# Mattermost

## API Basics

Base URL: `https://<server>/api/v4`

Authentication: `Authorization: Bearer <token>` (bot token or personal access token)

```bash
# Get current user
curl -H "Authorization: Bearer $TOKEN" https://server/api/v4/users/me

# Post a message
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"channel_id": "CHANNEL_ID", "message": "Hello from the API"}' \
  https://server/api/v4/posts

# Get channel by name
curl -H "Authorization: Bearer $TOKEN" \
  https://server/api/v4/teams/TEAM_ID/channels/name/CHANNEL_NAME
```

## Message Formatting

Mattermost uses a Markdown variant:

```markdown
**bold**, *italic*, ~~strikethrough~~, `inline code`

> blockquote

- bullet list
1. numbered list

| Header 1 | Header 2 |
|----------|----------|
| Cell 1   | Cell 2   |

[Link text](https://example.com)
![Alt text](image_url)
```

### Code blocks
````
```python
print("syntax highlighted")
```
````

### Mentions
- `@username` — mention a user
- `@channel` — notify everyone in channel
- `@here` — notify online members
- `@all` — notify all members (use sparingly)

### Attachments (rich formatting)
```json
{
  "channel_id": "CHANNEL_ID",
  "message": "Summary text",
  "props": {
    "attachments": [{
      "fallback": "Fallback text",
      "color": "#36a64f",
      "pretext": "Optional pretext",
      "title": "Attachment Title",
      "title_link": "https://example.com",
      "text": "Attachment body text",
      "fields": [
        {"short": true, "title": "Field 1", "value": "Value 1"},
        {"short": true, "title": "Field 2", "value": "Value 2"}
      ]
    }]
  }
}
```

## Common API Endpoints

### Channels
```
GET    /channels/{id}                    # Get channel
GET    /teams/{id}/channels              # List team channels
POST   /channels                         # Create channel
POST   /channels/{id}/members            # Add member
DELETE /channels/{id}/members/{user_id}  # Remove member
GET    /users/{id}/channels/{team_id}    # User's channels in team
```

### Posts (Messages)
```
POST   /posts                            # Create post
GET    /channels/{id}/posts              # Get posts in channel
PUT    /posts/{id}                       # Update post
DELETE /posts/{id}                       # Delete post
POST   /posts/{id}/reactions             # Add reaction
GET    /posts/{id}/thread                # Get thread
```

### Users
```
GET    /users                            # List users (paginated)
GET    /users/{id}                       # Get user
GET    /users/username/{username}        # Get by username
PUT    /users/{id}/roles                 # Update roles
GET    /users/{id}/status               # Get status
```

### Files
```
POST   /files                            # Upload file
GET    /files/{id}                       # Get file metadata
GET    /files/{id}/link                  # Get public link
```

### File Upload + Post
```bash
# Upload file first
FILE_ID=$(curl -X POST -H "Authorization: Bearer $TOKEN" \
  -F "files=@report.pdf" -F "channel_id=CHANNEL_ID" \
  https://server/api/v4/files | jq -r '.file_infos[0].id')

# Then post with file attached
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"channel_id\": \"CHANNEL_ID\", \"message\": \"Here's the report\", \"file_ids\": [\"$FILE_ID\"]}" \
  https://server/api/v4/posts
```

## Webhooks

### Incoming Webhook (post to channel)
```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"text": "Alert: server load high", "username": "monitor-bot", "icon_emoji": ":warning:"}' \
  https://server/hooks/WEBHOOK_ID
```

### Outgoing Webhook (trigger on keywords)
Mattermost POSTs to your URL when trigger words appear. Respond with:
```json
{
  "text": "Response message",
  "response_type": "comment"
}
```

## Slash Commands

Custom slash commands POST to your endpoint:
```json
{
  "token": "command_token",
  "team_id": "...",
  "channel_id": "...",
  "user_id": "...",
  "command": "/mycommand",
  "text": "arguments after command"
}
```

Response:
```json
{
  "response_type": "in_channel",
  "text": "Result visible to everyone"
}
```

`response_type`: `"in_channel"` (visible) or `"ephemeral"` (only to caller)

## Interactive Messages (Buttons & Menus)

```json
{
  "attachments": [{
    "text": "Choose an option:",
    "actions": [
      {
        "id": "approve",
        "name": "Approve",
        "type": "button",
        "style": "good",
        "integration": {
          "url": "https://your-server/action",
          "context": {"action": "approve", "item_id": "123"}
        }
      },
      {
        "id": "reject",
        "name": "Reject",
        "type": "button",
        "style": "danger",
        "integration": {
          "url": "https://your-server/action",
          "context": {"action": "reject", "item_id": "123"}
        }
      }
    ]
  }]
}
```

## Bot Best Practices

- Respond to DMs and @mentions; don't spam channels
- Use ephemeral responses for commands that only the caller needs to see
- Rate limit: respect the server's rate limits (default 10 req/sec)
- Use `props.from_webhook: "true"` to mark bot messages
- Thread replies: set `root_id` to reply in a thread instead of the channel
- Reactions: use `POST /reactions` for lightweight acknowledgments
