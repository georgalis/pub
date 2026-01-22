#!/usr/bin/env bash
# rev: 68ebf6c1 20251012 114303 PDT ./pub/know/llm/sub/claude_chat_export.sh
# Generates bookmarklet to export Claude chat JSON with hex timestamp filename

set -euo pipefail

# Documentation header for bookmarklet requirements
cat <<'EODOC'
PERSISTENT REQUIREMENTS FOR LLM-ASSISTED REVISIONS
===================================================

This script generates bookmarklets from formatted JavaScript. Future modifications 
require only specifying desired changes-all constraints below persist automatically.

Three requirement layers must be preserved across all revisions:

1. BOOKMARKLET PACKAGING (URL field execution constraints)
   - Single-line output with whitespace normalization
   - Comment-strip minification: sed removes // to EOL
   - No backticks, no inline comments, no multiline templates
   
2. JAVASCRIPT SYNTAX (minification compatibility)
   - Comments precede code blocks, never trail statements
   - Functions survive whitespace collapse
   - Avoid regex containing // operator
   
3. APPLICATION LOGIC (current implementation specifics)
   - Filename: chat-<hex_unix_timestamp>-<safe_title>.json
   - Timestamp: ISO8601 -> Unix seconds -> lowercase hex
   - Three-tier filtering: EXCLUDE_KEYS, EXCLUDE_EMPTY_KEYS, EXCLUDE_KEY_VALUES
   - DOT graph: UUID->hex timestamp translation for temporal visualization
   - Export metadata: version tracking, timestamps

CRITICAL: When revising, preserve all unmentioned specifics (formats, algorithms, 
data structures). Documentation output precedes bookmarklet on each execution to 
maintain requirement visibility. Specification details like "hex timestamp format" 
must survive unless explicitly changed.

Future prompts specify only deltas; this context provides foundation.

BOOKMARKLET PACKAGING REQUIREMENTS
===================================

