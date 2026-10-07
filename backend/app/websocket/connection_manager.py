import logging
from typing import Dict, List, Optional
from fastapi import WebSocket

logger = logging.getLogger("nylex.websocket")

class ConnectionManager:
    def __init__(self):
        # Maps user_id -> List of active WebSockets (allows multiple devices/tabs per user)
        self.active_connections: Dict[str, List[WebSocket]] = {}

    async def connect(self, user_id: str, websocket: WebSocket):
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = []
        self.active_connections[user_id].append(websocket)
        logger.info(f"User {user_id} connected via WebSocket. Active user count: {len(self.active_connections)}")
        await self.broadcast_status(user_id, is_online=True)

    def disconnect(self, user_id: str, websocket: WebSocket):
        if user_id in self.active_connections:
            if websocket in self.active_connections[user_id]:
                self.active_connections[user_id].remove(websocket)
            if len(self.active_connections[user_id]) == 0:
                del self.active_connections[user_id]
        logger.info(f"User {user_id} disconnected from WebSocket.")

    def is_user_online(self, user_id: str) -> bool:
        return user_id in self.active_connections and len(self.active_connections[user_id]) > 0

    async def send_personal_message(self, user_id: str, message: dict):
        if user_id in self.active_connections:
            for connection in self.active_connections[user_id]:
                try:
                    await connection.send_json(message)
                except Exception as e:
                    logger.error(f"Failed to send WS message to user {user_id}: {e}")

    async def broadcast(self, message: dict):
        for user_id, connections in self.active_connections.items():
            for connection in connections:
                try:
                    await connection.send_json(message)
                except Exception as e:
                    logger.error(f"Failed to broadcast WS message: {e}")

    async def broadcast_status(self, user_id: str, is_online: bool):
        await self.broadcast({
            "type": "user_status",
            "userId": user_id,
            "isOnline": is_online
        })

manager = ConnectionManager()
