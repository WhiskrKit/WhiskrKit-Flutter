package eu.whiskrkit.flutter_whiskrkit

import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.ViewGroup
import androidx.compose.ui.platform.ComposeView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleRegistry
import androidx.lifecycle.setViewTreeLifecycleOwner
import androidx.savedstate.SavedStateRegistry
import androidx.savedstate.SavedStateRegistryController
import androidx.savedstate.SavedStateRegistryOwner
import androidx.savedstate.setViewTreeSavedStateRegistryOwner
import eu.whiskrkit.WhiskrKit
import eu.whiskrkit.ui.WhiskrKitHost
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Flutter side of the WhiskrKit bridge.
 *
 * A thin shim over the WhiskrKit Android SDK. Every method is fire-and-forget,
 * mirroring the SDK's silent-failure contract — [Result.success] completes when
 * the call is dispatched, never with a survey outcome. Failures go to Logcat
 * (tag WhiskrKit).
 *
 * [ActivityAware] is required because survey presentation needs a host mounted
 * over the current Activity's content view.
 */
class FlutterWhiskrkitPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {
    private lateinit var channel: MethodChannel
    private var applicationContext: android.content.Context? = null
    private var activity: Activity? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_whiskrkit")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "initialize" -> {
                val apiKey = call.argument<String>("apiKey")
                if (apiKey == null) {
                    result.error("bad-args", "initialize requires a String apiKey", null)
                    return
                }
                val withMockedSurveys = call.argument<Boolean>("withMockedSurveys") ?: false
                val context = applicationContext
                if (context == null) {
                    result.error("no-context", "Plugin is not attached to an engine", null)
                    return
                }
                mainHandler.post {
                    WhiskrKit.initialize(context, apiKey, withMockedSurveys)
                    attachHostIfNeeded()
                }
                result.success(null)
            }

            "present" -> {
                val surveyId = call.argument<String>("surveyId")
                if (surveyId == null) {
                    result.error("bad-args", "present requires a String surveyId", null)
                    return
                }
                mainHandler.post {
                    attachHostIfNeeded()
                    WhiskrKit.present(surveyId)
                }
                result.success(null)
            }

            "checkAndPresent" -> {
                val surveyId = call.argument<String>("surveyId")
                if (surveyId == null) {
                    result.error("bad-args", "checkAndPresent requires a String surveyId", null)
                    return
                }
                mainHandler.post {
                    attachHostIfNeeded()
                    WhiskrKit.checkAndPresent(surveyId)
                }
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    /**
     * Mounts the WhiskrKitHost composable in a ComposeView laid over the
     * current Activity's content — the equivalent of wrapping a Compose app's
     * root in `WhiskrKitHost { ... }`. All survey presentations render there;
     * with no survey on screen it draws nothing and consumes no touches.
     *
     * Called before every SDK call (tag-guarded, so at most one host exists
     * per Activity) to survive Activity recreation and hot restarts. Runs on
     * the main thread.
     */
    private fun attachHostIfNeeded() {
        val activity = activity ?: return
        val root = activity.findViewById<ViewGroup>(android.R.id.content) ?: return
        if (root.findViewWithTag<View>(HOST_TAG) != null) return

        val host = ComposeView(activity).apply { tag = HOST_TAG }

        // FlutterActivity is a plain android.app.Activity, so unlike a
        // ComponentActivity its view tree carries no ViewTree owners — which
        // ComposeView requires (it throws "ViewTreeLifecycleOwner not found"
        // otherwise). Provide a host-scoped owner, torn down with the view so
        // the recomposer doesn't outlive the activity.
        val owner = ComposeHostOwner()
        host.setViewTreeLifecycleOwner(owner)
        host.setViewTreeSavedStateRegistryOwner(owner)
        owner.create()
        host.addOnAttachStateChangeListener(
            object : View.OnAttachStateChangeListener {
                override fun onViewAttachedToWindow(v: View) = Unit

                override fun onViewDetachedFromWindow(v: View) = owner.destroy()
            },
        )

        host.setContent { WhiskrKitHost { } }
        root.addView(
            host,
            ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        applicationContext = null
    }

    // region ActivityAware

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    // endregion

    companion object {
        private const val HOST_TAG = "whiskrkit_survey_host"
    }
}

/**
 * Minimal lifecycle + saved-state owner for the survey host's ComposeView,
 * since FlutterActivity provides neither on its view tree.
 *
 * Kept RESUMED for the view's whole time on screen (the host is an overlay:
 * with no survey showing it renders nothing, so there is nothing to pause).
 * Note: the saved-state registry starts empty each time, so unlike on native
 * Compose hosts, an open survey does not survive activity recreation.
 */
private class ComposeHostOwner : SavedStateRegistryOwner {
    private val lifecycleRegistry = LifecycleRegistry(this)
    private val savedStateController = SavedStateRegistryController.create(this)

    override val lifecycle: Lifecycle
        get() = lifecycleRegistry

    override val savedStateRegistry: SavedStateRegistry
        get() = savedStateController.savedStateRegistry

    fun create() {
        savedStateController.performRestore(null)
        lifecycleRegistry.currentState = Lifecycle.State.RESUMED
    }

    fun destroy() {
        lifecycleRegistry.currentState = Lifecycle.State.DESTROYED
    }
}
