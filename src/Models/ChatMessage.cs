namespace ZavaStorefront.Models
{
    public class ChatMessage
    {
        public string UserMessage { get; set; } = string.Empty;
    }

    public class ChatResponse
    {
        public bool Success { get; set; }
        public string? Response { get; set; }
        public string? Error { get; set; }
    }
}
