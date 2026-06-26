// Worker entry point pra Drift WASM.
// Compilado via `dart compile js web/drift_worker.dart -o web/drift_worker.js -O4`
// Esse arquivo .dart fica em web/ por convenção mas NÃO é embarcado no app.
// É só fonte do drift_worker.js — esse sim é servido como asset web.

import 'package:drift/wasm.dart';

void main() {
  WasmDatabase.workerMainForOpen();
}
