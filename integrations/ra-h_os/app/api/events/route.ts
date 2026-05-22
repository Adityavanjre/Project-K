/**
 * Server-Sent Events (SSE) API Route
 * Streams real-time database change events to connected clients
 */

import { eventBroadcaster } from '@/services/events';

export async function GET(request: Request) {
  const encoder = new TextEncoder();
  let activeController: ReadableStreamDefaultController<Uint8Array> | null = null;

  const cleanupConnection = () => {
    if (!activeController) return;
    console.log('🔌 SSE connection cleanup');
    eventBroadcaster.removeConnection(activeController);
    activeController = null;
  };

  const stream = new ReadableStream({
    start(controller) {
      activeController = controller;

      // Add this connection to the broadcaster
      console.log('🔌 New SSE connection established');
      eventBroadcaster.addConnection(controller);
      console.log('📊 Total SSE connections:', eventBroadcaster.getConnectionCount());

      // Send initial connection confirmation
      const initialMessage = `data: ${JSON.stringify({
        type: 'CONNECTION_ESTABLISHED',
        data: { timestamp: Date.now() }
      })}\n\n`;
      
      controller.enqueue(encoder.encode(initialMessage));
    },
    
    cancel() {
      cleanupConnection();
    }
  });

  request.signal.addEventListener('abort', cleanupConnection, { once: true });

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache, no-transform',
      'Connection': 'keep-alive',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Cache-Control',
    },
  });
}
