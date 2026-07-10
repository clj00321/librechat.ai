#!/usr/bin/env bash
set -euo pipefail
# ------------------------------------------------------------
# Debian 13 dependencies
# ------------------------------------------------------------
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends curl
sudo apt-get install -y --no-install-recommends jq
# ------------------------------------------------------------
# OpenRouter.ai api-key
# ------------------------------------------------------------
API_KEY="${OPENROUTER_API_KEY:-}"   # Optional: set your key for auth
# ------------------------------------------------------------
# Folder/Files same as script file name
SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
SCRIPT_BASENAME=$(basename "$SCRIPT_PATH" .sh)
OUTPUT_JSON="$SCRIPT_DIR/${SCRIPT_BASENAME}.json"
OUTPUT_CSV="$SCRIPT_DIR/${SCRIPT_BASENAME}.csv"
API_URL="https://openrouter.ai/api/v1/models?output_modalities=all"
RSS_URL="https://openrouter.ai/api/v1/models?use_rss=true"
RSS_OUTPUT="$SCRIPT_DIR/${SCRIPT_BASENAME}.rss"

# Hent RSS feed
if [[ -n "$API_KEY" ]]; then
  curl -sf -H "Authorization: Bearer $API_KEY" "$RSS_URL" > "$RSS_OUTPUT"
else
  curl -sf "$RSS_URL" > "$RSS_OUTPUT"
fi
echo "RSS eksporteret til: $RSS_OUTPUT"
# ------------------------------------------------------------
# OpenRouter.ai Fetching all models
# ------------------------------------------------------------
if [[ -n "$API_KEY" ]]; then
  JSON=$(curl -sf -H "Authorization: Bearer $API_KEY" "$API_URL")
else
  JSON=$(curl -sf "$API_URL")
fi
# Export raw JSON til samme mappe
echo "$JSON" | jq '.' > "$OUTPUT_JSON"
echo "JSON eksporteret til: $OUTPUT_JSON"

# CSV Header — alle felter + nye developer & model kolonner
echo "id,canonical_slug,name,developer,model,created,description,context_length,\
architecture_input_modalities,architecture_output_modalities,architecture_tokenizer,architecture_instruct_type,\
pricing_prompt,pricing_completion,pricing_request,pricing_image,pricing_web_search,\
pricing_internal_reasoning,pricing_input_cache_read,pricing_input_cache_write,\
top_provider_context_length,top_provider_max_completion_tokens,top_provider_is_moderated,\
supported_parameters,default_parameters,expiration_date,knowledge_cutoff,links,per_request_limits,supported_voices,hugging_face_id,\
benchmarks_design_arena" > "$OUTPUT_CSV"

