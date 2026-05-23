/**
 * Test duplicate detection and preview the comment without posting
 */

import { Octokit } from "@octokit/rest";
import { detectDuplicates, generateDuplicateComment } from "../detect_duplicates.js";

console.log("╔════════════════════════════════════════════════════════════╗");
console.log("║         Duplicate Detection Preview (No Posting)          ║");
console.log("╚════════════════════════════════════════════════════════════╝");
console.log("");

async function previewDuplicateDetection() {
  const issueNumber = process.env.TEST_ISSUE_NUMBER;
  const githubToken = process.env.GITHUB_TOKEN || "";
  const owner = process.env.REPOSITORY_OWNER || "kirodotdev";
  const repo = process.env.REPOSITORY_NAME || "Kiro";

  if (!issueNumber) {
    console.error("❌ TEST_ISSUE_NUMBER environment variable is required");
    console.log("");
    console.log("Usage:");
    console.log("  export TEST_ISSUE_NUMBER=4977");
    console.log("  npm run build && node dist/test/test-duplicate-preview.js");
    process.exit(1);
  }

  if (!githubToken) {
    console.error("❌ GITHUB_TOKEN environment variable is required");
    process.exit(1);
  }

  console.log(`Repository: ${owner}/${repo}`);
  console.log(`Issue Number: #${issueNumber}`);
  console.log("");

  // Fetch the issue details from GitHub
  console.log("Fetching issue details from GitHub...");
  const client = new Octokit({ auth: githubToken });

  try {
    const { data: issue } = await client.issues.get({
      owner,
      repo,
      issue_number: parseInt(issueNumber),
    });

    console.log("✅ Issue fetched successfully");
    console.log("");
    console.log("─".repeat(60));
    console.log(`Title: ${issue.title}`);
    console.log(`State: ${issue.state}`);
    console.log(`Labels: ${issue.labels.map((l: any) => l.name).join(", ") || "none"}`);
    console.log(`Type: ${issue.type || "NOT SET"}`);
    console.log(`Created: ${issue.created_at}`);
    console.log(`URL: ${issue.html_url}`);
    console.log("─".repeat(60));
    console.log("");

    // Run duplicate detection
    console.log("🔍 Running duplicate detection...");
    console.log("");

    const duplicates = await detectDuplicates(
      issue.title,
      issue.body || "",
      owner,
      repo,
      parseInt(issueNumber),
      githubToken
    );

    console.log("");
    console.log("═".repeat(60));
    console.log("");

    if (duplicates.length > 0) {
      console.log(`✅ Found ${duplicates.length} potential duplicate(s)`);
      console.log("");
      console.log("Duplicate Details:");
      console.log("─".repeat(60));
      duplicates.forEach((dup, idx) => {
        console.log(`${idx + 1}. Issue #${dup.issue_number}: ${dup.issue_title}`);
        console.log(`   Similarity: ${(dup.similarity_score * 100).toFixed(1)}%`);
        console.log(`   URL: ${dup.url}`);
        console.log(`   Reasoning: ${dup.reasoning}`);
        console.log("");
      });
      console.log("─".repeat(60));
      console.log("");

      // Generate the comment
      const comment = generateDuplicateComment(duplicates);

      console.log("📝 PREVIEW OF COMMENT THAT WOULD BE POSTED:");
      console.log("═".repeat(60));
      console.log(comment);
      console.log("═".repeat(60));
      console.log("");
      console.log("⚠️  NOTE: This is a preview only. No comment was posted to GitHub.");
    } else {
      console.log("✅ No duplicates found");
      console.log("");
      console.log("This issue appears to be unique. No duplicate comment would be posted.");
    }

    console.log("");
    console.log("✅ Preview complete!");

  } catch (error: any) {
    console.error("❌ Error:", error.message);
    if (error.status === 404) {
      console.log("");
      console.log("Issue not found. Please check:");
      console.log(`  - Issue #${issueNumber} exists in ${owner}/${repo}`);
      console.log("  - You have access to the repository");
    }
    process.exit(1);
  }
}

previewDuplicateDetection().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
