# CLAUDE.md — AutoLog

> Instruções operacionais para agentes de IA (Claude Code) trabalhando neste repositório.
> Leia também `docs/PRD.md` (o quê/por quê) e `docs/ARCHITECTURE.md` (como). Em conflito, `docs/ARCHITECTURE.md` vence em decisões técnicas; `docs/PRD.md` vence em escopo.

## Papéis

- **André = Diretor / Tester.** Define direção, revisa, testa em dispositivo real. Não escreve implementação.
- **Você (agente) = desenvolvedor.** Implementa, gera assets, escreve testes, mantém docs atualizados. Trabalha de forma autônoma até a tarefa fechar.

## Regras de ouro

1. **Offline-first na escrita, sempre.** Toda escrita do usuário grava no Drift primeiro e sincroniza depois. Nunca bloqueie a UI esperando rede. Se você implementar uma escrita que vai direto ao Supabase sem passar pelo local, está errado.
2. **Cálculo de consumo é sagrado.** Siga a regra de tanque cheio em `docs/PRD.md §6` à risca. Nunca exiba um consumo calculado sobre baseline insuficiente — exiba "—". Escreva testes unitários para essa lógica antes de considerá-la pronta.
3. **Scan nunca salva cego.** O resultado da IA **pré-preenche** o formulário; o usuário **revisa e confirma**. Não existe fluxo "foto → salvo direto".
3b. **Fallback manual é o caminho base, não um extra.** Todo registro tem que ser preenchível na mão, sem IA, sem cota, offline. O scan é um atalho que alimenta o mesmo formulário manual. Se o scan falhar, a cota esgotar ou não houver rede, o usuário registra normalmente. Nunca implemente um fluxo onde a IA seja obrigatória para registrar.
4. **Chave da API Anthropic nunca toca o app.** Toda chamada ao modelo passa por Edge Function no backend. Se você for tentado a colocar a chave no Dart, pare.
5. **Cota é validada no backend.** O client pode mostrar a cota, mas a verdade é a `usage_quota` no servidor. Não confie no client para gating de premium.
6. **Soft delete only.** Nada de hard delete no MVP. `deleted_at` + filtro nas queries.
7. **UUID no client** para todas as entidades sincronizáveis.
8. **Entitlement de assinatura é agnóstico de plataforma.** `is_premium` mora no backend, atrelado à CONTA, não ao dispositivo nem à loja. Quem assina na web usa no mobile e vice-versa. NUNCA amarre a assinatura à plataforma onde foi comprada. Validação de compra (Play/App Store/Stripe) acontece no backend, unificada via RevenueCat.
9. **Dentro do app das lojas, não linkar para pagamento externo.** Não coloque botão/link "assine mais barato no site" dentro do app Android ou iOS — é violação de política de loja. Preço web menor é divulgado FORA dos apps. Ver `docs/ARCHITECTURE.md §8`.
10. **Captura de imagem é abstraída por plataforma.** Use a interface `ImageSource` (câmera no mobile, upload na web). O pipeline de scan recebe bytes e não sabe a origem. Não acople o fluxo de IA à câmera.

## Convenções de código

- Dart/Flutter idiomático. `dart format` + `flutter analyze` sem warnings antes de fechar tarefa.
- Modelos de domínio com **freezed** + **json_serializable**.
- Estado com **Riverpod** (providers tipados; evitar `StateProvider` solto para estado complexo).
- Uma responsabilidade por arquivo. Repositórios são a única fonte de verdade por entidade.
- Strings de UI em PT-BR. Preparar para i18n (não traduzir agora, mas não hardcodar de forma que impeça depois).
- Valores monetários: `decimal` no domínio, formatação R$ só na borda (UI). Nunca `double` para dinheiro em lógica de negócio.

## Padrão de desenvolvimento (papéis por modelo)

> Este é o padrão fixo. Granularidade = **por tarefa do `docs/BACKLOG.md`**. Sprint = gate de homologação do Diretor.

