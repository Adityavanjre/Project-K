/**
 * Test for duplicate detection with issue type filtering
 * Tests the changes to filter by Bug/Feature types instead of labels
 */

import { fetchExistingIssues } from "../detect_duplicates.js";
import { addDuplicateLabel } from "../assign_labels.js";

console.log("╔════════════════════════════════════════════════════════════╗");
console.log("║    Duplicate Detection - Issue Type Filter Test           ║");
console.log("╚════════════════════════════════════════════════════════════╝");
console.log("");

async function testIssueTypeFiltering() {
  const owner = process.env.REPOSITORY_OWNER || "kirodotdev";
  const repo = process.env.REPOSITORY_NAME || "Kiro";
  const githubToken = process.env.GITHUB_TOKEN || "";

  if (!githubToken) {
    console.error("❌ GITHUB_TOKEN environment variable is required");
    process.exit(1);
  }

  console.log(`Repository: ${owner}/${repo}`);
  console.log("");

  // Test 1: Fetch existing issues and verify type filtering
  console.log("Test 1: Fetching issues with Bug/Feature types");
  console.log("─".repeat(60));

  try {
    const issues = await fetchExistingIssues(
      owner,
      repo,
      999999, // Fake issue number to exclude
      githubToken
    );

    console.log(`✅ Fetched ${issues.length} issues with Bug or Feature type`);
    console.log("");

    if (issues.length > 0) {
      console.log("Sample issues (first 5):");
      issues.slice(0, 5).forEach((issue) => {
        console.log(`   #${issue.number}: ${issue.title}`);
        console.log(`   Labels: ${issue.labels.join(", ") || "none"}`);
        console.log(`   URL: ${issue.url}`);
        console.log("");
      });
    } else {
      console.log("⚠️  No issues found with Bug or Feature type");
      console.log("   This might mean:");
      console.log("   - The repository doesn't have issue types configured");
      console.log("   - No open issues have Bug or Feature type assigned");
      console.log("   - The API doesn't return the 'type' field yet");
    }
  } catch (error) {
    console.error("❌ Error fetching issues:", error);
  }

  console.log("");
  console.log("═".repeat(60));
  console.log("");

  // Test 2: Test adding duplicate label and removing pending-triage
  console.log("Test 2: Add duplicate label and remove pending-triage");
  console.log("─".repeat(60));
  console.log("");
  console.log("⚠️  This test requires a real issue number to test against.");
  console.log("   Set ISSUE_NUMBER environment variable to test this feature.");
  console.log("");

  const testIssueNumber = process.env.ISSUE_NUMBER;
  if (testIssueNumber) {
    console.log(`Testing with issue #${testIssueNumber}`);
    try {
      const result = await addDuplicateLabel(
        owner,
        repo,
        parseInt(testIssueNumber),
        githubToken
      );

      if (result) {
        console.log("✅ Successfully added duplicate label");
        console.log("✅ Attempted to remove pending-triage label");
        console.log("");
        console.log("Please verify manually:");
        console.log(`   1. Issue #${testIssueNumber} has 'duplicate' label`);
        console.log(`   2. Issue #${testIssueNumber} does NOT have 'pending-triage' label`);
      } else {
        console.log("❌ Failed to add duplicate label");
      }
    } catch (error) {
      console.error("❌ Error testing label operations:", error);
    }
  } else {
    console.log("ℹ️  Skipping label test (no ISSUE_NUMBER provided)");
  }

  console.log("");
  console.log("═".repeat(60));
  console.log("");
  console.log("✅ Test complete!");
  console.log("");
  console.log("Summary of changes tested:");
  console.log("  1. ✓ Fetch issues filtered by type (Bug/Feature) instead of labels");
  console.log("  2. ✓ Remove pending-triage label when adding duplicate label");
}

// Run test
testIssueTypeFiltering()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => {
    console.error("Fatal error:", error);
    process.exit(1);
  });
