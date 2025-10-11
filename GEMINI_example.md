# GEMINI.md - Local Intelligence MCP Integration for Google Gemini

## 🚀 Local Intelligence MCP for Gemini AI Studio & Vertex AI

This guide shows how to integrate Local Intelligence MCP server with Google's AI platforms for professional audio domain processing.

## 📋 Integration Overview

Local Intelligence MCP provides specialized audio processing tools that enhance Gemini's capabilities:
- **Audio domain expertise** - Professional audio production knowledge
- **PII protection** - Secure content processing with audio term preservation
- **Content analysis** - Advanced text analysis for audio contexts
- **Session management** - Structured processing of audio sessions
- **Catalog tools** - Audio library management and analysis

## 🔧 Setup Configuration

### **1. MCP Server Configuration**
```json
{
  "mcpServers": {
    "local-intelligence-mcp": {
      "command": "LocalIntelligenceMCP",
      "args": ["--host", "localhost", "--port", "3000"],
      "env": {
        "MCP_LOG_LEVEL": "info"
      }
    }
  }
}
```

### **2. Gemini API Integration**
```python
import vertexai
from vertexai.generative_models import GenerativeModel, Part

# Initialize Gemini with MCP integration
def setup_gemini_with_mcp():
    project_id = "your-project-id"
    location = "us-central1"
    vertexai.init(project=project_id, location=location)

    model = GenerativeModel("gemini-1.5-pro")
    return model
```

### **3. Docker Deployment**
```bash
# Start Local Intelligence MCP server
docker-compose up -d

# Verify server is running
curl http://localhost:3000/health
```

## 🎵 Audio Processing Workflows

### **Session Notes Processing**
```python
def process_audio_session_with_gemini(raw_transcript):
    """Process audio session using MCP + Gemini"""

    # Step 1: Normalize and clean transcript
    normalized_text = mcp_call("TextNormalizeTool", {
        "text": raw_transcript,
        "removeFillers": True,
        "standardizeFormat": True
    })

    # Step 2: Detect content purpose
    purpose_analysis = mcp_call("ContentPurposeDetector", {
        "text": normalized_text,
        "audioContext": True
    })

    # Step 3: Redact sensitive information
    protected_text = mcp_call("PIIRedactionTool", {
        "text": normalized_text,
        "preserveAudioTerms": True,
        "policy": "conservative"
    })

    # Step 4: Generate technical summary with Gemini
    model = setup_gemini_with_mcp()

    prompt = f"""
    Analyze this audio session transcript and provide professional insights:

    Session Purpose: {purpose_analysis['purpose']}
    Protected Content: {protected_text['redactedText']}

    Focus on:
    - Technical audio techniques used
    - Production decisions and rationale
    - Equipment and settings mentioned
    - Key takeaways for future sessions
    """

    response = model.generate_content(prompt)

    # Step 5: Extract structured metadata
    metadata = mcp_call("SchemaExtractionTool", {
        "text": response.text,
        "schemaType": "audio_production_metadata"
    })

    return {
        "gemini_insights": response.text,
        "structured_metadata": metadata,
        "session_purpose": purpose_analysis,
        "protected_content": protected_text
    }
```

### **Catalog Analysis Pipeline**
```python
def analyze_audio_catalog_with_gemini(audio_files_data):
    """Analyze audio catalog using MCP + Gemini"""

    # Step 1: Process catalog with MCP
    catalog_summary = mcp_call("CatalogSummarizationTool", {
        "catalogData": audio_files_data,
        "analysisType": "comprehensive",
        "includeVendorAnalysis": True
    })

    # Step 2: Generate embeddings for similarity search
    embeddings = []
    for item in catalog_summary['processedItems']:
        embedding = mcp_call("EmbeddingGenerationTool", {
            "content": item['description'],
            "model": "text-embedding-ada-002"
        })
        embeddings.append(embedding)

    # Step 3: Get Gemini's strategic analysis
    model = setup_gemini_with_mcp()

    prompt = f"""
    As an audio production expert, analyze this catalog summary:

    {catalog_summary['summary']}

    Provide strategic recommendations for:
    - Content organization and workflow improvements
    - Technical quality assessments
    - Production efficiency optimizations
    - Creative opportunities and collaborations
    """

    strategic_analysis = model.generate_content(prompt)

    # Step 4: Find similar content
    similarity_results = mcp_call("SimilarityRankingTool", {
        "queryContent": "mastering workflow optimization",
        "catalog": catalog_summary['processedItems'],
        "topK": 5
    })

    return {
        "catalog_summary": catalog_summary,
        "strategic_analysis": strategic_analysis.text,
        "similar_content": similarity_results,
        "embeddings": embeddings
    }
```

