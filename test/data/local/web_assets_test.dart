// Regressão W1 (handoff 25/06): garante que os assets do Drift web existem
// em `web/`. Sem eles, o app web compila mas trava em runtime ao abrir o
// banco (404 no sqlite3.wasm / drift_worker.js).
//
// Esse teste roda na VM (não no browser) — não exercita o caminho real
// do WasmDatabase, só verifica que CI/dev não deletaram os arquivos.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web/sqlite3.wasm existe e tem tamanho razoável', () {
    final f = File('web/sqlite3.wasm');
    expect(f.existsSync(), isTrue,
        reason: 'Faltando web/sqlite3.wasm. Baixar do release sqlite3.dart '
            'que case com a versão instalada (ver handoff Sprint 8).');
    // Sanidade: o release oficial tem >500KB. Se for menor, baixou errado.
    expect(f.lengthSync(), greaterThan(500 * 1024),
        reason: 'web/sqlite3.wasm tem ${f.lengthSync()} bytes — provável '
            'arquivo corrompido ou release errado.');
  });

  test('web/drift_worker.js existe e tem tamanho razoável', () {
    final f = File('web/drift_worker.js');
    expect(f.existsSync(), isTrue,
        reason: 'Faltando web/drift_worker.js. Gerar com '
            '`dart compile js web/drift_worker.dart -o web/drift_worker.js -O4`.');
    // dart compile js -O4 do worker simples sai com 200-500KB.
    expect(f.lengthSync(), greaterThan(100 * 1024),
        reason: 'web/drift_worker.js tem ${f.lengthSync()} bytes — provável '
            'compilação incompleta.');
  });
}
