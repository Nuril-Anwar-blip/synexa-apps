import {
    WebSocketGateway,
    SubscribeMessage,
    MessageBody,
    WebSocketServer,
    ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { PrismaService } from '../prisma/prisma.service';

@WebSocketGateway({
    cors: {
        origin: '*',
    },
})
export class ChatGateway {
    @WebSocketServer()
    server: Server;

    constructor(private prisma: PrismaService) { }

    /**
     * Handler saat client mengirim pesan
     * @param client Socket client
     * @param payload Data pesan (roomId, senderId, content)
     */
    @SubscribeMessage('send_message')
    async handleMessage(
        @ConnectedSocket() client: Socket,
        @MessageBody() payload: { roomId: string; senderId: string; content: string },
    ) {
        // Simpan pesan ke database
        const message = await this.prisma.message.create({
            data: {
                room_id: payload.roomId,
                sender_id: payload.senderId,
                content: payload.content,
            },
            include: {
                sender: {
                    select: {
                        full_name: true,
                        photo_url: true,
                    },
                },
            },
        });

        // Broadcast pesan ke semua orang di room tersebut
        this.server.to(payload.roomId).emit('receive_message', message);

        return message;
    }

    /**
     * Menghubungkan client ke room chat tertentu
     * @param client Socket client
     * @param roomId ID Chat Room
     */
    @SubscribeMessage('join_room')
    handleJoinRoom(client: Socket, roomId: string) {
        client.join(roomId);
        console.log(`Client ${client.id} bergabung ke room ${roomId}`);
    }
}
