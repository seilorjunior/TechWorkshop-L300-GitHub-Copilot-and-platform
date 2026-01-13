using Azure;
using Azure.AI.Inference;
using Azure.Identity;
using ZavaStorefront.Models;

namespace ZavaStorefront.Services
{
    public class ChatService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<ChatService> _logger;
        private readonly ChatCompletionsClient? _client;

        public ChatService(IConfiguration configuration, ILogger<ChatService> logger)
        {
            _configuration = configuration;
            _logger = logger;

            var endpoint = _configuration["AzureAI:Endpoint"];

            if (!string.IsNullOrEmpty(endpoint))
            {
                try
                {
                    _client = new ChatCompletionsClient(
                        new Uri(endpoint),
                        new DefaultAzureCredential());
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to initialize ChatCompletionsClient");
                }
            }
        }

        public async Task<ChatResponse> SendMessageAsync(string userMessage)
        {
            if (_client == null)
            {
                return new ChatResponse
                {
                    Success = false,
                    Error = "Chat service is not configured. Please set AzureAI:Endpoint and AzureAI:DeploymentName in configuration."
                };
            }

            try
            {
                var requestOptions = new ChatCompletionsOptions
                {
                    Messages =
                    {
                        new ChatRequestSystemMessage("You are a helpful assistant for the Zava Storefront. Help customers with product inquiries, pricing questions, and general support."),
                        new ChatRequestUserMessage(userMessage)
                    },
                    MaxTokens = 800,
                    Temperature = 0.7f
                };

                var response = await _client.CompleteAsync(requestOptions);

                return new ChatResponse
                {
                    Success = true,
                    Response = response.Value.Content
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending message to AI service");
                return new ChatResponse
                {
                    Success = false,
                    Error = $"Failed to get response: {ex.Message}"
                };
            }
        }
    }
}
