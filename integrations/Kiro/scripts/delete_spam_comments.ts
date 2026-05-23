/**
 * Delete Spam Comments Script
 * Uses AWS Bedrock to semantically detect and delete spam comments on GitHub issues.
 */

import { Octokit } from "@octokit/rest";
import {
  BedrockRuntimeClient,
  InvokeModelCommand,
} from "@aws-sdk/client-bedrock-runtime";
import { retryWithBackoff } from "./retry_utils.js";

const BEDROCK_MODEL_ID = "us.anthropic.claude-sonnet-4-20250514-v1:0";
const CONFIDENCE_THRESHOLD = 0.95;
const SPAM_DETECTION_PROMPT =
  "You are a spam detection system for GitHub issue comments. Your job is to protect the repository from spam while preserving all legitimate user contributions.\n\n" +
  "CRITICAL: Err on the side of NOT flagging spam. A false positive (deleting a real comment) is far worse than a false negative (missing spam). When in doubt, classify as NOT spam.\n\n" +
  "Spam includes:\n" +
  "- Cryptocurrency scams, investment fraud, or guaranteed returns claims\n" +
  "- Unsolicited promotions for Telegram, WhatsApp, Discord, or other external groups\n" +
  "- Phishing links or obfuscated URLs (hxxps://, punycode xn-- domains, defanged links, URL shorteners to suspicious destinations)\n" +
  "- Freelancer solicitation (contact me to fix this, DM me for help)\n" +
  "- SEO backlink spam (Great project! Visit my site at...)\n" +
  "- Bot-generated noise (emoji-only, copy-paste generic praise with links)\n" +
  "- Any message designed to lure users off-platform for financial or personal gain\n\n" +
  "NOT spam (do not flag these):\n" +
  "- Bug reports, feature requests, or questions — even if poorly written\n" +
  "- Comments referencing external tools, libraries, or documentation links that are relevant to the discussion\n" +
  "- Users sharing workarounds or code snippets\n" +
  "- Expressions of frustration or criticism about the project\n" +
  "- Comments in any language — non-English comments are not spam by default\n\n" +
  "OBFUSCATION: Comments may use Unicode homoglyphs, leetspeak, zero-width characters, or mixed scripts to evade detection. Analyze semantic intent, not surface characters.\n\n" +
  "CONFIDENCE CALIBRATION:\n" +
  "- 0.0-0.3: Clearly legitimate\n" +
  "- 0.4-0.6: Ambiguous, could go either way\n" +
  "- 0.7-0.8: Likely spam but some doubt remains\n" +
  "- 0.9-1.0: Unambiguously spam with no reasonable alternative interpretation\n\n" +
  'Respond with JSON only:\n{"is_spam": true | false, "confidence": 0.0 to 1.0, "reason": "brief explanation"}';

export interface SpamCheckResult {
  isSpam: boolean;
  reason: string;
  confidence: number;
}

function createBedrockClient(): BedrockRuntimeClient {
  return new BedrockRuntimeClient({
    region: process.env.AWS_REGION || "us-east-1",
  });
}

/**
 * Sanitize comment body to prevent prompt injection.
 * Strips null bytes and limits length; content is passed as a separate user
 * message (never interpolated into the system prompt) so injection is not
 * structurally possible, but we still normalise the input defensively.
 */
function sanitizeCommentBody(body: string): string {
  return body
    .replace(/\0/g, "") // strip null bytes
    .substring(0, 2000)  // hard cap — model doesn't need more
    .trim();
}

/**
 * Use Bedrock to semantically detect spam, including obfuscated/homoglyph content.
 * The comment body is passed as a separate user message so it can never
 * override or escape the system instructions.
 */
export async function isSpamComment(body: string): Promise<SpamCheckResult> {
  if (!body.trim()) {
    return { isSpam: false, reason: "Empty comment", confidence: 0 };
  }

  const client = createBedrockClient();

  // Sanitize and isolate the comment — never interpolate into the system prompt.
  const safeBody = sanitizeCommentBody(body);

  try {
    const responseBody = await retryWithBackoff(async () => {
      const command = new InvokeModelCommand({
        modelId: BEDROCK_MODEL_ID,
        contentType: "application/json",
        accept: "application/json",
        body: JSON.stringify({
          anthropic_version: "bedrock-2023-05-31",
          max_tokens: 256,
          temperature: 0.1,
          system: SPAM_DETECTION_PROMPT,
          // Comment is the sole user message — structurally isolated from instructions.
          messages: [{ role: "user", content: safeBody }],
        }),
      });
      const response = await client.send(command);
      return new TextDecoder().decode(response.body);
    });

    const parsed = JSON.parse(responseBody);
    const text = parsed.content?.find((c: any) => c.type === "text")?.text ?? "";
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (!jsonMatch) throw new Error("No JSON in Bedrock response");

    const result = JSON.parse(jsonMatch[0]);
    const confidence = result.confidence ?? 0;
    const isSpam = result.is_spam === true && confidence >= CONFIDENCE_THRESHOLD;

    return { isSpam, reason: result.reason ?? "", confidence };
  } catch (err) {
    console.warn("Bedrock spam check failed, skipping:", err);
    return { isSpam: false, reason: "Bedrock check failed", confidence: 0 };
  }
}

/**
 * Run a second independent Bedrock call to confirm a spam verdict.
 * Uses a distinct system prompt asking the model to re-evaluate the comment
 * with fresh reasoning. Only returns true if both passes agree.
 */
