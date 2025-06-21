#!/bin/bash

# ==========================================
# Color Definitions
# ==========================================
# Standard colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Bold colors
BOLD_RED='\033[1;31m'
BOLD_GREEN='\033[1;32m'
BOLD_YELLOW='\033[1;33m'
BOLD_BLUE='\033[1;34m'
BOLD_PURPLE='\033[1;35m'
BOLD_CYAN='\033[1;36m'
BOLD_WHITE='\033[1;37m'

# ==========================================
# Banner Display
# ==========================================
function display_banner() {
    echo "========================================"
    echo -e "${YELLOW} Simple script is made by EZ-LABS${NC}"
    echo -e "-------------------------------------"

    echo -e "${BLUE}"
    echo -e " ███████╗███████╗     ██╗      █████╗ ██████╗ ███████╗"
    echo -e " ██╔════╝╚══███╔╝     ██║     ██╔══██╗██╔══██╗██╔════╝"
    echo -e " █████╗    ███╔╝█████╗██║     ███████║██████╔╝███████╗"
    echo -e " ██╔══╝   ███╔╝ ╚════╝██║     ██╔══██║██╔══██╗╚════██║"
    echo -e " ███████╗███████╗     ███████╗██║  ██║██████╔╝███████║"
    echo -e " ╚══════╝╚══════╝     ╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝"
    echo -e "${NC}"

    echo -e "${PURPLE}╭───────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│  ${YELLOW}⚡ ${WHITE}S i m p l i f y i n g   D e v e l o p m e n t ${YELLOW}⚡  ${CYAN}│${NC}"
    echo -e "${PURPLE}╰───────────────────────────────────────────────────────╯${NC}"

    echo -e "\n${GREEN}🚀 Node.js Tools  •  ${RED}Linux Automation  •  ${BLUE}Cloud Solutions${NC}\n"
    echo -e "${YELLOW}Github: ${GREEN}https://github.com/ezlabs-nodes${NC}"
    echo -e "${YELLOW}Telegram: ${GREEN}https://t.me/EzLabsNodes${NC}"
    echo -e "${YELLOW}Twitter: ${GREEN}@EzlabsNodes${NC}"
    echo -e "${YELLOW}Medium: ${GREEN}https://medium.com/@ezlabsnodes/${NC}"
    echo "======================================================="
}

# ==========================================
# Display Banner
# ==========================================
display_banner

# --- Configuration ---
STORAGE_RPC_PORT="5678"
STORAGE_RPC="http://localhost:$STORAGE_RPC_PORT"
PARENT_RPC="https://0g-evm.maouam.nodelab.my.id/"
CHECK_INTERVAL=300  # 5 minutes
THRESHOLD=300       # 300 blocks
WALLET_ADDRESS="YOUR-ADDRESS 0x"  # Replace with your wallet address

# --- Optional: Telegram Token & Chat ID (export from env or hardcode here) ---
BOT_TOKEN="${BOT_TOKEN:-}"     # export BOT_TOKEN="..." to enable
CHAT_ID="${CHAT_ID:-}"         # export CHAT_ID="..." to enable

# --- Escape MarkdownV2 ---
escape_markdown_v2() {
    echo "$1" | sed -E 's/([][(){}.!*#+-=|~`>_<])|\\/\\\1/g'
}

# --- Send Telegram message ---
send_telegram_log() {
    local status_raw="$1"
    local status=$(escape_markdown_v2 "$status_raw")
    local A0GI_BALANCE=$(get_a0gi_balance)
    local msg=$(cat <<EOF
📢 *EZ LABS NODE REPORT*
🧠 *0G Storage Node*

📦 *Storage:* \`$STORAGE_HEIGHT\`
🌐 *Parent:* \`$PARENT_HEIGHT\`
🔁 *Difference:* \`$DIFF\`
💰 *OG Balance:* \`$A0GI_BALANCE OG\`
$status
EOF
)
    if [[ -n "$BOT_TOKEN" && -n "$CHAT_ID" ]]; then
        echo -e "${YELLOW}[DEBUG] Sending Telegram message...${NC}"
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
            -d chat_id="$CHAT_ID" \
            --data-urlencode "text=$msg" \
            -d parse_mode="MarkdownV2" \
            -w "\n[HTTP STATUS: %{http_code}]\n"
    else
        echo -e "${YELLOW}[INFO] BOT_TOKEN or CHAT_ID not set. Skipping Telegram message.${NC}"
    fi
}

# --- Hex to decimal conversion ---
hex_to_dec() {
    printf "%d" "$((16#${1#0x}))"
}

# --- Get OG balance from RPC ---
get_a0gi_balance() {
    local BAL_HEX=$(curl -s -X POST "$PARENT_RPC" \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBalance\",\"params\":[\"$WALLET_ADDRESS\", \"latest\"],\"id\":1}" | jq -r '.result')

    if [[ "$BAL_HEX" == "null" || -z "$BAL_HEX" ]]; then
        echo "0"
    else
        local BAL_DEC=$(printf "%d" "$((16#${BAL_HEX#0x}))")
        echo "scale=6; $BAL_DEC / 1000000000000000000" | bc
    fi
}

# --- Monitoring loop ---
while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[$TIMESTAMP] ${CYAN}⏳ Checking block height...${NC}"

    STORAGE_HEIGHT=$(curl -s -X POST "$STORAGE_RPC" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"zgs_getStatus","params":[],"id":1}' | jq -r '.result.logSyncHeight')

    PARENT_HEX=$(curl -s -X POST "$PARENT_RPC" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | jq -r '.result')

    PARENT_HEIGHT=$(hex_to_dec "$PARENT_HEX")

    if [[ ! $STORAGE_HEIGHT =~ ^[0-9]+$ ]] || [[ ! $PARENT_HEIGHT =~ ^[0-9]+$ ]]; then
        echo -e "[$TIMESTAMP] ${RED}❌ Failed to get block height!${NC} | Storage: $STORAGE_HEIGHT | Parent(hex): $PARENT_HEX"
        sleep $CHECK_INTERVAL
        continue
    fi

    DIFF=$((PARENT_HEIGHT - STORAGE_HEIGHT))
    echo -e "[$TIMESTAMP] ${CYAN}📦 Storage:${NC} $STORAGE_HEIGHT | ${CYAN}🌐 Parent:${NC} $PARENT_HEIGHT | ${YELLOW}🔁 Difference:${NC} $DIFF"

    A0GI_BAL=$(get_a0gi_balance)
    echo -e "[$TIMESTAMP] ${CYAN}💰 OG Balance:${NC} $A0GI_BAL OG"

    if (( DIFF > THRESHOLD )); then
        echo -e "[$TIMESTAMP] ${RED}⚠️ STORAGE_NODE FALLING BEHIND! Restarting zgs...${NC}"
        send_telegram_log "⚠️ Status: STORAGE_NODE FALLING BEHIND — Restarting zgs..."
        systemctl restart zgs
    else
        echo -e "[$TIMESTAMP] ${GREEN}✅ STORAGE_NODE OK${NC}"
        send_telegram_log "✅ Status: STORAGE_NODE OK"
    fi

    sleep $CHECK_INTERVAL
done