Format Constraints:
- Single-line JavaScript execution within URL field
- Comment-strip minification: removes // to EOL
- Whitespace normalization: collapses newlines and spaces
- URL encoding compatible (reserved: : / ? # [ ] @ ! $ & ' ( ) * + , ; =)

JavaScript Syntax Compatibility:
- Use // comments only (never inline within strings)
- Avoid backticks in string literals (breaks sed processing)
- No multi-line string templates requiring whitespace preservation
- Function declarations compatible with whitespace collapse

Minification Method:
1. Strip all // comment lines: sed -e "s=// .*=="
2. Convert newlines to spaces: tr '\n' ' '
3. Normalize whitespace: sed -e 's/ [ ]*/ /g'

Application Requirements:
- API base: https://claude.ai/api
- Endpoints: /organizations, /organizations/{orgId}/chat_conversations/{chatId}
- Filename format: chat-<hex_timestamp>-<safeTitle>.json (hex = unix seconds)
- JSON output with 2-space indentation
- Schema-adaptive: capture all keys, enable exclusion lists
- DOT graph uses hex timestamps for all nodes

Derived Constraints:
- Comments must precede code, never trail statements
- String concatenation safe for minification
- Avoid regex literals containing //
- Error handling must survive whitespace collapse
- Timestamp conversion: ISO8601 -> Unix seconds -> lowercase hex
- Empty arrays/objects excluded same as null/undefined/empty string for specified keys
- Populated arrays/objects preserved regardless of EXCLUDE_EMPTY_KEYS membership
- Specific key-value pairs excluded when matching exact values (e.g., truncated: false)

EODOC


echo "Generate bookmarklet to export Claude chat JSON with hex timestamp filename"
echo ""

# JavaScript bookmarklet with key exclusion and hex timestamp DOT graph
{ read -d '' JavaScript < <(cat <<'EOJ'
// Claude Chat Download Utility
// Purpose: Download chat as JSON with hex timestamp filename
// Date: 2025-01-11
// (c) 2025 George Georgalis <george@galis.org> // https://opensource.org/license/mit
// prior revisions:
// @name         Claude.ai Ultimate Chat Exporter
// @version      1.0
// @author       Geo Anima
// @namespace    https://github.com/GeoAnima/claude.ai-ultimate-chat-exporter
// @license      MIT
// - This project is a fork of "Export Claude.Ai" (https://github.com/TheAlanK/export-claude), licensed under the MIT license.

javascript:(function () {
    'use strict';

    const API_BASE_URL = 'https://claude.ai/api';

    // Keys to exclude from export (demonstration with non-existent keys)
    const EXCLUDE_KEYS = ['xyz123', 'abc456'];

    // Keys to exclude only if null, undefined, empty string, or empty array
    const EXCLUDE_EMPTY_KEYS = ['model', 'summary', 'project_uuid', 'files', 'files_v2', 'sync_sources', 'attachments'];

    // Key-value pairs to exclude when matching exact values
    const EXCLUDE_KEY_VALUES = {
        'truncated': false,
        'is_temporary' : false,
        'stop_reason': 'stop_sequence'
    };

    // Function to convert ISO8601 timestamp to hex unix seconds
    function timestampToHex(isoString) {
        const unixSeconds = Math.floor(new Date(isoString).getTime() / 1000);
        return unixSeconds.toString(16);
    }

    // Function to check if value is empty (null, undefined, '', or empty array)
    function isEmpty(value) {
        return value === null || value === undefined || value === '' || (Array.isArray(value) && value.length === 0);
    }

    // Function to recursively filter excluded keys from object
    function filterExcludedKeys(obj, excludeList, excludeEmptyList, excludeKeyValues) {
        if (obj === null || typeof obj !== 'object') {
            return obj;
        }
        if (Array.isArray(obj)) {
            return obj.map(item => filterExcludedKeys(item, excludeList, excludeEmptyList, excludeKeyValues));
        }
        const filtered = {};
        Object.keys(obj).forEach(key => {
            const value = obj[key];
            // Skip if in absolute exclusion list
            if (excludeList.includes(key)) {
                return;
            }
            // Skip if key-value pair matches exclusion map
            if (key in excludeKeyValues && value === excludeKeyValues[key]) {
                return;
            }
            // Skip if in conditional exclusion list AND value is empty
            if (excludeEmptyList.includes(key) && isEmpty(value)) {
                return;
            }
            filtered[key] = filterExcludedKeys(value, excludeList, excludeEmptyList, excludeKeyValues);
        });
        return filtered;
    }

    // Function to make API requests using fetch
    function apiRequest(method, endpoint, data = null, headers = {}) {
        return fetch(`${API_BASE_URL}${endpoint}`, {
            method: method,
            headers: {
                'Content-Type': 'application/json',
                ...headers,
            },
            body: data ? JSON.stringify(data) : null,
        }).then(response => {
            if (response.ok) {
                return response.json();
            } else {
                throw new Error(`API request failed with status ${response.status}`);
            }
        });
    }

    // Function to get the organization ID
    async function getOrganizationId() {
        const organizations = await apiRequest('GET', '/organizations');
        return organizations[0].uuid;
    }

    // Function to get conversation history (all available keys)
    async function getConversationHistory(orgId, chatId) {
        return await apiRequest('GET', `/organizations/${orgId}/chat_conversations/${chatId}`);
    }

    // Function to create a safe filename with hex timestamp
    function createSafeFilename(chatData) {
        const hexTimestamp = timestampToHex(chatData.created_at);
        const safeTitle = chatData.name.replace(/[^a-zA-Z0-9_]+/g, '_');
        return `chat-${hexTimestamp}-${safeTitle}.json`;
    }

    // Function to generate DOT graph data with hex timestamp nodes
    function generateDotGraph(chatData) {
        const hexTimestamp = timestampToHex(chatData.created_at);
        
        // Build UUID to hex timestamp map for parent_id translation
        const uuidToHex = {};
        chatData.chat_messages.forEach((message) => {
            const msgHexTime = timestampToHex(message.created_at);
            uuidToHex[message.uuid] = msgHexTime;
        });
        
        let dotGraph = 'digraph chat_structure {\n';
        dotGraph += `  "0x${hexTimestamp}" [label="${chatData.name}", shape=box];\n`;
        dotGraph += '  assistant [shape=box];\n';
        dotGraph += '  human [shape=box];\n';
        dotGraph += '  attachment [shape=ellipse];\n';
        dotGraph += '\n';

        // Add nodes and edges with hex timestamps
        chatData.chat_messages.forEach((message) => {
            const msgHexTime = uuidToHex[message.uuid];
            dotGraph += `  "0x${msgHexTime}" [label="${message.sender}"];\n`;
            if (message.parent_id && uuidToHex[message.parent_id]) {
                const parentHexTime = uuidToHex[message.parent_id];
                dotGraph += `  "0x${parentHexTime}" -> "0x${msgHexTime}" [label="reply_to"];\n`;
            }
            if (message.attachments) {
                message.attachments.forEach((attachment) => {
                    dotGraph += `  "0x${msgHexTime}" -> "${attachment.id}" [label="${attachment.file_name}"];\n`;
                });
            }
        });

        dotGraph += '}\n';
        return dotGraph;
    }

    // Function to download data as a file
    function downloadData(data, filename) {
        const content = JSON.stringify(data, null, 2);
        const blob = new Blob([content], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        a.style.display = 'none';
        document.body.appendChild(a);
        a.click();
        setTimeout(() => {
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
        }, 100);
    }

    // Function to export a single chat
    async function exportChat(chatId) {
        try {
            const orgId = await getOrganizationId();
            const chatData = await getConversationHistory(orgId, chatId);

            // Filter excluded keys from entire response
            const filteredData = filterExcludedKeys(chatData, EXCLUDE_KEYS, EXCLUDE_EMPTY_KEYS, EXCLUDE_KEY_VALUES);

            // Add metadata to export
            filteredData.export_metadata = {
                exported_at: new Date().toISOString(),
                export_tool_rev: 'claude_chat_export.sh 68ebf6c1'
            };

            // Add DOT graph data to the chat data
            filteredData.dot_graph = generateDotGraph(filteredData);

            const filename = createSafeFilename(filteredData);
            downloadData(filteredData, filename);
        } catch (error) {
            alert('Error exporting chat. Please try again later.');
        }
    }

    // Function to initialize the export functionality
    async function initExportFunctionality() {
        const currentUrl = window.location.href;
        if (currentUrl.includes('/chat/')) {
            const urlParts = currentUrl.split('/');
            const chatId = urlParts[urlParts.length - 1];
            await exportChat(chatId);
        } else {
            alert('This JavaScript bookmarklet only exports Claude chats.');
        }
    }

    // Initialize the script immediately for bookmarklet use
    initExportFunctionality();
})(); /* claude_chat_export.sh 68ebf6c1 */
EOJ
) ;} || true

# Process (strip comments and normalize whitespace) and output JavaScript bookmarklet
printf "Bookmarklet code (copy entire line, into bookmark URL):\n>>>---\n"
tr -s ' ' < <(tr '\n' ' ' < <(sed -e "s=// .*==" <<<"$JavaScript"))
printf "\n<<<---\n"