### Ciclo de cada tarefa

1. **Opus — Especificação + TDD** 🔴
   - Lê a tarefa; confirma que as dependências estão prontas.
   - Escreve um spec curto: escopo, contrato/interface, critérios de aceite, *definition of done*.
   - Escreve os **testes falhando** (red) cobrindo a lógica — obrigatório nas áreas sagradas (consumo, sync, parse do scan, cota).
   - Entrega spec + testes ao Sonnet.
2. **Sonnet — Implementação** 🟢
   - Recebe spec + testes. Implementa na vertical (model → repository → service → UI) até **green**; refatora.
   - `dart format` + `flutter analyze` sem warnings.
3. **Haiku — Code review / QA** ✅
   - Revisa o diff contra o spec **e** as Regras de Ouro acima.
   - Confirma: testes verdes, analyze limpo, regras respeitadas. Reprovou → volta ao Sonnet com achados; aprovou → tarefa fechada.
   - Marca o item no `docs/BACKLOG.md`; atualiza `docs/ARCHITECTURE.md` se a arquitetura mudou.
4. **André (Diretor) — Homologação** 🤝
   - A cada **sprint completa**, testa em device/simulador real e aprova antes da próxima sprint.

A orquestração Opus → Sonnet → Haiku roda numa única sessão: o Opus segura o contexto e despacha sub-agentes (`Agent(model: sonnet)` e `Agent(model: haiku)`).

### Quando a homologação reprova

O Opus classifica a causa-raiz e re-entra no ciclo pelo ponto certo:

- **A. Bug / regressão** (specado certo, código errado): Opus escreve **teste de regressão que reproduz o bug** → Sonnet corrige → Haiku re-revisa. Reforçar o checklist do Haiku.
- **B. Spec errado / incompleto** (fiel ao spec, mas o spec estava errado — culpa do Opus): Opus revisa spec + testes → Sonnet implementa o delta → Haiku revisa.
- **C. Mudança de direção / UX**: requisito novo → mini-brainstorm → vira tarefa/ajuste → ciclo normal.

Regras do gate:
- **Toda falha vira teste.** Bug homologado sem teste de regressão não está resolvido.
- **Sprint reprovada bloqueia a próxima** (backlog é sequenciado por dependência).
- **Registro em `docs/HOMOLOG.md`**: uma linha por homologação (data, o que foi testado, veredito, falhas, resolução).
- **Re-homologação testa só o que falhou**, não a sprint inteira.

### Plataforma durante o desenvolvimento
Desenvolver e testar no **simulador/device iOS** (Mac, integração mais simples). A estratégia de **lançamento permanece Android-primeiro** conforme `docs/PRD.md §3` — não reescrever os docs. Sprints 0–5 são Dart/Flutter agnósticas de plataforma; a divergência real só aparece na Sprint 6 (billing).

## Testes — o que sempre exige cobertura
- Cálculo de consumo (todos os casos: primeiro abastecimento, parciais, sequência de cheios).
- Lógica de sync (pending → synced, resolução de conflito).
- Parse defensivo do JSON do scan (campos null, JSON malformado, markdown acidental).
- Checagem de cota.

## O que NÃO fazer sem aprovação do Diretor
- Adicionar dependências pesadas novas (justifique antes).
- Mudar o modelo de dados depois de definido (migração tem custo).
- Implementar features fora do escopo do MVP (`docs/PRD.md §3` lista o que NÃO entra).
- Tocar em fluxo de billing sem revisão (dinheiro real).

## Stack de referência rápida
Flutter (Android → Web → iOS) · Riverpod · Drift (SQLite / WASM na web) · Supabase (Postgres/Auth/Edge Functions) · ML Kit (OCR odômetro, só mobile) · Claude Haiku 4.5 (extração de cupom, via backend) · Billing: Google Play + App Store IAP + Stripe, unificados via RevenueCat.
