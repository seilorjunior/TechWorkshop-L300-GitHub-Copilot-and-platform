using Microsoft.Extensions.Configuration;
using Azure;
using Azure.AI.Inference;
using Azure.Core;
using Azure.Identity;
using Azure.Core.Pipeline;
using ZavaStorefront.Models;

namespace ZavaStorefront.Services
{
    public class ChatService
    {
        private readonly IConfiguration _configuration;
        private readonly string _modelName;
        private readonly string _deploymentName;
        private readonly ChatCompletionsClient? _client;

        public ChatService(IConfiguration configuration)
        {
            _configuration = configuration;
            
            // Use the new configuration values with fallbacks
            var modelName = _configuration["AzureAI:Model"];
            _modelName = !string.IsNullOrEmpty(modelName) ? modelName : "Phi-4";
            
            var deploymentName = _configuration["AzureAI:DeploymentName"];
            _deploymentName = !string.IsNullOrEmpty(deploymentName) ? deploymentName : "phi4";
            
            // Initialize the ChatCompletionsClient with the new endpoint
            var endpoint = _configuration["AzureAI:Endpoint"];
            if (string.IsNullOrWhiteSpace(endpoint))
            {
                endpoint = "https://aisiflvjrl6hpmdg.services.ai.azure.com/openai/v1/";
            }
            
            if (!string.IsNullOrWhiteSpace(endpoint))
            {
                var uri = new Uri(endpoint);
                var credential = new DefaultAzureCredential();
                var clientOptions = new AzureAIInferenceClientOptions();
                var tokenPolicy = new BearerTokenAuthenticationPolicy(credential, new string[] { "https://cognitiveservices.azure.com/.default" });
                clientOptions.AddPolicy(tokenPolicy, HttpPipelinePosition.PerRetry);
                
                _client = new ChatCompletionsClient(uri, credential, clientOptions);
            }
        }

        public async Task<ChatResponse> SendMessageAsync(string userMessage)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(userMessage))
                {
                    return new ChatResponse
                    {
                        Success = false,
                        Error = "Message cannot be empty"
                    };
                }

                if (_client == null)
                {
                    return new ChatResponse
                    {
                        Success = false,
                        Error = "Azure AI endpoint is not configured"
                    };
                }

                var requestOptions = new ChatCompletionsOptions
                {
                    Messages =
                    {
                        new ChatRequestSystemMessage("You are a helpful assistant for the Zava Storefront. Help customers with product inquiries, pricing questions, and general support."),
                        new ChatRequestUserMessage(userMessage)
                    },
                    Model = _deploymentName,
                    MaxTokens = 800,
                    Temperature = 0.7f
                };

                var response = await _client.CompleteAsync(requestOptions);
                var aiResponse = response.Value.Content;

                if (string.IsNullOrEmpty(aiResponse))
                {
                    return new ChatResponse
                    {
                        Success = false,
                        Error = "AI service returned empty response"
                    };
                }

                return new ChatResponse
                {
                    Success = true,
                    Response = aiResponse
                };
            }
            catch (Exception ex)
            {
                return new ChatResponse
                {
                    Success = false,
                    Error = $"Failed to get AI response: {ex.Message}",
                    ExceptionType = ex.GetType().FullName,
                    StackTrace = ex.ToString(),
                    InnerException = ex.InnerException?.ToString()
                };
            }
        }
    }
}