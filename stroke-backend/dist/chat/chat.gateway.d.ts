import { Server, Socket } from 'socket.io';
import { PrismaService } from '../prisma/prisma.service';
export declare class ChatGateway {
    private prisma;
    server: Server;
    constructor(prisma: PrismaService);
    handleMessage(client: Socket, payload: {
        roomId: string;
        senderId: string;
        content: string;
    }): Promise<{
        sender: {
            full_name: string;
            photo_url: string | null;
        };
    } & {
        id: string;
        created_at: Date;
        content: string;
        metadata: import("@prisma/client/runtime/library").JsonValue | null;
        room_id: string;
        sender_id: string;
    }>;
    handleJoinRoom(client: Socket, roomId: string): void;
}
