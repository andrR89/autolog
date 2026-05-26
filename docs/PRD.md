# PRD — App de Gestão Veicular Pessoal (codinome: *AutoLog*)

> Documento de produto. Define **o quê** e **por quê**. Para **como**, ver `ARCHITECTURE.md`.

## 1. Tese central

O mercado de gestão veicular pessoal já está ocupado (Drivvo, Fuelio, Carmana). Competir feature-a-feature é inviável. **O diferencial é eliminar a fricção de input.**

> A causa nº1 de abandono nesse nicho é a preguiça de registrar abastecimento manualmente. Quem resolve isso, ganha.

**Proposta de valor:** "Tire uma foto. O app preenche o resto."

O usuário fotografa o cupom fiscal do posto e/ou o odômetro, e a IA extrai litros, preço/litro, total, data e quilometragem automaticamente. **O registro manual sempre existe como caminho base** — funciona offline, sem cota, de graça, para sempre. A IA acelera; o manual garante.

## 2. Público-alvo

- Pessoa física, dono de 1–3 veículos (carro/moto).
- **Sem** recursos de pessoa jurídica / frota / gestão de motoristas no MVP.
- Brasil, português (BR). Valores em R$, litros, km.
- Perfil: quer controle de gastos e consumo sem virar trabalho.

## 3. Plataformas

> **Mobile-primeiro, web logo depois. Arquitetar para web desde já; lançar em sequência, não simultaneamente.**

| Plataforma | Quando | Observações |
|---|---|---|
| **Android** | Lançamento (1º) | Maior base no Brasil, publicação mais simples/barata. |
| **Web** (Flutter Web) | 2ª onda | SEO/descoberta + quem prefere lançar dados no desktop. |
| **iOS** | 3ª onda | Reavaliar regras de loja na época (ver `ARCHITECTURE.md §8`). |

**Divergências de plataforma a respeitar (detalhe técnico em `ARCHITECTURE.md §7`):**
- Captura de imagem do scan: câmera (mobile) vs. upload de arquivo (web). A IA é a mesma; a captura difere.
- OCR de odômetro on-device (ML Kit): **só mobile**. Na web, odômetro é manual ou via scan multimodal.
- Billing: Google Play (Android), Stripe (web), App Store IAP (iOS). Convergem num único entitlement no backend.

## 4. Escopo do MVP

### Inclui
1. **Cadastro de veículo** (apelido, marca/modelo, placa opcional, tipo de combustível, odômetro inicial).
2. **Registro de abastecimento** com:
   - **Scan por IA** (foto do cupom → JSON estruturado). *Esta é a tese, entra no v1.*
   - **Leitura de odômetro** por foto (OCR no device — só mobile).
   - **Entrada manual** — caminho base, sempre disponível, sem IA, sem cota, offline.
3. **Cálculo de consumo**: km/l, custo/km, custo total por período. Trata tanque cheio vs. parcial corretamente (ver regra em §7).
4. **Despesas gerais** (manutenção, lavagem, estacionamento, multas) — entrada manual.
5. **Lembretes** simples: revisão por km ou data, vencimento de documentos (IPVA, seguro).
6. **Relatórios**: gasto por mês, consumo médio, evolução de preço/litro.
7. **Sync na nuvem** + auth (conta do usuário, dados isolados).
8. **Controle de cota de scan** (freemium — ver §5).

### NÃO inclui no MVP (backlog futuro)
- Frota / multiusuário / PJ.
- Scan de notas de oficina/peças/seguro (só combustível no v1).
- Integração com OBD-II.
- Exportação fiscal / relatórios contábeis.
- Geolocalização de postos / comparação de preços regional.
- Anúncios (ver §6 — decisão deliberada de não incluir no MVP).

## 5. Monetização

**Modelo:** Freemium com assinatura (mensal/anual). Entitlement único, agnóstico de plataforma.

| Recurso | Free | Premium |
|---|---|---|
| Registro manual | Ilimitado, offline, sempre | Ilimitado |
| Scan por IA | **5 / mês** (cota) | Ilimitado |
| Veículos | 1 | Até 3+ |
| Relatórios básicos | ✅ | ✅ |
| Relatórios avançados | ❌ | ✅ |
| Backup na nuvem | ✅ | ✅ |

**Cota grátis = 5 scans por mês** (não lifetime). Por mês mantém o usuário free voltando e engajado — usuário ativo é quem converte e quem indica. A cota é **marketing, não generosidade**: é o "aha moment" que mostra a mágica antes do paywall.

**Racional econômico:** custo de IA por scan < US$ 0,01 (ver §6 da `ARCHITECTURE.md`). Um usuário free que esgota a cota custa ~5 centavos de dólar/mês. A margem da assinatura é alta; a cota grátis se paga em aquisição.

**Preço diferenciado por canal:** a web (Stripe) pode ser mais barata que o mobile, porque as taxas de loja (15–30%) não incidem. **Esse preço menor é divulgado FORA dos apps** (site, email, redes) — nunca dentro do app, por regra das lojas. Detalhe em `ARCHITECTURE.md §8`.

## 6. Anúncios — decisão: NÃO no MVP

Decisão deliberada de **não incluir anúncios no MVP**. Racional:
- Anúncio (banner/intersticial) corrói a tese central de "app limpo, sem fricção" e canibaliza o valor percebido do premium.
- ROI de display ad em app de nicho é baixo (centavos/usuário/mês) e não compensa o atrito de UX + consentimento LGPD.

**Caminho futuro (pós-MVP), se houver massa de usuários free que nunca converte:** introduzir **rewarded ad opcional** ("assista um anúncio, ganhe +1 scan este mês"). É o usuário que opta, então não polui a experiência de quem não quer, e cria uma terceira via entre free e assinatura. Decisão a tomar **com dados de conversão na mão**, não antes.

## 7. Regras de negócio críticas

### Cálculo de consumo (a armadilha clássica)
O consumo só pode ser calculado **entre dois abastecimentos de tanque cheio**. Abastecimento parcial não fecha um ciclo de medição.

- Cada registro tem flag `tanque_cheio` (bool).
- km/l = (km_atual − km_do_último_tanque_cheio) / (soma de litros desde o último tanque cheio, inclusive o atual).
- Se houver parciais entre dois cheios, somam-se os litros de todos eles.
- Primeiro abastecimento nunca gera consumo (não há baseline).
- Exibir consumo como "—" quando não há baseline suficiente, nunca um número errado.

### Odômetro
- Deve ser >= odômetro inicial do veículo (bloqueante).
- Deve ser monotônico crescente **entre datas distintas** (bloqueante).
- Mesma data permite qualquer ordem (não registramos hora do dia).

## 8. Métricas de sucesso (pós-lançamento)
- % de registros feitos via scan vs. manual (mede se a tese pega).
- Retenção D7 / D30.
- Taxa de conversão free → premium.
- Nº médio de registros por usuário ativo / mês.

## 9. Riscos
| Risco | Mitigação |
|---|---|
| Scan erra em cupons de layout incomum | Sempre mostrar campos extraídos para revisão antes de salvar; nunca salvar cego. Fallback manual sempre presente. |
| Sinal ruim no posto (momento do registro) | Sync otimista: salva local, sincroniza depois. Registro manual funciona 100% offline. |
| Custo de IA escalar | Cota no free; OCR no device para odômetro; Haiku (não Sonnet/Opus). |
| Mercado saturado | Posicionamento 100% em "sem digitação", não em quantidade de features. |
| Regras de loja sobre billing mudam | Modelo conservador (ver `ARCHITECTURE.md §8`); revisar políticas antes de cada publicação. |
