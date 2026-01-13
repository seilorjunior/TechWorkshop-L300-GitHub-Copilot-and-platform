using Azure;
using Azure.AI.ContentSafety;
using Azure.AI.Inference;
using Azure.Identity;
using ZavaStorefront.Models;

namespace ZavaStorefront.Services
{
    public class ChatService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<ChatService> _logger;
        private readonly ChatCompletionsClient? _chatClient;
        private readonly ContentSafetyClient? _contentSafetyClient;
        private const int UnsafeSeverityThreshold = 2;

        public ChatService(IConfiguration configuration, ILogger<ChatService> logger)
        {
            _configuration = configuration;
            _logger = logger;

            var endpoint = _configuration["AzureAI:Endpoint"];
            var contentSafetyEndpoint = _configuration["AzureAI:ContentSafetyEndpoint"];

            if (!string.IsNullOrEmpty(endpoint))
            {
                try
                {
                    var credential = new DefaultAzureCredential();
                    _chatClient = new ChatCompletionsClient(new Uri(endpoint), credential);

                    // Use Content Safety endpoint if provided, otherwise use main AI Services endpoint
                    var safetyEndpoint = !string.IsNullOrEmpty(contentSafetyEndpoint) ? contentSafetyEndpoint : endpoint;
                    _contentSafetyClient = new ContentSafetyClient(new Uri(safetyEndpoint), credential);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to initialize AI clients");
                }
            }
        }

        public async Task<ChatResponse> SendMessageAsync(string userMessage)
        {
            if (_chatClient == null)
            {
                return new ChatResponse
                {
                    Success = false,
                    Error = "Chat service is not configured. Please set AzureAI:Endpoint in configuration."
                };
            }

            // Check content safety before processing
            var safetyResult = await CheckContentSafetyAsync(userMessage);
            if (!safetyResult.IsSafe)
            {
                _logger.LogWarning("Unsafe content detected in user message. Categories flagged: {Categories}", safetyResult.FlaggedCategories);
                return new ChatResponse
                {
                    Success = false,
                    Error = "I'm sorry, but I can't process this request as it may contain inappropriate content. Please rephrase your message."
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

                var response = await _chatClient.CompleteAsync(requestOptions);

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

        private async Task<ContentSafetyResult> CheckContentSafetyAsync(string text)
        {
            if (_contentSafetyClient == null)
            {
                _logger.LogWarning("Content Safety client not configured, skipping safety check");
                return new ContentSafetyResult { IsSafe = true };
            }

            try
            {
                var request = new AnalyzeTextOptions(text);
                var response = await _contentSafetyClient.AnalyzeTextAsync(request);

                var flaggedCategories = new List<string>();

                // Check Violence
                if (response.Value.CategoriesAnalysis.FirstOrDefault(c => c.Category == TextCategory.Violence)?.Severity >= UnsafeSeverityThreshold)
                {
                    flaggedCategories.Add("Violence");
                }

                // Check Sexual content
                if (response.Value.CategoriesAnalysis.FirstOrDefault(c => c.Category == TextCategory.Sexual)?.Severity >= UnsafeSeverityThreshold)
                {
                    flaggedCategories.Add("Sexual");
                }

                // Check Hate speech
                if (response.Value.CategoriesAnalysis.FirstOrDefault(c => c.Category == TextCategory.Hate)?.Severity >= UnsafeSeverityThreshold)
                {
                    flaggedCategories.Add("Hate");
                }

                // Check Self-harm
                if (response.Value.CategoriesAnalysis.FirstOrDefault(c => c.Category == TextCategory.SelfHarm)?.Severity >= UnsafeSeverityThreshold)
                {
                    flaggedCategories.Add("SelfHarm");
                }

                var isSafe = flaggedCategories.Count == 0;

                _logger.LogInformation("Content safety check completed. Safe: {IsSafe}, Categories checked: Violence, Sexual, Hate, SelfHarm", isSafe);

                return new ContentSafetyResult
                {
                    IsSafe = isSafe,
                    FlaggedCategories = string.Join(", ", flaggedCategories)
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking content safety");
                // Fail open - allow the request if safety check fails
                return new ContentSafetyResult { IsSafe = true };
            }
        }

        private class ContentSafetyResult
        {
            public bool IsSafe { get; set; }
            public string FlaggedCategories { get; set; } = string.Empty;
        }
    }
}
