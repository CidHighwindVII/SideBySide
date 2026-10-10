package dev.sidebyside.sidebyside

import io.flutter.plugin.common.MethodChannel

// Phase 5 — capability-aware on-device note summaries.
//
// Design decisions (recorded in new-implementation.md Phase 5):
//  * The ML Kit GenAI Summarization API is beta, runs only on AICore/Gemini
//    Nano-capable devices, and its documented language set (2026-10) is
//    English/Japanese/Korean — NOT Portuguese. Bundling the dependency
//    without a verified supported device would add risk to the release build
//    while still never serving this app's primary locales' promise, so the
//    build intentionally does NOT include the provider yet.
//  * Until real provider availability/setup/inference is implemented, this
//    bridge always reports unavailable for supported languages. Package/class
//    presence is not a readiness check. History stays fully usable.
//  * Future wiring must use the provider's actual feature-status API and local
//    inference, with no cloud path.
object SummarizationBridge {
    private val SUPPORTED_LANGS = setOf("en", "ja", "ko")

    fun capability(context: android.content.Context, lang: String): String {
        if (!SUPPORTED_LANGS.contains(lang)) return "unsupportedLanguage"
        // Neither class presence nor an installed AICore package establishes
        // inference readiness. No provider is shipped/wired in this build.
        return "unavailable"
    }

    fun summarize(context: android.content.Context, lang: String): Nothing? {
        when (capability(context, lang)) {
            "available" -> throw IllegalStateException(
                "Provider present but inference wiring is pending verified " +
                    "device support (see new-implementation.md Phase 5)")
            "needsDownload" -> throw IllegalStateException("needsDownload")
            else -> throw IllegalStateException("unavailable")
        }
    }
}

fun configureSummarizationChannel(
    messenger: io.flutter.plugin.common.BinaryMessenger,
    activity: android.app.Activity,
) {
    MethodChannel(messenger, "sidebyside/summarization")
        .setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "capability" -> {
                        val lang = (call.arguments as? Map<*, *>)?.get("lang")
                            as? String ?: "en"
                        result.success(SummarizationBridge.capability(activity, lang))
                    }
                    "prepare" -> result.success("unavailable")
                    "summarize" -> {
                        val lang = (call.arguments as? Map<*, *>)?.get("lang")
                            as? String ?: "en"
                        try {
                            SummarizationBridge.summarize(activity, lang)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error(
                                if (e.message == "needsDownload") "needsDownload"
                                else "unavailable",
                                e.message, null)
                        }
                    }
                    "cancel" -> result.success(null)
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("error", e.message, null)
            }
        }
}
