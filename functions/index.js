const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const { GoogleGenerativeAI } = require("@google/generative-ai");

admin.initializeApp();

const geminiApiKey = defineSecret("GEMINI_API_KEY");

// ============================================================================
// 1. GEMINI AI INTEGRATION
// ============================================================================
exports.chatWithGemini = onCall(
  { secrets: [geminiApiKey], maxInstances: 10 }, 
  async (request) => {
    try {
      const userPrompt = request.data.prompt;
      if (!userPrompt || typeof userPrompt !== "string") {
        throw new HttpsError("invalid-argument", "Valid prompt required.");
      }

      const genAI = new GoogleGenerativeAI(geminiApiKey.value());
      const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });
      const result = await model.generateContent(userPrompt);

      return { reply: result.response.text() };
    } catch (error) {
      console.error("Gemini API Error:", error);
      throw new HttpsError("internal", "Failed to generate response.");
    }
  }
);

// ============================================================================
// 2. ADMIN ROLE ASSIGNMENT (Custom Claims)
// ============================================================================
exports.setAdminRole = onCall(async (request) => {
  if (!request.auth || request.auth.token.admin !== true) {
    throw new HttpsError("permission-denied", "Only admins can assign roles.");
  }

  const targetUid = request.data.uid;
  if (!targetUid) {
    throw new HttpsError("invalid-argument", "Target UID required.");
  }

  try {
    await admin.auth().setCustomUserClaims(targetUid, { admin: true });
    return { message: `Success! User ${targetUid} has been granted Admin privileges.` };
  } catch (error) {
    console.error("Error setting custom claim:", error);
    throw new HttpsError("internal", "Failed to assign admin role.");
  }
});