### **Feedback Analysis with Gemini**
```python
def analyze_feedback_with_gemini(feedback_data):
    """Analyze user feedback using MCP + Gemini"""

    # Step 1: Process feedback with MCP
    feedback_analysis = mcp_call("FeedbackAnalysisTool", {
        "feedbackData": feedback_data,
        "analysisType": "comprehensive",
        "categorizeFeedback": True
    })

    # Step 2: Extract key themes and sentiments
    themes = mcp_call("TagGenerationTool", {
        "content": feedback_analysis['processedFeedback'],
        "category": "feedback_themes",
        "count": 15
    })

    # Step 3: Get Gemini's actionable insights
    model = setup_gemini_with_mcp()

    prompt = f"""
    As a product manager for audio tools, analyze this feedback:

    Feedback Summary: {feedback_analysis['summary']}
    Key Themes: {themes['tags']}
    Sentiment Analysis: {feedback_analysis['sentiment']}

    Provide:
    - Priority action items (high/medium/low)
    - Feature improvement recommendations
    - User experience optimizations
    - Technical debt considerations
    - Market positioning insights
    """

    actionable_insights = model.generate_content(prompt)

    # Step 4: Generate implementation roadmap
    roadmap_prompt = f"""
    Based on the feedback analysis and insights, create a 90-day implementation roadmap:

    {actionable_insights.text}

    Structure as:
    - Month 1: Critical fixes and quick wins
    - Month 2: Feature enhancements
    - Month 3: Strategic improvements

    Include success metrics for each phase.
    """

    roadmap = model.generate_content(roadmap_prompt)

    return {
        "feedback_analysis": feedback_analysis,
        "key_themes": themes,
        "actionable_insights": actionable_insights.text,
        "implementation_roadmap": roadmap.text
    }
```

## 🔍 Content Intelligence Pipeline

### **Multi-Modal Audio Analysis**
```python
def analyze_multimodal_content(audio_file, transcript, metadata):
    """Analyze audio content across multiple modalities"""

    # Step 1: Process text components with MCP
    session_notes = mcp_call("SessionNotesTool", {
        "content": transcript,
        "sessionType": metadata['sessionType'],
        "outputFormat": "structured"
    })

    # Step 2: Generate comprehensive summary
    summary = mcp_call("EnhancedSummarizationTool", {
        "text": session_notes['processedContent'],
        "context": f"Audio session: {metadata['title']}",
        "style": "technical",
        "includeKeyPoints": True
    })

    # Step 3: Get Gemini's multi-modal analysis
    model = setup_gemini_with_mcp()

    # Prepare multi-modal prompt
    prompt = f"""
    Analyze this audio session comprehensively:

    Audio Metadata: {metadata}
    Session Notes: {session_notes['structuredOutput']}
    Summary: {summary['summary']}

    Provide insights on:
    1. Technical audio quality and production techniques
    2. Creative decisions and artistic choices
    3. Workflow efficiency and optimization opportunities
    4. Equipment and tool recommendations
    5. Collaboration and communication improvements

    Format as structured analysis with actionable recommendations.
    """

    multimodal_analysis = model.generate_content(prompt)

    # Step 4: Extract structured data
    structured_data = mcp_call("SchemaExtractionTool", {
        "text": multimodal_analysis.text,
        "schemaType": "comprehensive_audio_analysis"
    })

    return {
        "session_processing": session_notes,
        "summary": summary,
        "multimodal_analysis": multimodal_analysis.text,
        "structured_data": structured_data
    }
```

## 🎛️ Real-Time Processing

### **Live Session Enhancement**
```python
def enhance_live_session(live_transcript, session_context):
    """Enhance live audio session with real-time processing"""

    # Step 1: Quick content analysis
    purpose = mcp_call("ContentPurposeDetector", {
        "text": live_transcript,
        "audioContext": True,
        "fastMode": True
    })

    # Step 2: Generate real-time suggestions
    model = setup_gemini_with_mcp()

    prompt = f"""
    Live Audio Session Context: {session_context}
    Current Purpose: {purpose['purpose']}
    Live Transcript: {live_transcript}

    Provide real-time suggestions for:
    - Technical adjustments (EQ, compression, etc.)
    - Creative direction changes
    - Workflow optimizations
    - Collaboration improvements

    Keep suggestions concise and actionable.
    """

    suggestions = model.generate_content(prompt)

    # Step 3: Extract action items
    action_items = mcp_call("TagGenerationTool", {
        "content": suggestions.text,
        "category": "action_items",
        "count": 5
    })

    return {
        "live_purpose": purpose,
        "suggestions": suggestions.text,
        "action_items": action_items['tags'],
        "timestamp": datetime.now().isoformat()
    }
```

## 📊 Performance Analytics