# Parse hver model med jq og tilføj rækker
echo "$JSON" | jq -r '
  .data[] |
  [
    .id // "",
    .canonical_slug // "",
    .name // "",
    (.name | split(":")[0] | gsub(" "; "")),
    (.name | split(":")[1:] | join(":") | gsub("^ "; "")),
    (.created | tostring),
    (.description // "" | gsub("\n";" ") | gsub(",";";")),
    (.context_length | tostring),
    (.architecture.input_modalities  | join("|")),
    (.architecture.output_modalities | join("|")),
    (.architecture.tokenizer // ""),
    (.architecture.instruct_type // ""),
    (.pricing.prompt // ""),
    (.pricing.completion // ""),
    (.pricing.request // ""),
    (.pricing.image // ""),
    (.pricing.web_search // ""),
    (.pricing.internal_reasoning // ""),
    (.pricing.input_cache_read // ""),
    (.pricing.input_cache_write // ""),
    ((.top_provider.context_length // "") | tostring),
    ((.top_provider.max_completion_tokens // "") | tostring),
    ((.top_provider.is_moderated // "") | tostring),
    (.supported_parameters // [] | join("|")),
    (.default_parameters // {} | tostring | gsub(",";";")),
    (.expiration_date // ""),
    (.knowledge_cutoff // ""),
    (.links | tostring | gsub(",";";")),
    (.per_request_limits | tostring | gsub(",";";")),
    (.supported_voices | tostring | gsub(",";";")),
    (.hugging_face_id // ""),
    (.benchmarks.design_arena // [] | map("\(.arena)/\(.category):elo=\(.elo),wr=\(.win_rate),rank=\(.rank)") | join("|"))
  ] | @csv
' >> "$OUTPUT_CSV"

COUNT=$(tail -n +2 "$OUTPUT_CSV" | wc -l)
echo "Done! $COUNT modeller eksporteret til:"
echo "  CSV  -> $OUTPUT_CSV"
echo "  JSON -> $OUTPUT_JSON"
echo "  RSS  -> $RSS_OUTPUT"

# ------------------------------------------------------------
# README.md — genereres dynamisk fra $JSON (samme data som CSV/JSON export)
# ------------------------------------------------------------
OUTPUT_README="$SCRIPT_DIR/README.md"

TOTAL=$(echo "$JSON" | jq '.data | length')
FREE=$(echo "$JSON" | jq '[.data[] | select(.id | test(":free$"))] | length')
PAID=$((TOTAL - FREE))
DEV_COUNT=$(echo "$JSON" | jq '[.data[].name | split(":")[0]] | unique | length')
CTX_MAX=$(echo "$JSON" | jq '[.data[].context_length] | max')
CTX_MIN=$(echo "$JSON" | jq '[.data[].context_length] | min')

TOP_DEVS=$(echo "$JSON" | jq -r '
  [.data[] | (.name | split(":")[0])]
  | group_by(.) | map({dev: .[0], count: length})
  | sort_by(-.count) | .[0:15][]
  | "| \(.dev) | \(.count) |"
')

TOP_MODALITIES=$(echo "$JSON" | jq -r '
  [.data[].architecture.input_modalities | join("|")]
  | group_by(.) | map({m: .[0], count: length})
  | sort_by(-.count) | .[0:5][]
  | "| `\(.m)` | \(.count) |"
')

cat > "$OUTPUT_README" << EOF
# 🤖 OpenRouter AI Models Export

Automatiseret export af samtlige tilgængelige AI-modeller fra [OpenRouter.ai](https://openrouter.ai) via deres public \`/models\` API-endpoint.

---

## 📂 Filer i dette repo

| Fil | Beskrivelse |
|---|---|
| \`${SCRIPT_BASENAME}.sh\` | Bash-script der henter, parser og eksporterer modeldata |
| \`${SCRIPT_BASENAME}.json\` | Rå JSON-output (fuld struktur, pretty-printed via \`jq\`) |
| \`${SCRIPT_BASENAME}.csv\` | Flad CSV-export, 32 kolonner, en række pr. model |
| \`${SCRIPT_BASENAME}.rss\` | RSS-feed med nye modeller (seneste snapshot) |

---

## ⚙️ Hvad scriptet gør

1. 📥 Installerer \`curl\` + \`jq\` (Debian 13 / non-interactive)
2. 🌐 Kalder \`https://openrouter.ai/api/v1/models?output_modalities=all\`
3. 🗂️ Gemmer rå JSON til \`${SCRIPT_BASENAME}.json\`
4. 📊 Parser JSON → CSV med udvidede developer/model-kolonner
5. ✅ Printer antal eksporterede modeller ved afslutning

---

## 📊 Datasæt-overblik (seneste kørsel: $(date '+%Y-%m-%d %H:%M'))

- **Total antal modeller:** $TOTAL
- **Gratis modeller (\`:free\`):** $FREE
- **Betalte modeller:** $PAID
- **Unikke developers:** $DEV_COUNT
- **Context length spænd:** $CTX_MIN – $CTX_MAX tokens

### 🏢 Top 15 developers efter antal modeller

| Developer | Antal modeller |
|---|---|
$TOP_DEVS

### 🏗️ Input-modalitet fordeling (top 5)

| Modalitet | Antal modeller |
|---|---|
$TOP_MODALITIES

---

## 🧾 CSV-kolonner (fuld liste)

$(head -1 "$OUTPUT_CSV" | tr ',' '\n' | sed 's/^/- \`/;s/$/\`/')

---

## 🔁 Genkørsel / opdatering

Scriptet er idempotent — gentagne kørsler overskriver blot \`.json\`/\`.csv\`/\`README.md\` med et frisk snapshot.

\`\`\`bash
0 4 * * * $SCRIPT_PATH >> /var/log/openrouter_export.log 2>&1
\`\`\`
EOF

echo "README genereret -> $OUTPUT_README"
