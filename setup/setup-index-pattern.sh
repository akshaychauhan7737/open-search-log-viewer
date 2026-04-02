#!/bin/bash
# Wait for OpenSearch to be ready
echo "Waiting for OpenSearch..."
until curl -s http://opensearch:9200 >/dev/null 2>&1; do
  sleep 2
done
echo "OpenSearch is up!"

# Wait for OpenSearch Dashboards to be ready
echo "Waiting for OpenSearch Dashboards..."
until curl -s http://opensearch-dashboards:5601/api/status >/dev/null 2>&1; do
  sleep 2
done
echo "OpenSearch Dashboards is up!"

# Create index template in OpenSearch so any application-logs-* index is auto-configured
echo "Creating index template..."
curl -s -X PUT "http://opensearch:9200/_index_template/application-logs-template" \
  -H 'Content-Type: application/json' \
  -d '{
  "index_patterns": ["application-logs-*"],
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    },
    "mappings": {
      "properties": {
        "@timestamp":    { "type": "date" },
        "level":         { "type": "keyword" },
        "logger_name":   { "type": "keyword" },
        "thread_name":   { "type": "keyword" },
        "message":       { "type": "text" },
        "stack_trace":   { "type": "text" },
        "HOSTNAME":      { "type": "keyword" },
        "errorReporter": { "type": "keyword" },
        "endpoint":      { "type": "text" },
        "requestId":     { "type": "keyword" },
        "httpStatusCode": { "type": "keyword" },
        "requestBody":   { "type": "text" },
        "responseBody":  { "type": "text" },
        "errorCode":     { "type": "keyword" },
        "pspId":         { "type": "keyword" },
        "clientId":      { "type": "keyword" },
        "logSource":     { "type": "keyword" },
        "messageId":     { "type": "keyword" },
        "partnerId":     { "type": "keyword" },
        "eventType":     { "type": "keyword" },
        "messageType":   { "type": "keyword" },
        "eventName":     { "type": "keyword" }
      }
    }
  }
}'
echo ""

# Seed a dummy doc so the index exists before creating the pattern
echo "Seeding initial index..."
curl -s -X POST "http://opensearch:9200/application-logs-$(date +%Y.%m.%d)/_doc" \
  -H 'Content-Type: application/json' \
  -d "{
  \"@timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\",
  \"message\": \"Index pattern setup - seed document\",
  \"level\": \"INFO\",
  \"logger_name\": \"setup\"
}"
echo ""

sleep 2

# Create index pattern in OpenSearch Dashboards so it shows in Discover
echo "Creating index pattern in Dashboards..."
curl -s -X POST "http://opensearch-dashboards:5601/api/saved_objects/index-pattern/application-logs" \
  -H 'Content-Type: application/json' \
  -H 'osd-xsrf: true' \
  -d '{
  "attributes": {
    "title": "application-logs-*",
    "timeFieldName": "@timestamp"
  }
}'
echo ""

# Set it as the default index pattern
echo "Setting default index pattern..."
curl -s -X POST "http://opensearch-dashboards:5601/api/opensearch-dashboards/settings" \
  -H 'Content-Type: application/json' \
  -H 'osd-xsrf: true' \
  -d '{
  "changes": {
    "defaultIndex": "application-logs"
  }
}'
echo ""

echo "Setup complete! Index pattern 'application-logs-*' is ready in Discover."

# ── Test Execution Logs Index ──
echo ""
echo "=== Setting up test-execution-logs index ==="

# Create index template for test-execution-logs
echo "Creating test-execution-logs index template..."
curl -s -X PUT "http://opensearch:9200/_index_template/test-execution-logs-template" \
  -H 'Content-Type: application/json' \
  -d '{
  "index_patterns": ["test-execution-logs-*"],
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    },
    "mappings": {
      "properties": {
        "@timestamp":  { "type": "date" },
        "level":       { "type": "keyword" },
        "logger":      { "type": "keyword" },
        "thread":      { "type": "keyword" },
        "testId":      { "type": "keyword" },
        "message":     { "type": "text" }
      }
    }
  }
}'
echo ""

# Seed a dummy doc so the index exists
echo "Seeding test-execution-logs index..."
curl -s -X POST "http://opensearch:9200/test-execution-logs-$(date +%Y.%m.%d)/_doc" \
  -H 'Content-Type: application/json' \
  -d "{
  \"@timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\",
  \"message\": \"Index pattern setup - seed document\",
  \"level\": \"INFO\",
  \"logger\": \"setup\",
  \"thread\": \"main\",
  \"testId\": \"N/A\"
}"
echo ""

sleep 2

# Create index pattern in Dashboards
echo "Creating test-execution-logs index pattern in Dashboards..."
curl -s -X POST "http://opensearch-dashboards:5601/api/saved_objects/index-pattern/test-execution-logs" \
  -H 'Content-Type: application/json' \
  -H 'osd-xsrf: true' \
  -d '{
  "attributes": {
    "title": "test-execution-logs-*",
    "timeFieldName": "@timestamp"
  }
}'
echo ""

echo "Setup complete! Index pattern 'test-execution-logs-*' is ready in Discover."
