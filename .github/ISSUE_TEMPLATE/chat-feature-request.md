---
name: "Add AI Chat Functionality with Phi4 Model Integration"
about: "Feature request for adding chat functionality integrated with Microsoft Foundry Phi4"
title: "Add AI Chat Functionality with Phi4 Model Integration"
labels: enhancement, feature
---

## Feature Request

### Summary
Add a simple chat functionality as a separate page that integrates with Microsoft Foundry's Phi4 endpoint to provide AI-powered responses.

### Description
Create a new Chat page in the Zava Storefront application that allows users to interact with the Phi4 AI model deployed on Microsoft Foundry. The chat interface should:

1. Display a text input area for user messages
2. Send messages to the Phi4 endpoint on Microsoft Foundry
3. Display AI responses in an existing text area (conversation history)
4. Provide a clean, user-friendly interface consistent with the existing application design

### Requirements

#### Backend
- [ ] Create a new `ChatController.cs` in the Controllers folder
- [ ] Create a new `ChatService.cs` in the Services folder to handle Foundry API communication
- [ ] Add configuration settings for the Foundry endpoint and Phi4 model in `appsettings.json`
- [ ] Register the ChatService in `Program.cs`

#### Frontend
- [ ] Create a new `Chat/Index.cshtml` view with:
  - Text area for conversation history (readonly)
  - Input field for user messages
  - Send button
  - Loading indicator during API calls
- [ ] Add navigation link to Chat page in `_Layout.cshtml`
- [ ] Style the chat interface using Bootstrap (consistent with existing design)

#### Configuration
- [ ] Configure the Phi4 model endpoint URL
- [ ] Handle authentication to Microsoft Foundry (Azure AI Services)
- [ ] Add proper error handling for API failures

### Technical Details
- The application is an ASP.NET Core MVC app (.NET 6.0)
- Microsoft Foundry/Azure AI Services infrastructure is already defined in `infra/modules/ai-services.bicep`
- Use the Azure.AI.Inference SDK or REST API for Foundry communication

### Acceptance Criteria
1. User can navigate to the Chat page from the main navigation
2. User can type a message and submit it
3. The message is sent to the Phi4 model endpoint
4. The AI response is displayed in the conversation area
5. Conversation history is maintained during the session
6. Error messages are displayed gracefully when API fails
7. Loading state is shown while waiting for responses

### Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `src/Controllers/ChatController.cs` | Create | New controller for chat endpoints |
| `src/Services/ChatService.cs` | Create | Service for Foundry API integration |
| `src/Models/ChatMessage.cs` | Create | Model for chat messages |
| `src/Views/Chat/Index.cshtml` | Create | Chat page view |
| `src/appsettings.json` | Modify | Add Foundry configuration |
| `src/Program.cs` | Modify | Register ChatService |
| `src/Views/Shared/_Layout.cshtml` | Modify | Add navigation link |

### Additional Notes
- Ensure proper async/await patterns for API calls
- Add logging for debugging and monitoring
- Consider rate limiting for API calls
- The Phi4 model is already deployed on Microsoft Foundry
