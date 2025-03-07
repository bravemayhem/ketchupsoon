const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false
});

// Track the sequential thinking state
let thinkingSteps = [];
const MAX_HISTORY = 5;

// Initialize MCP protocol
console.log(JSON.stringify({
  type: "initialize",
  name: "sequential-thinking",
  version: "1.0.0",
  description: "MCP server that helps with sequential thinking",
  tools: [
    {
      name: "sequential_thinking",
      description: "Break down a problem into sequential steps, tracking progress and reasoning",
      parameters: {
        type: "object",
        properties: {
          thought: {
            type: "string",
            description: "The current thought or reasoning step"
          },
          question: {
            type: "string",
            description: "The specific question or aspect being addressed in this step"
          }
        },
        required: ["thought"]
      }
    },
    {
      name: "retrieve_thinking_history",
      description: "Retrieve previous thinking steps",
      parameters: {
        type: "object",
        properties: {},
        required: []
      }
    }
  ]
}));

// Handle incoming messages
rl.on('line', (line) => {
  try {
    const message = JSON.parse(line);
    
    if (message.type === "invoke") {
      const { id, tool, parameters } = message;
      
      if (tool === "sequential_thinking") {
        // Add new thinking step
        thinkingSteps.push({
          timestamp: new Date().toISOString(),
          thought: parameters.thought,
          question: parameters.question || null
        });
        
        // Trim history if needed
        if (thinkingSteps.length > MAX_HISTORY) {
          thinkingSteps = thinkingSteps.slice(-MAX_HISTORY);
        }
        
        // Respond with success
        console.log(JSON.stringify({
          type: "response",
          id,
          result: {
            status: "success",
            step_number: thinkingSteps.length,
            message: "Thinking step recorded"
          }
        }));
      } 
      else if (tool === "retrieve_thinking_history") {
        // Return the thinking history
        console.log(JSON.stringify({
          type: "response",
          id,
          result: {
            status: "success",
            history: thinkingSteps,
            total_steps: thinkingSteps.length
          }
        }));
      }
      else {
        // Unknown tool
        console.log(JSON.stringify({
          type: "response",
          id,
          error: {
            code: "unknown_tool",
            message: `Unknown tool: ${tool}`
          }
        }));
      }
    }
  } catch (error) {
    console.error(error);
    // Send error response if we have a message ID
    if (line && line.id) {
      console.log(JSON.stringify({
        type: "response",
        id: line.id,
        error: {
          code: "internal_error",
          message: error.message
        }
      }));
    }
  }
});

// Handle process exit
process.on('SIGINT', () => {
  process.exit(0);
}); 