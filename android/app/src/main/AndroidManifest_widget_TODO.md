# Android Home Widget — TODO (Sprint futura)

> Status: **NÃO IMPLEMENTADO**. Widget Android fica para sprint posterior.
> Sprint 6.BB focou iOS WidgetKit. Android entra quando houver sprint dedicada.

---

## O que precisará ser feito

### 1. AppWidgetProvider Kotlin

Criar `android/app/src/main/kotlin/com/oddcar/autolog/AutoLogWidgetProvider.kt`:

```kotlin
class AutoLogWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        // home_widget salva com prefixo "flutter." no Android
        val headline = prefs.getString("flutter.headline", "AutoLog") ?: "AutoLog"
        val sub = prefs.getString("flutter.sub", "") ?: ""

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.autolog_widget)
            views.setTextViewText(R.id.widget_headline, headline)
            views.setTextViewText(R.id.widget_sub, sub)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
```

### 2. Layout XML

Criar `android/app/src/main/res/layout/autolog_widget.xml` com TextView para
headline e sub.

### 3. AppWidget info XML

Criar `android/app/src/main/res/xml/autolog_widget_info.xml` com metadados do
widget (minWidth, minHeight, updatePeriodMillis, previewImage).

### 4. AndroidManifest.xml — registrar receiver

Adicionar dentro de `<application>` em
`android/app/src/main/AndroidManifest.xml`:

```xml
<receiver
    android:name=".AutoLogWidgetProvider"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/autolog_widget_info" />
</receiver>
```

### 5. Dart — nome do provider

O `HomeWidgetService` já passa `androidName: 'AutoLogWidgetProvider'` na chamada
`HomeWidget.updateWidget`. Nenhuma alteração necessária no Dart quando o receiver
estiver registrado.

---

## Notas importantes

- No Android, `home_widget` usa `SharedPreferences` com prefixo `flutter.`
  (diferente do iOS que usa `UserDefaults` com App Group).
- Não é necessário App Group no Android — `SharedPreferences` é acessível
  dentro do mesmo APK.
- O `updatePeriodMillis` no widget info define refresh periódico (mínimo 30min
  no Android). O refresh por evento (salvar abastecimento) funciona via
  `HomeWidget.updateWidget` sem limitação adicional.
