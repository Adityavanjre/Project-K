import { tool } from 'ai';
import { z } from 'zod';

export const webSearchTool = tool({
  description: 'Search web via Tavily',
  inputSchema: z.object({
    query: z.string().describe('The search query for finding information on the web'),
    limit: z.number().min(1).max(10).default(5).describe('Maximum number of results to return (default: 5)')
  }),
  execute: async ({ query, limit = 5 }) => {
    try {
      const apiKey = process.env.TAVILY_API_KEY;
      
      if (!apiKey) {
        console.error('Tavily API key not found in environment variables');
        throw new Error('Tavily API key not configured - check environment variables');
      }
      
      console.log('WebSearch: Starting Tavily search for query:', query);

      const response = await fetch('https://api.tavily.com/search', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          api_key: apiKey,
          query: query,
          search_depth: 'basic',
          include_answer: true,
          include_images: false,
          include_raw_content: false,
          max_results: limit,
          include_domains: [],
          exclude_domains: []
        }),
      });
      
      if (!response.ok) {
        const errorText = await response.text();
        console.error('Tavily API error response:', response.status, errorText);
        throw new Error(`Tavily API failed with status: ${response.status} - ${errorText}`);
      }
      
      const data = await response.json();
      console.log('WebSearch: Tavily response received with', data.results?.length || 0, 'results');
      
      // Extract results from Tavily response
      const results = (data.results || []).map((result: any) => ({
        title: result.title || 'No title',
        snippet: result.content || 'No description available',
        url: result.url || '',
        score: result.score || 0,
        published_date: result.published_date || null,
      }));

      return {
        success: true,
        data: {
          results,
          query: query,
          count: results.length,
          answer: data.answer || null,
          source: 'Tavily AI Search'
        }
      };
    } catch (error) {
      console.error('WebSearch tool error:', error);
      // Fallback response when web search fails
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Web search failed',
        data: {
          results: [],
          query: query,
          count: 0,
          note: 'Web search is currently unavailable. Consider searching your knowledge base instead.'
        }
      };
    }
  }
});