### **Processing Metrics Dashboard**
```python
def generate_processing_dashboard(session_data):
    """Generate comprehensive processing analytics"""

    # Step 1: Get MCP server metrics
    health_status = mcp_call("HealthPingTool", {
        "detailed": True,
        "includeMetrics": True
    })

    capabilities = mcp_call("CapabilitiesListTool", {
        "category": "audio_processing",
        "detailed": True
    })

    # Step 2: Analyze processing performance
    model = setup_gemini_with_mcp()

    performance_data = {
        "server_health": health_status,
        "available_tools": capabilities,
        "session_stats": session_data
    }

    prompt = f"""
    Analyze this Local Intelligence MCP performance data:

    {json.dumps(performance_data, indent=2)}

    Generate insights on:
    - Tool usage patterns and efficiency
    - Processing bottlenecks and optimization opportunities
    - Resource utilization and scaling recommendations
    - Quality metrics and improvement areas

    Provide actionable recommendations for performance optimization.
    """

    performance_analysis = model.generate_content(prompt)

    return {
        "health_metrics": health_status,
        "tool_capabilities": capabilities,
        "performance_analysis": performance_analysis.text,
        "recommendations": extract_recommendations(performance_analysis.text)
    }
```

## 🔗 Gemini API Integration Examples

### **Vertex AI Pipeline**
```python
from vertexai.generative_models import GenerativeModel, Part
import json

def vertex_ai_mcp_pipeline(audio_content):
    """Vertex AI + Local Intelligence MCP pipeline"""

    # Initialize Vertex AI
    vertexai.init(project="your-project", location="us-central1")
    model = GenerativeModel("gemini-1.5-pro")

    # Process with Local Intelligence MCP
    processed_content = mcp_call("TextProcessingPipeline", {
        "text": audio_content,
        "pipeline": "audio_analysis",
        "preserveContext": True
    })

    # Create multi-part prompt for Vertex AI
    parts = [
        Part.from_text("Analyze this audio production content:"),
        Part.from_text(f"Processed Content: {processed_content['summary']}"),
        Part.from_text(f"Technical Analysis: {processed_content['technical_insights']}"),
        Part.from_text("Provide professional audio production recommendations.")
    ]

    response = model.generate_content(parts)

    return {
        "mcp_processing": processed_content,
        "vertex_ai_analysis": response.text,
        "recommendations": extract_recommendations(response.text)
    }
```

## 🚨 Error Handling & Resilience

### **Robust Error Handling**
```python
def resilient_mcp_gemini_processing(content, max_retries=3):
    """Resilient processing with retry logic"""

    for attempt in range(max_retries):
        try:
            # Check MCP server health
            health = mcp_call("HealthPingTool")

            if not health['status'] == 'healthy':
                raise Exception("MCP server not healthy")

            # Process with MCP
            mcp_result = mcp_call("TextNormalizeTool", {
                "text": content,
                "errorHandling": "strict"
            })

            # Process with Gemini
            model = setup_gemini_with_mcp()
            response = model.generate_content(mcp_result['normalizedText'])

            return {
                "success": True,
                "mcp_result": mcp_result,
                "gemini_response": response.text,
                "attempt": attempt + 1
            }

        except Exception as e:
            if attempt == max_retries - 1:
                return {
                    "success": False,
                    "error": str(e),
                    "attempt": attempt + 1,
                    "fallback_processed": fallback_processing(content)
                }

            # Exponential backoff
            time.sleep(2 ** attempt)
            continue
```

## 📈 Monitoring & Analytics

### **Usage Analytics**
```python
def track_mcp_gemini_usage():
    """Track usage patterns and performance"""

    # Get MCP metrics
    mcp_metrics = mcp_call("HealthPingTool", {
        "detailed": True,
        "includeMetrics": True
    })

    # Log usage patterns
    usage_log = {
        "timestamp": datetime.now().isoformat(),
        "mcp_tools_used": get_used_tools(),
        "processing_time": mcp_metrics['metrics']['processingTime'],
        "success_rate": calculate_success_rate(),
        "error_patterns": analyze_errors()
    }

    # Generate insights with Gemini
    model = setup_gemini_with_mcp()

    prompt = f"""
    Analyze this usage data for Local Intelligence MCP + Gemini integration:

    {json.dumps(usage_log, indent=2)}

    Provide insights on:
    - Usage patterns and trends
    - Performance optimization opportunities
    - Resource allocation recommendations
    - User experience improvements
    """

    insights = model.generate_content(prompt)

    return {
        "usage_metrics": usage_log,
        "performance_insights": insights.text,
        "recommendations": generate_recommendations(insights.text)
    }
```

---

**🎯 Key Benefits of Local Intelligence MCP + Gemini:**

1. **Audio Domain Expertise** - Professional audio production knowledge
2. **Secure Processing** - PII protection with audio term preservation
3. **Advanced Analysis** - Multi-modal content understanding
4. **Scalable Architecture** - Docker deployment for production
5. **Real-time Processing** - Live session enhancement capabilities
6. **Comprehensive Analytics** - Performance monitoring and optimization

**🔗 Integration Best Practices:**
- Always check MCP server health before processing
- Use streaming for large content (>8KB)
- Implement proper error handling and retry logic
- Monitor performance metrics and optimize accordingly
- Cache frequently used patterns and results