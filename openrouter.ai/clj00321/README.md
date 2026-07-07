# 🤖 OpenRouter AI Models Export

Automatiseret export af samtlige tilgængelige AI-modeller fra [OpenRouter.ai](https://openrouter.ai) via deres public `/models` API-endpoint.

---

## 📂 Filer i dette repo

| Fil | Beskrivelse |
|---|---|
| `openrouter.ai_models_alfa2.sh` | Bash-script der henter, parser og eksporterer modeldata |
| `openrouter.ai_models_alfa2.json` | Rå JSON-output (fuld struktur, pretty-printed via `jq`) |
| `openrouter.ai_models_alfa2.csv` | Flad CSV-export, 32 kolonner, en række pr. model |

---

## ⚙️ Hvad scriptet gør

1. 📥 Installerer `curl` + `jq` (Debian 13 / non-interactive)
2. 🌐 Kalder `https://openrouter.ai/api/v1/models?output_modalities=all`
3. 🗂️ Gemmer rå JSON til `openrouter.ai_models_alfa2.json`
4. 📊 Parser JSON → CSV med udvidede developer/model-kolonner
5. ✅ Printer antal eksporterede modeller ved afslutning

---

## 📊 Datasæt-overblik (seneste kørsel: 2026-07-07 04:34)

- **Total antal modeller:** 433
- **Gratis modeller (`:free`):** 26
- **Betalte modeller:** 407
- **Unikke developers:** 82
- **Context length spænd:** 0 – 10000000 tokens

### 🏢 Top 15 developers efter antal modeller

| Developer | Antal modeller |
|---|---|
| OpenAI | 74 |
| Qwen | 50 |
| Google | 37 |
| Mistral | 21 |
| Anthropic | 17 |
| NVIDIA | 14 |
| Meta | 12 |
| Z.ai | 12 |
| DeepSeek | 11 |
| Recraft | 11 |
| MiniMax | 9 |
| Cohere | 8 |
| Perplexity | 7 |
| xAI | 7 |
| MoonshotAI | 6 |

### 🏗️ Input-modalitet fordeling (top 5)

| Modalitet | Antal modeller |
|---|---|
| `text` | 198 |
| `text|image` | 87 |
| `text|image|file` | 37 |
| `text|image|video` | 17 |
| `image|text|file` | 15 |

---

## 🧾 CSV-kolonner (fuld liste)

- `id`
- `canonical_slug`
- `name`
- `developer`
- `model`
- `created`
- `description`
- `context_length`
- `architecture_input_modalities`
- `architecture_output_modalities`
- `architecture_tokenizer`
- `architecture_instruct_type`
- `pricing_prompt`
- `pricing_completion`
- `pricing_request`
- `pricing_image`
- `pricing_web_search`
- `pricing_internal_reasoning`
- `pricing_input_cache_read`
- `pricing_input_cache_write`
- `top_provider_context_length`
- `top_provider_max_completion_tokens`
- `top_provider_is_moderated`
- `supported_parameters`
- `default_parameters`
- `expiration_date`
- `knowledge_cutoff`
- `links`
- `per_request_limits`
- `supported_voices`
- `hugging_face_id`
- `benchmarks_design_arena`

---

## 🔁 Genkørsel / opdatering

Scriptet er idempotent — gentagne kørsler overskriver blot `.json`/`.csv`/`README.md` med et frisk snapshot.

```bash
0 4 * * * openrouter.ai_models_alfa2.sh >> /var/log/openrouter_export.log 2>&1
```
