package dev.sidebyside.sidebyside

import android.content.ContentValues
import android.content.pm.PackageManager
import android.provider.CalendarContract
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

// v0.4.0 (#16): writes coded all-day "SxS" events into a user-picked visible
// calendar (v0.5.0 picker; first-visible kept as fallback). Own 60-line
// channel instead of device_calendar — its 4.x pins timezone <0.11 and can't
// coexist with flutter_local_notifications 22.
class MainActivity : FlutterActivity() {
    private var pendingMethod: String? = null
    private var pendingArgs: Map<*, *>? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "addEvents" || call.method == "listCalendars") {
                    if (hasCalendarPermission()) {
                        route(call.method, call.arguments as? Map<*, *>, result)
                    } else {
                        pendingMethod = call.method
                        pendingArgs = call.arguments as? Map<*, *>
                        pendingResult = result
                        requestPermissions(
                            arrayOf(PERM_READ, PERM_WRITE), REQ
                        )
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQ) return
        val granted = grantResults.isNotEmpty() &&
            grantResults.all { it == PackageManager.PERMISSION_GRANTED }
        val result = pendingResult
        val method = pendingMethod
        val args = pendingArgs
        pendingResult = null
        pendingMethod = null
        pendingArgs = null
        if (!granted) result?.success("permission")
        else route(method, args, result)
    }

    private fun route(
        method: String?,
        args: Map<*, *>?,
        result: MethodChannel.Result?
    ) {
        if (method == "listCalendars") listCalendars(result)
        else addEvents(args, result)
    }

    private fun hasCalendarPermission(): Boolean =
        ContextCompat.checkSelfPermission(this, PERM_READ) ==
            PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(this, PERM_WRITE) ==
            PackageManager.PERMISSION_GRANTED

    private fun addEvents(args: Map<*, *>?, result: MethodChannel.Result?) {
        try {
            val days = (args?.get("days") as? Number)?.toInt() ?: 14
            val title = args?.get("title") as? String ?: "SxS"
            val calId = (args?.get("calendarId") as? Number)?.toLong()
                ?: firstCalendarId()
            if (calId == null) {
                result?.success("none")
                return
            }
            val cal = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val tz = cal.timeZone.id
            repeat(days) {
                val start = cal.timeInMillis
                cal.add(Calendar.DAY_OF_MONTH, 1)
                val values = ContentValues().apply {
                    put(CalendarContract.Events.CALENDAR_ID, calId)
                    put(CalendarContract.Events.TITLE, title)
                    put(CalendarContract.Events.ALL_DAY, 1)
                    put(CalendarContract.Events.DTSTART, start)
                    put(CalendarContract.Events.DTEND, cal.timeInMillis)
                    put(CalendarContract.Events.EVENT_TIMEZONE, tz)
                }
                contentResolver.insert(CalendarContract.Events.CONTENT_URI, values)
            }
            result?.success("ok")
        } catch (e: Exception) {
            result?.error("calendar", e.message, null)
        }
    }

    private fun listCalendars(result: MethodChannel.Result?) {
        try {
            val out = ArrayList<Map<String, Any>>()
            contentResolver.query(
                CalendarContract.Calendars.CONTENT_URI,
                arrayOf(
                    CalendarContract.Calendars._ID,
                    CalendarContract.Calendars.CALENDAR_DISPLAY_NAME
                ),
                "${CalendarContract.Calendars.VISIBLE} = 1",
                null,
                "${CalendarContract.Calendars._ID} ASC"
            )?.use {
                while (it.moveToNext()) out.add(
                    mapOf("id" to it.getLong(0), "name" to it.getString(1))
                )
            }
            result?.success(out)
        } catch (e: Exception) {
            result?.error("calendar", e.message, null)
        }
    }

    private fun firstCalendarId(): Long? =
        contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            arrayOf(CalendarContract.Calendars._ID),
            "${CalendarContract.Calendars.VISIBLE} = 1",
            null,
            "${CalendarContract.Calendars._ID} ASC"
        )?.use { if (it.moveToFirst()) it.getLong(0) else null }

    companion object {
        private const val CHANNEL = "sidebyside/calendar"
        private const val REQ = 42
        private const val PERM_READ = android.Manifest.permission.READ_CALENDAR
        private const val PERM_WRITE = android.Manifest.permission.WRITE_CALENDAR
    }
}
