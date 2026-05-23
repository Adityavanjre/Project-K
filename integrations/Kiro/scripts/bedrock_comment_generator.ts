/**
 * Bedrock Comment Generator Module
 * Generates personalized acknowledgment comments using AWS Bedrock
 */

import { Octokit } from "@octokit/rest";
import {
  BedrockRuntimeClient,
  InvokeModelCommand,
} from "@aws-sdk/client-bedrock-runtime";
import { ClassificationResult } from "./data_models.js";
import { retryWithBackoff } from "./retry_utils.js";

const MODEL_ID_PRIMARY = "us.anthropic.claude-opus-4-6-v1";
const MODEL_ID_FALLBACK = "anthropic.claude-opus-4-5-20251101-v1:0";
const MAX_TOKENS = 1024;
const TEMPERATURE = 0.7;

// Security: Maximum lengths for input validation
const MAX_TITLE_LENGTH = 500;
const MAX_BODY_LENGTH = 2000;
const MAX_COMMENTS_LENGTH = 3000;
const MAX_COMMENTS_TO_FETCH = 10;

/**
 * Fetch existing comments on the issue
 */
async function fetchIssueComments(
  owner: string,
  repo: string,
  issueNumber: number,
  githubToken: string
): Promise<string> {
  try {
    const client = new Octokit({ auth: githubToken });

    const { data: comments } = await retryWithBackoff(async () => {
      return await client.issues.listComments({
        owner,
        repo,
        issue_number: issueNumber,
        per_page: MAX_COMMENTS_TO_FETCH,
        sort: "created",
        direction: "asc",
      });
    });

    if (comments.length === 0) {
      return "(No comments yet)";
    }

    // Format comments with author and body
    const formattedComments = comments
      .map((comment, index) => {
        const author = comment.user?.login || "unknown";
        const body = comment.body || "";
        return `Comment ${index + 1} by @${author}:\n${body}`;
      })
      .join("\n\n---\n\n");

    // Truncate if too long
    if (formattedComments.length > MAX_COMMENTS_LENGTH) {
      return formattedComments.substring(0, MAX_COMMENTS_LENGTH) + "\n\n[Comments truncated for length]";
    }

    return formattedComments;
  } catch (error) {
    console.error("Error fetching issue comments:", error);
    return "(Unable to fetch comments)";
  }
}

/**
 * Initialize Bedrock client with AWS credentials
 */
function createBedrockClient(): BedrockRuntimeClient {
  const region = process.env.AWS_REGION || "us-east-1";

  return new BedrockRuntimeClient({
    region,
    credentials: {
      accessKeyId: process.env.AWS_ACCESS_KEY_ID || "",
      secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || "",
    },
  });
}

/**
 * Build prompt for generating acknowledgment comment
 */
function buildCommentPrompt(
  issueTitle: string,
  issueBody: string,
  issueComments: string,
  labels: string
): string {
  return `You are a friendly GitHub bot for the Kiro project. Generate a welcoming acknowledgment comment for a newly triaged issue.

===== ISSUE TITLE =====
${issueTitle}
===== END ISSUE TITLE =====

===== ISSUE BODY =====
${issueBody || "(No description provided)"}
===== END ISSUE BODY =====

===== EXISTING COMMENTS =====
${issueComments}
===== END EXISTING COMMENTS =====

===== ASSIGNED LABELS =====
${labels}
===== END LABELS =====

TASK:
Write a brief, friendly acknowledgment comment (2-4 sentences) that:
1. Thanks the user for opening the issue
2. Briefly acknowledges what the issue is about (in 1 sentence), considering any discussion in the comments
3. Mentions that a maintainer will review it shortly
4. Is warm and encouraging

RULES:
- Keep it concise (2-4 sentences max)
- Be friendly and professional
- Don't make promises about fixes or timelines
- Don't repeat the issue title verbatim
- Use a conversational tone
- End with an encouraging note
- If there are existing comments, acknowledge the discussion briefly

OUTPUT:
Provide ONLY the comment text, no JSON, no formatting markers.`;
}

/**
 * Invoke Bedrock model with automatic fallback
 */
async function invokeBedrockWithFallback(
  client: BedrockRuntimeClient,
  prompt: string
): Promise<string> {
  const models = [
    { id: MODEL_ID_PRIMARY, name: "Claude Opus 4.6" },
    { id: MODEL_ID_FALLBACK, name: "Claude Opus 4.5" },
  ];

  let lastError: Error | null = null;

  for (const model of models) {
    try {
      console.log(`Attempting to generate comment with ${model.name}...`);

      const responseBody = await retryWithBackoff(async () => {
        const command = new InvokeModelCommand({
          modelId: model.id,
          contentType: "application/json",
          accept: "application/json",
          body: JSON.stringify({
            anthropic_version: "bedrock-2023-05-31",
            max_tokens: MAX_TOKENS,
            temperature: TEMPERATURE,
            messages: [
              {
                role: "user",
                content: prompt,
              },
            ],
          }),
        });

        const response = await client.send(command);
        return new TextDecoder().decode(response.body);
      });

      console.log(`Successfully generated comment with ${model.name}`);
      return responseBody;
    } catch (error) {
      console.warn(`${model.name} failed:`, error instanceof Error ? error.message : error);
      lastError = error instanceof Error ? error : new Error(String(error));
      
      // Continue to next model
      if (model.id !== models[models.length - 1].id) {
        console.log(`Falling back to next model...`);
      }
    }
  }

  // All models failed
  throw lastError || new Error("All models failed to generate comment");
}

/**
 * Parse Bedrock response to extract comment text
 */
function parseCommentResponse(responseBody: string): string {
  try {
    const parsed = JSON.parse(responseBody);
    
    if (parsed.content && Array.isArray(parsed.content)) {
      const textContent = parsed.content.find((c: any) => c.type === "text");
      if (textContent && textContent.text) {
        return textContent.text.trim();
      }
    }
    
    throw new Error("Unable to parse response content");
  } catch (error) {
    console.error("Error parsing Bedrock response:", error);
    throw error;
  }
}

/**
 * Generate acknowledgment comment using Bedrock Claude Opus 4.6
 */
export async function generateAcknowledgmentComment(
  owner: string,
  repo: string,
  issueNumber: number,
  issueTitle: string,
  issueBody: string,
  classification: ClassificationResult,
  githubToken: string
): Promise<string> {
  // Sanitize and truncate inputs
  const sanitizedTitle = issueTitle.substring(0, MAX_TITLE_LENGTH);
  const sanitizedBody = issueBody.substring(0, MAX_BODY_LENGTH);
  const labels = classification.recommended_labels.join(", ") || "pending-triage";

  // Fetch existing comments
  const issueComments = await fetchIssueComments(owner, repo, issueNumber, githubToken);

  const client = createBedrockClient();
  const prompt = buildCommentPrompt(sanitizedTitle, sanitizedBody, issueComments, labels);

  try {
    const responseBody = await invokeBedrockWithFallback(client, prompt);
    return parseCommentResponse(responseBody);
  } catch (error) {
    console.error("Error generating acknowledgment comment with Bedrock:", error);
    throw error;
  }
}

/**
 * Get fallback comment when Bedrock fails
 */
export function getFallbackComment(): string {
  return `Thank you for opening this issue! 🙏

We've received your report and our automated triage system has analyzed it. A maintainer will review it shortly.

We appreciate your contribution to making Kiro better!`;
}