async function confirmSpam(body: string, firstResult: SpamCheckResult): Promise<boolean> {
  const client = createBedrockClient();
  const safeBody = sanitizeCommentBody(body);

  const confirmationPrompt =
    "You are a spam detection reviewer. A previous check flagged the following comment as spam. " +
    "Re-evaluate the comment independently from scratch. Respond with JSON: " +
    '{"is_spam": boolean, "confidence": number, "reason": string}. ' +
    "Be conservative — only confirm spam if you are highly confident.";

  try {
    const responseBody = await retryWithBackoff(async () => {
      const command = new InvokeModelCommand({
        modelId: BEDROCK_MODEL_ID,
        contentType: "application/json",
        accept: "application/json",
        body: JSON.stringify({
          anthropic_version: "bedrock-2023-05-31",
          max_tokens: 256,
          temperature: 0.1,
          system: confirmationPrompt,
          messages: [{ role: "user", content: safeBody }],
        }),
      });
      const response = await client.send(command);
      return new TextDecoder().decode(response.body);
    });

    const parsed = JSON.parse(responseBody);
    const text = parsed.content?.find((c: any) => c.type === "text")?.text ?? "";
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (!jsonMatch) throw new Error("No JSON in confirmation response");

    const result = JSON.parse(jsonMatch[0]);
    const confirmed = result.is_spam === true && (result.confidence ?? 0) >= CONFIDENCE_THRESHOLD;
    console.log(`Confirmation pass: is_spam=${result.is_spam}, confidence=${result.confidence?.toFixed(2)}, reason=${result.reason}`);
    return confirmed;
  } catch (err) {
    console.warn("Confirmation pass failed, defaulting to NOT spam:", err);
    return false;
  }
}

/**
 * Check if a user is a member of the repository's organization.
 * Returns true for org members so their comments are never flagged as spam.
 */
async function isOrgMember(
  client: Octokit,
  org: string,
  username: string
): Promise<boolean> {
  try {
    await client.orgs.checkMembershipForUser({ org, username });
    // A successful response (204 or 302) without throwing means the user is a member
    // or the requester can see the membership. Treat as member.
    return true;
  } catch {
    // 404 means not a member (or org/user doesn't exist)
    return false;
  }
}

async function fetchComment(
  client: Octokit,
  owner: string,
  repo: string,
  commentId: number
): Promise<{ body: string; author: string }> {
  const { data } = await retryWithBackoff(() =>
    client.issues.getComment({ owner, repo, comment_id: commentId })
  );
  return { body: data.body ?? "", author: data.user?.login ?? "unknown" };
}

async function deleteComment(
  client: Octokit,
  owner: string,
  repo: string,
  commentId: number
): Promise<void> {
  await retryWithBackoff(async () => {
    await client.issues.deleteComment({ owner, repo, comment_id: commentId });
  });
}

async function processSingleComment(
  client: Octokit,
  owner: string,
  repo: string,
  commentId: number,
  commentBody: string,
  commentAuthor: string
): Promise<boolean> {
  console.log(`Checking comment #${commentId} by @${commentAuthor}...`);

  if (await isOrgMember(client, owner, commentAuthor)) {
    console.log(`@${commentAuthor} is an org member — skipping spam check.`);
    return false;
  }

  const result = await isSpamComment(commentBody);

  if (!result.isSpam) {
    console.log(`Clean (confidence: ${result.confidence.toFixed(2)}). Reason: ${result.reason}`);
    return false;
  }

  console.log(`First pass flagged spam (confidence: ${result.confidence.toFixed(2)}). Running confirmation pass...`);
  const confirmed = await confirmSpam(commentBody, result);

  if (!confirmed) {
    console.log(`Confirmation pass did NOT agree — keeping comment #${commentId}.`);
    return false;
  }

  await deleteComment(client, owner, repo, commentId);
  console.log(`--- Audit Log: Deleted comment #${commentId} ---`);
  console.log(`Author: @${commentAuthor}`);
  console.log(`Confidence: ${result.confidence.toFixed(2)}`);
  console.log(`Reason: ${result.reason}`);
  console.log(`Body length: ${commentBody.length} chars`);
  console.log(`Timestamp: ${new Date().toISOString()}`);
  console.log(`---`);
  return true;
}


async function main() {
  const owner = process.env.REPOSITORY_OWNER || "";
  const repo = process.env.REPOSITORY_NAME || "";
  const githubToken = process.env.GITHUB_TOKEN || "";
  const commentId = process.env.COMMENT_ID ? parseInt(process.env.COMMENT_ID) : null;

  if (!owner || !repo || !githubToken) {
    console.error("Missing required environment variables: REPOSITORY_OWNER, REPOSITORY_NAME, GITHUB_TOKEN");
    process.exit(1);
  }

  if (!commentId) {
    console.error("Missing required COMMENT_ID for spam check");
    process.exit(1);
  }

  const client = new Octokit({ auth: githubToken });

  console.log(`=== Single Comment Spam Check (comment #${commentId}) ===`);
  const { body, author } = await fetchComment(client, owner, repo, commentId);
  const deleted = await processSingleComment(client, owner, repo, commentId, body, author);
  console.log(`\nSummary: ${deleted ? `Spam comment #${commentId} by @${author} was deleted.` : `Comment #${commentId} is clean — no action taken.`}`);
}

// Only run when executed directly (not when imported by tests)
if (process.env.JEST_WORKER_ID === undefined) {
  main().catch((err) => {
    console.error("Fatal error:", err);
    process.exit(1);
  });
}
